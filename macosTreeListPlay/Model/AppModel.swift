//
//  AppModel.swift
//  macosTreeListPlayApp
//
//  Created by Jonathan Hume on 16/10/2022.
//

import SwiftUI

class AppModel: ObservableObject {
    init(items: [Item]) {
        itemsAtTopLevel = items
    }

    @Published var itemsAtTopLevel: [Item]
    @Published var isDragging: Bool = false

    var itemsUnreadCount: Int {
        func unreadInFolder(_ array: [Item]) -> Int {
            return array.reduce(0) { acc, value in
                acc + (value.isFolder ? unreadInFolder(value.children ?? []) : (value.read ? 0 : 1))
            }
        }

        return unreadInFolder(itemsAtTopLevel)
    }

    func itemFindInTrees(uuid: UUID) -> Item? {
        Item.findDescendant(with: uuid, inTreesWithRoots: itemsAtTopLevel)
    }

    func itemsFind(uuids: Set<UUID>) -> Array<Item> {
        uuids.compactMap { uuid in
            itemFindInTrees(uuid: uuid)
        }
    }

    func itemIdsToMove(dragItemId: UUID, selectionIds: Selection) -> Array<UUID> {
        let asArray = itemsToMove(dragItemId: dragItemId, selectionIds: selectionIds)
            .map({ $0.id })
        return asArray
    }

    func itemsToMove(dragItemId: UUID, selectionIds: Selection) -> Array<Item> {
        let withPossibleChildrenIds =
            selectionIds.count == 0 || selectionIds.contains(dragItemId) == false
                ? [dragItemId]
                : selectionIds

        // Map to items and remove any ids that are not in the tree
        let inSystemWithPossibleChildrenItems =
            withPossibleChildrenIds
                .compactMap { uuid in
                    itemFindInTrees(uuid: uuid)
                }

        // Remove any in the selection that are descendents of other items in the selection i.e. only need to reparent the
        // the top most item.
        let notMovedByOthersInSelection =
            inSystemWithPossibleChildrenItems
                .filter { item in
                    item.isDescendant(ofAnyOf: inSystemWithPossibleChildrenItems) != true
                }

        return notMovedByOthersInSelection
    }

    func itemsToMoveIsValid(for possibleMovers: Array<UUID>, into tgtFolder: Item) -> Bool {
        for i in possibleMovers.indices {
            // Invalid to move to self to self
            if possibleMovers[i] == tgtFolder.id {
                // print("Invalid move: attempting move an item into its self")
                return false
            }

            // Invalid to move root folders
            if itemFindInTrees(uuid: possibleMovers[i])?.parent == nil {
                // print("Invalid move: attempting to move a root item, i.e. one that has no parents")
                return false
            }
        }
        return true
    }

    func itemsMove(_ possibleMovers: Array<UUID>, into tgtFolder: Item) {
        guard itemsToMoveIsValid(for: possibleMovers, into: tgtFolder) else {
            return
        }

        /// Remove any items not in the system
        let possibleMoversExtant: Array<Item> = itemsFind(uuids: Set(possibleMovers))

        // Remove any items that already have this folder as their parent.
        let notExistingChild = possibleMoversExtant.filter({
            if let parentId = $0.parent?.id, parentId == tgtFolder.id {
                return false
            } else {
                return true
            }
        })

        // Remove any in the selection that are descendents of other items in the selection i.e. only need to reparent the
        let notMovedByOthers = notExistingChild.filter { item in
            item.isDescendant(ofAnyOf: notExistingChild) != true
        }

        DispatchQueue.main.async {
            withAnimation {
                notMovedByOthers.forEach { i in
                    tgtFolder.adopt(child: i)
                }
                self.objectWillChange.send()
            }
        }
    }
}

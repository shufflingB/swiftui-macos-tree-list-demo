//
//  AppModel.swift
//  macosTreeListPlayApp
//
//  Created by Jonathan Hume on 16/10/2022.
//

import SwiftUI

class AppModel: ObservableObject {
    init(items: [Item]) {
        self.items = items
    }

    @Published var items: [Item]
    @Published var isDragging: Bool = false

    var unreadCount: Int {
        func unreadInFolder(_ array: [Item]) -> Int {
            return array.reduce(0) { acc, value in
                acc + (value.isFolder ? unreadInFolder(value.children ?? []) : (value.read ? 0 : 1))
            }
        }

        return unreadInFolder(items)
    }

    func itemFindInTrees(uuid: UUID) -> Item? {
        Item.findDescendant(with: uuid, inTreesWithRoots: items)
    }

    func itemsFind(uuids: Set<UUID>) -> Array<Item> {
        uuids.compactMap { uuid in
            itemFindInTrees(uuid: uuid)
        }
    }

    func draggingSelectionIds(dragItemId: UUID, selectionIds: Selection) -> Array<UUID> {
        let asArray = draggingSelectionItems(dragItemId: dragItemId, selectionIds: selectionIds)
            .map({ $0.uuid })
        return asArray
    }

    func draggingSelectionItems(dragItemId: UUID, selectionIds: Selection) -> Array<Item> {
        let withPossibleChildrenIds =
            selectionIds.count == 0 || selectionIds.contains(dragItemId) == false
                ? [dragItemId]
                : selectionIds

        // Map to items and remove any ids that are not in the
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

    func itemsMoveIsValid(for possibleMovers: Array<UUID>, into tgtFolder: Item) -> Bool {
        // Invalid to move any folder into itself
        for i in possibleMovers.indices {
            // Invalid to move to self to self
            if possibleMovers[i] == tgtFolder.uuid {
                print("Flagging invald as move is to self")
                return false
            }

            // Invalid to move root folders
            if itemFindInTrees(uuid: possibleMovers[i])?.parent == nil {
                print("Flagging invald as illegal to move self")
                return false
            }
        }
        return true
    }

    func itemsMove(_ possibleMovers: Array<UUID>, into tgtFolder: Item) {
        guard itemsMoveIsValid(for: possibleMovers, into: tgtFolder) else {
            return
        }

        /// Remove any items not in the system
        let possibleMoversExtant: Array<Item> = itemsFind(uuids: Set(possibleMovers))

        // Remove any items that already have this folder as their parent.
        let notExistingChild = possibleMoversExtant.filter({
            if let parentId = $0.parent?.uuid, parentId == tgtFolder.uuid {
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

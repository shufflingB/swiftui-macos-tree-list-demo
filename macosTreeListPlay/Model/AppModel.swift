//
//  AppModel.swift
//  macosTreeListPlayApp
//
//  Created by Jonathan Hume on 16/10/2022.
//

import SwiftUI

class AppModel: ObservableObject {
    typealias Selection = Set<Item.Id>

    init(items: [Item]) {
        itemsAtTopLevel = items
    }

    @Published var itemsAtTopLevel: [Item]
    @Published var isDragging: Bool = false

    func providerEncode(id: Item.Id) -> NSItemProvider {
        NSItemProvider(object: id.uuidString as NSString)
    }
    
    func providerDecode(loadedString: String?) -> Array<Item> {
        guard let possibleStringOfConcatIds: String = loadedString as String? else {
            return []
        }

        let decodedItems: Array<Item> = possibleStringOfConcatIds
            .split(separator: ",")
            .map { String($0) }
            .compactMap({ UUID(uuidString: $0) })
            .compactMap({ self.itemFindInTrees(id: $0)})
        
        return decodedItems
    }
    
    
  

    func itemFindInTrees(id: Item.Id) -> Item? {
        Item.findDescendant(with: id, inTreesWithRoots: itemsAtTopLevel)
    }

    func itemsFind(ids: Set<Item.Id>) -> Array<Item> {
        ids.compactMap { id in
            itemFindInTrees(id: id)
        }
    }

    func itemIdsToMove(dragItemId: Item.Id, selectionIds: Selection) -> Array<Item.Id> {
        let asArray = itemsToMove(dragItemId: dragItemId, selectionIds: selectionIds)
            .map({ $0.id })
        return asArray
    }

    func itemsToMove(dragItemId: Item.Id, selectionIds: Selection) -> Array<Item> {
        let withPossibleChildrenIds =
            selectionIds.count == 0 || selectionIds.contains(dragItemId) == false
                ? [dragItemId]
                : selectionIds

        // Map to items and remove any ids that are not in the tree
        let inSystemWithPossibleChildrenItems =
            withPossibleChildrenIds
                .compactMap { id in
                    itemFindInTrees(id: id)
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

    func itemsToMoveIsValid(for possibleMovers: Array<Item.Id>, into tgtFolder: Item) -> Bool {
        for i in possibleMovers.indices {
            // Invalid to move to self to self
            if possibleMovers[i] == tgtFolder.id {
                // print("Invalid move: attempting move an item into its self")
                return false
            }

            // Invalid to move root folders
            if itemFindInTrees(id: possibleMovers[i])?.parent == nil {
                // print("Invalid move: attempting to move a root item, i.e. one that has no parents")
                return false
            }
        }
        return true
    }

    func itemsMove(_ possibleMovers: Array<Item.Id>, into tgtFolder: Item) {
        guard itemsToMoveIsValid(for: possibleMovers, into: tgtFolder) else {
            return
        }

        /// Remove any items not in the system
        let possibleMoversExtant: Array<Item> = itemsFind(ids: Set(possibleMovers))

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

//
//  File.swift
//  TreeViewPlay
//
//  Created by Jonathan Hume on 16/10/2022.
//

import SwiftUI

class AppModel: ObservableObject {
    

    init(items: [Item]) {
        self.items = items
    }

    @Published var items: [Item]

    var unreadCount: Int {
        func unreadInFolder(_ array: [Item]) -> Int {
            return array.reduce(0) { acc, value in
                acc + (value.isFolder ? unreadInFolder(value.children ?? []) : (value.read ? 0 : 1))
            }
        }

        return unreadInFolder(items)
    }

    
    func itemFind(uuid: UUID) -> Item? {
        Item.findDescendant(with: uuid, inTreesWithRoots: items)
    }

    func itemsFind(uuids: Set<UUID>) -> Array<Item> {
        uuids.compactMap { uuid in
            itemFind(uuid: uuid)
        }
    }

    func itemsMoveIsValid(for  possibleMovers: Array<Item>, into tgtFolder: Item) -> Bool {
        // Invalid to move any folder into itself
        for i in possibleMovers.indices {
            // Invalid to move to self to self
            if possibleMovers[i].uuid == tgtFolder.uuid { return false }
            
            // Invalid to move root folders
            if possibleMovers[i].parent == nil { return false }
        }
        return true
    }
    
    func itemsMove(_ possibleMovers: Array<UUID>, into tgtFolder: Item) {
        /// Remove any items not in the system
        let possibleMoversExtant: Array<Item> = itemsFind(uuids: Set(possibleMovers))
        
        guard itemsMoveIsValid(for: possibleMoversExtant, into: tgtFolder) else {
            return
        }
        

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

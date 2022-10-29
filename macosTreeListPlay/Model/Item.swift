//
//  Item.swift
//  macosTreeListPlayApp
//
//  Created by Jonathan Hume on 16/10/2022.
//

import Foundation

class Item: ObservableObject, Identifiable, Equatable {
    typealias Id = UUID

    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }

    let id = Id()
    let isFolder: Bool
    let name: String

    @Published var children: [Item]?
    @Published var parent: Item?
    @Published var read: Bool

    init(_ name: String, isFolder: Bool = false, children: [Item]? = nil, read: Bool = false) {
        self.name = name
        self.isFolder = isFolder
        self.children = children
        self.read = read

        self.children?.forEach({ item in
            item.parent = self
        })
    }

    func adopt(child adopteeItem: Item) {
        // Prevent accidentally adopting self
        guard id != adopteeItem.id else {
            return
        }

        // If child has existing parent then remove it
        if let childsOriginalParent = adopteeItem.parent, let childsOriginalParentKids = childsOriginalParent.children {
            let remainingKids = childsOriginalParentKids.filter({ $0 != adopteeItem })

            if remainingKids.count == 0 {
                childsOriginalParent.children = []
            } else {
                childsOriginalParent.children = remainingKids
            }
            // childsOriginalParent.objectWillChange.send()
        }
        
        // Add the item to the adopter's list of kids and update  the adoptee
        children = (children ?? []) + [adopteeItem]
        adopteeItem.parent = self
        
//        
//
//        
//        adopteeItem.objectWillChange.send()
//        objectWillChange.send()
    }

    static func findDescendant(with id: Id?, inTreesWithRoots items: [Item]) -> Item? {
        guard let id = id else { return nil }

        return items.reduce(nil) { previouslyFoundItem, item in

            // Only find the first value & then don't repeat (& accidentally overwrite)
            guard previouslyFoundItem == nil else { return previouslyFoundItem }

            if item.id == id {
                return item
            }

            guard let children = item.children else {
                return nil
            }

            return findDescendant(with: id, inTreesWithRoots: children)
        }
    }

    func isDescendant(ofAnyOf possibleParents: Array<Item>) -> Bool {
        let found = possibleParents.first(where: { self.isDescendant(of: $0) })

        return found == nil ? false : true
    }

    func isDescendant(of possibleParent: Item) -> Bool {
        Self.isDescendant(item: self, of: possibleParent)
    }

    static func isDescendant(item: Item, of possibleParent: Item) -> Bool {
        guard let parentChildren = possibleParent.children else {
            return false
        }

        if findDescendant(with: item.id, inTreesWithRoots: parentChildren) == nil {
            return false
        } else {
            return true
        }
    }

    static func findAncestors(for item: Item, backTo possibleAncestor: Item?) -> Array<Item> {
        if let parent = item.parent {
            if let possibleAncestor = possibleAncestor, parent == possibleAncestor {
                return [parent]
            } else {
                return [parent] + findAncestors(for: parent, backTo: possibleAncestor)
            }

        } else {
            return []
        }
    }
}

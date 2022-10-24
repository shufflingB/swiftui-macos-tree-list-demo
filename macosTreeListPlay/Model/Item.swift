//
//  Item.swift
//  macosTreeListPlayApp
//
//  Created by Jonathan Hume on 16/10/2022.
//

import Foundation

class Item: ObservableObject, Identifiable, Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.uuid == rhs.uuid
    }

    var uuid: UUID = UUID()
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

    func adopt(child childItem: Item) {
        // Prevent accidentally adopting self
        guard self.uuid != childItem.uuid else {
            return
        }
        
        
        // If child has existing parent then remove it
        if let childsExistingParent = childItem.parent {
            if let remainingKids = childsExistingParent.children?.filter({ $0 != childItem }) {
                if remainingKids.count == 0 {
                    childsExistingParent.children = nil
                } else {
                    childsExistingParent.children = remainingKids
                }
                childsExistingParent.objectWillChange.send()
            }
        }
        children = (children ?? []) + [childItem]
        childItem.parent = self
    }

    static func findDescendant(with uuid: UUID?, inTreesWithRoots items: [Item]) -> Item? {
        guard let uuid = uuid else { return nil }

        return items.reduce(nil) { previouslyFoundItem, item in

            // Only find the first value & then don't repeat (& accidentally overwrite)
            guard previouslyFoundItem == nil else { return previouslyFoundItem }

            if item.uuid == uuid {
                return item
            }

            guard let children = item.children else {
                return nil
            }

            return findDescendant(with: uuid, inTreesWithRoots: children)
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

        if findDescendant(with: item.uuid, inTreesWithRoots: parentChildren) == nil {
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

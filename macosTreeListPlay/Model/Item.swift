//
//  Item.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 19/11/2021.
//

import Foundation
import os
import SwiftUI

class Item: ObservableObject, Identifiable, Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }

    let id: UUID = UUID()
    
    @Published var isParent: Bool
    @Published var title: String
    @Published var children: Array<Item>?
    @Published var parent: Item?
    @Published var complete: Bool
    @Published var priority: Date
    
    var ancestors: Array<Item> {
        self.getAncestors()
    }

    init(_ title: String, priority: Date, isParent: Bool = false, movable: Bool = true, children: [Item]? = nil, complete: Bool = false) {
        self.title = title
        self.isParent = isParent
        self.children = children
        self.complete = complete
        self.priority = priority

        self.children?.forEach({ child in
            child.parent = self
        })
    }

    private func getAncestors() -> Array<Item> {
        if let parent = self.parent {
            return [parent] + parent.getAncestors()
        } else {
            return []
        }
    }
}

fileprivate let log = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: #file.components(separatedBy: "/").last ?? ""
)

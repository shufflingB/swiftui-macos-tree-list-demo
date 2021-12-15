//
//  DisplayItem.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 11/12/2021.
//

import Foundation
import os

class DisplayItem: ObservableObject, Identifiable, Equatable {
    init(_ item: Item, markerItem: Bool = false, atTreeDepth depth: Int) {
        _item = Published(wrappedValue: item)
        self.markerItem = markerItem
        _depth = Published(wrappedValue: depth)
    }

    static func == (lhs: DisplayItem, rhs: DisplayItem) -> Bool {
        lhs.id == rhs.id
    }

    var id: UUID {
        item.id
    }

    @Published var item: Item
    @Published var depth: Int
    let markerItem: Bool
}

fileprivate let log = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: #file.components(separatedBy: "/").last ?? ""
)

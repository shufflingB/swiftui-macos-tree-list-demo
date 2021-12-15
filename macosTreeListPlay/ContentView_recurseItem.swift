//
//  ContentView_displayItems.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 15/12/2021.
//

import Foundation
import os

extension ContentView {
    internal func recurseItem(_ item: Item, parent: Item?, depth: Int) -> Array<DisplayItem> {
        let thisDi = DisplayItem(item, atTreeDepth: depth)
        if item.isParent == false || item.children == nil {
            return [thisDi]
        } else if let children = item.children {
            let sortedChildren = children.sorted(by: { $0.priority < $1.priority })

            let flattenedChildDi: Array<DisplayItem> = sortedChildren
                .map { childItem in
                    recurseItem(childItem, parent: item, depth: depth + 1)
                }
                .flatMap({ $0 })

            // Adds a tail position to distinguish between moving to a sibling of the parent and to that of a child of the parent
            //     Parent
            //          Child1
            //          Tail
            //     Sibling of parent
            //
            //

            let tailMarkerPriority: Date = {
                guard let childItem = sortedChildren.last else {
                    return item.priority + AppModel.DELTA
                }
                return childItem.priority + AppModel.DELTA
            }()

            let tailMarkerDi = DisplayItem(Item("End marker", priority: tailMarkerPriority), markerItem: true, atTreeDepth: depth + 1)
            return [thisDi] + flattenedChildDi + [tailMarkerDi]
        } else {
            log.warning("Item \(String(describing: item)) is set as non-parent but has children")
            return []
        }
    } /// End of recurseItem
}

fileprivate let log = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: #file.components(separatedBy: "/").last ?? ""
)

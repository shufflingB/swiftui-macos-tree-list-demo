//
//  FolderRow+DropDelegate.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 24/10/2022.
//

import SwiftUI

extension FolderRow: DropDelegate {
    func dropEntered(info: DropInfo) {
        isDropTgt = true
    }

    func dropExited(info: DropInfo) {
        isDropTgt = false
    }

    func validateDrop(info: DropInfo) -> Bool {
        return appModel.itemsToMoveIsValid(for: Array(draggingIds), into: folderItem)
    }

    func performDrop(info: DropInfo) -> Bool {
        appModel.itemsMove(Array(draggingIds), into: folderItem)
        selectionIds = draggingIds
        draggingIds = []
        return true
    }
}

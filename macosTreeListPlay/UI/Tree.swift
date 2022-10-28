//
//  Row.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 19/10/2022.
//

import SwiftUI
struct Tree: View {
    @ObservedObject var item: Item
    @Binding var selectionIds: AppModel.Selection
    @Binding var draggingIds: AppModel.Selection

    var body: some View {
        if item.isFolder {
            FolderRow(folderItem: item, selectionIds: $selectionIds, draggingIds: $draggingIds)

        } else {
            DefaultRow(item: item, selectionIds: $selectionIds, draggingIds: $draggingIds)
                .id(item.id)
        }
    }
}

//
//  File.swift
//  TreeViewPlay
//
//  Created by Jonathan Hume on 19/10/2022.
//

import SwiftUI
struct Row: View {
    @ObservedObject var item: Item
    @Binding var selection: Selection

    var body: some View {
        if item.isFolder {
            FolderRow(folderItem: item, selection: $selection)

        } else {
            DefaultRow(item: item, selection: $selection)
        }
    }
}

//
//  ContentView.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 16/10/2022.
//

import SwiftUI
// Not great ...
// 1) Drag has to be on the actual item, can't just grab the row.
// 2) Dragging preview for structured items is not a nice preview of the structure from which the items
// were selected.
// Cannot select root level items
// 3) Appearance not very macOS native like






struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        Group {
            List(selection: $selectionIds) {
                ForEach(appModel.itemsAtTopLevel) { item in
                    Tree(item: item, selectionIds: $selectionIds, draggingIds: $draggingIds)
                        .id(item.id)
                }
                // Note: This onInsert never actually gets run. But if it is not here then we don't get the insert
                // in FolderRow running. Possibly fragile code 🤔
                .onInsert(of: [.text]) { (idx: Int, _: Array<NSItemProvider>) in
                    print("Top Got inserted at , idx = \(idx)")
                }
            }
        }

        .listStyle(.sidebar)
        
        if #available(iOS 16.1, *) {
            Text("Something that only shows up in iOS 16.1+")
        }
        
    }

    @State private var selectionIds = AppModel.Selection() // Stores what is currently selected
    @State private var draggingIds = AppModel.Selection() // Stores what is being dragged

    private var detailItemsSelected: Array<Item> {
        appModel.itemsFind(ids: selectionIds)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

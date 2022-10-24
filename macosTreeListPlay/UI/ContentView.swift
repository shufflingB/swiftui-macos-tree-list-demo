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

typealias Selection = Set<UUID>

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        VStack {
            Text("Unread Messages: \(appModel.itemsUnreadCount)")
            NavigationSplitView(sidebar: {
                List(selection: $selectionIds) {
                    ForEach(appModel.itemsAtTopLevel) { item in
                        Tree(item: item, selectionIds: $selectionIds, draggingIds: $draggingIds)
                            .id(item.uuid)
                    }
                    // Note: This onInsert never actually gets run. But if it is not here then we don't get the insert
                    // in FolderRow running. Possibly fragile code 🤔
                    .onInsert(of: [.text]) { (idx: Int, _: Array<NSItemProvider>) in
                        print("Top Got inserted at , idx = \(idx)")
                    }
                }
                .listStyle(.sidebar)
            }, detail: {
                VStack {
                    if selectionIds.count == 0 {
                        Text("Select one or more items")
                    } else {
                        Text("Selected items:")
                            .padding(.bottom, 10)
                            .font(.title2)
                        ForEach(detailItemsSelected) { item in
                            Text(item.name)
                        }
                    }
                }
                .padding(10)
            })
        }
    }

    @State private var selectionIds = Selection() // Stores what is currently selected
    @State private var draggingIds = Selection() // Stores what is being dragged

    private var detailItemsSelected: Array<Item> {
        appModel.itemsFind(uuids: selectionIds)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

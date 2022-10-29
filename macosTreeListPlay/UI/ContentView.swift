//
//  ContentView.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 16/10/2022.
//

import SwiftUI
struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    #if os(iOS)
        @Environment(\.editMode) var editMode: Binding<EditMode>?
    #endif

    @StateObject var bootstrapRoot = Item("__BootstrapRootItem__")
    var body: some View {
        VStack {
            #if os(iOS)
                Text("Drag source items (can't drag to location in same tree under iOS)")
                Button("EditMode", action: {
                    if let editVal = editMode?.wrappedValue, editVal == .active {
                        editMode?.wrappedValue = .inactive
                    } else {
                        editMode?.wrappedValue = .active
                    }

                })
                .buttonStyle(.bordered)
            #else
                Text("Use drag and drop to rearrange items in tree")
            #endif
            Button("Add item test item to Trash") {
                let dummy = Item("Dummy item created at \(Date())")
                topLevelTrash.adopt(child: dummy)
            }

            List(selection: $selectionIds) {
                Node(parent: bootstrapRoot, items: appModel.itemsAtTopLevel)
            }
            .listStyle(.sidebar)
        }

        #if os(iOS)
            VStack {
                Text("Drop target tree")
                List {
                    Node(parent: bootstrapRoot, items: appModel.itemsAtTopLevel)
                }
            }
        #endif
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

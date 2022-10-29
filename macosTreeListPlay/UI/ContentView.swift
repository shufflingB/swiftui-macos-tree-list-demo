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

struct Parent: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var item: Item
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Node(parent: item, items: item.children ?? [])
        } label: {
            if item.parent == nil {
                Label(item.name, systemImage: "folder.badge.questionmark")
                    .onDrop(of: [.text], isTargeted: nil) { providers in
                        providers.forEach { p in
                            _ = p.loadObject(ofClass: String.self) { text, _ in
                                appModel.providerDecode(loadedString: text)
                                    .forEach { itemDropped in
                                        DispatchQueue.main.async {
                                            print("New parent = \(item.name) adopting \(itemDropped.name)")
                                            item.adopt(child: itemDropped)
                                        }
                                    }
                            }
                        }
                        return true
                    }

            } else {
                Label(item.name, systemImage: "folder")
                    .onDrag {
                        appModel.providerEncode(id: item.id)
                    }
            }
        }
    }

    @State private var isTargeted: Bool = false
    @State private var isExpanded: Bool = false
}

struct Node: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var parent: Item

    @State var items: Array<Item>

    var body: some View {
        ForEach(items) { (item: Item) in
            if item.isFolder == false {
                Label(item.name, systemImage: "doc.text")
                    .onDrag {
                        appModel.providerEncode(id: item.id)
                    }

            } else {
                Parent(item: item)
            }
        }
        .onInsert(of: [.text]) { edgeIdx, providers in
            print("Got edgeIdx = \(edgeIdx), parent = \(parent.name) provider count = \(providers.count)")
            providers.forEach { p in
                _ = p.loadObject(ofClass: String.self) { text, _ in

                    appModel.providerDecode(loadedString: text)
                        .forEach { item in
                            DispatchQueue.main.async {
                                print("New parent = \(parent.name) adopting \(item.name)")
                                self.parent.adopt(child: item)
                            }
                        }
                }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    #if os(iOS)
        @Environment(\.editMode) var editMode: Binding<EditMode>?
    #endif

    @StateObject var fakeRoot = Item("FakeRoot")
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

            List(selection: $selectionIds) {
                Node(parent: fakeRoot, items: appModel.itemsAtTopLevel)
            }
            .listStyle(.sidebar)
        }

        #if os(iOS)
            VStack {
                Text("Drop target tree")
                List {
                    Node(parent: nil, items: appModel.itemsAtTopLevel)
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

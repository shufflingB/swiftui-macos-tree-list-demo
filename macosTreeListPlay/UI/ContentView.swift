//
//  ContentView.swift
//  TreeViewPlay
//
//  Created by Jonathan Hume on 16/10/2022.
//

import SwiftUI

typealias Selection = Set<UUID>

// Not good
// 1) Drag has to be on the actual item, can't just grab the row.
// 2) Doesn't appear very macOS native



typealias AutoExpandedTracker = LastInFirstOut<Item>

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject var aet = AutoExpandedTracker() // One per-window

    var body: some View {
        VStack {
            Text("Unread Messages: \(appModel.unreadCount)")

            HStack {
                List(selection: $selection) {
                    ForEach(appModel.items) { item in
                        Row(item: item, selection: $selection)
                    }
                }

                .listStyle(.sidebar)

                VStack {
                    if selection.count == 0 {
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
                .frame(minWidth: 300, maxHeight: 300)
                .padding(10)
            }
        }
        .environmentObject(aet)
    }

    @State private var selection = Selection()

    private var detailItemsSelected: Array<Item> {
        appModel.itemsFind(uuids: selection)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

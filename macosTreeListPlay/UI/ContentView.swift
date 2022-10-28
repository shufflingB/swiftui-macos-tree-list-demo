//
//  ContentView.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 16/10/2022.
//

import SwiftUI







typealias Selection = Set<UUID>

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    let lst = AutoExpandingDisclosureGroupStyle()

    var body: some View {
        List(selection: $selectionIds) {
            OutlineGroup($appModel.itemsAtTopLevel, children: \.children) { $item in
                Row(item: item)
            }

            .disclosureGroupStyle(lst)
        }
        .listStyle(.sidebar)

        #if canImport(AppKit)
        #else
            VStack {
                Text("iPadOS Target tree (can't drag in same tree)")
                List {
                    OutlineGroup($appModel.itemsAtTopLevel, children: \.children) { $item in

                        Row(item: item)
                    }

                    .disclosureGroupStyle(lst)
                }
                .listStyle(.sidebar)
            }
        #endif
    } // End of body

    @State private var selectionIds = Selection() // Stores what is currently selected
    @State private var draggingIds = Selection() // Stores what is being dragged
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


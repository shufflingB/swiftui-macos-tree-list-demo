//
//  ContentView_ParentRow.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 24/11/2021.
//

import SwiftUI

extension ContentView {
    struct ParentRow: View {
        let item: Item

        var body: some View {
            Label {
                Text(item.title)
            } icon: {
                Image(systemName: "folder.fill")
            }
        }
    }
}

struct ContentView_ParentRow_Previews: PreviewProvider {
    static var previews: some View {
        let item = Item("Test Parent", priority: Date(), isParent: true, children: [Item("Test Child", priority: Date())], complete: false)
        ContentView.ParentRow(item: item)
    }
}

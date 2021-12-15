//
//  ContentView_ChildRow.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 24/11/2021.
//

import os
import SwiftUI

extension ContentView {
    struct ChildRow: View {
        @ObservedObject var item: Item
        var body: some View {
            HStack {
                Toggle("", isOn: $item.complete)
                Label {
                    Text(item.title)
                } icon: {
                    Image(systemName: "envelope")
                }
            }

        }
    }
}

fileprivate let log = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: #file.components(separatedBy: "/").last ?? ""
)

struct ContentView_ChildRow_Previews: PreviewProvider {
    static var previews: some View {
        let item = Item("Test Child", priority: Date())
        ContentView.ChildRow(item: item)
    }
}

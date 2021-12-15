//
//  ContentView_Row.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 19/11/2021.
//

import SwiftUI

extension ContentView {

    
    struct Row: View {
        @ObservedObject var dItem: DisplayItem
        var body: some View {
            if dItem.item.isParent {
                VStack(alignment: .leading) {
                    ContentView.ParentRow(item: dItem.item)
                }

            } else if dItem.markerItem {
                VStack(alignment: .leading) {
                    Divider()
                }
            } else {
                VStack(alignment: .leading) {
                    ContentView.ChildRow(item: dItem.item)
                }
            }
        }
    }
}

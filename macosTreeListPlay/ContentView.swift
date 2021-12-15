//
//  ContentView.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 19/11/2021.
//

import os
import SwiftUI

struct ContentView: View {
    @EnvironmentObject internal var appModel: AppModel

    var body: some View {
        List(selection: $selection) {
            ForEach(displayItems) { di in

                VStack(alignment: .leading) {
                    ContentView.Row(dItem: di)
                        .alignmentGuide(.leading, computeValue: { _ in CGFloat(di.depth) * -15.00 })
                }
            }
            .onMove(perform: onMoveHdlr)
        }
    }

    @State private var selection: Set<UUID> = []

    internal var displayItems: Array<DisplayItem> {
//            log.debug("Calculating sorted items")
        let unFlattendedTopLevel: Array<Array<DisplayItem>> = appModel.items
            .sorted(by: { $0.priority < $1.priority })
            .map({ topLevelItem in
                recurseItem(topLevelItem, parent: nil, depth: 0)
            })
        return unFlattendedTopLevel.flatMap({ $0 })
    }
}

fileprivate let log = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: #file.components(separatedBy: "/").last ?? ""
)

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

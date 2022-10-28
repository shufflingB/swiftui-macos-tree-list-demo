//
//  macosTreeListPlayApp.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 19/11/2021.
//

import SwiftUI

let TestData = [
    Item("Inbox", isFolder: true,
         children: [Item("Friends", isFolder: true,
                         children: [
                             Item("FBook", isFolder: true,
                                  children: [
                                      Item("Mostly harmless"),
                                      Item("Re: Mostly harmless"),
                                  ]),

                             Item("Birthday party", read: true),
                             Item("Re: Birthday party")]),
                    Item("Work", isFolder: true,
                         children: [Item("Next meeting", read: true),
                                    Item("Team building")]),
                    Item("Holidays!", read: true),
                    Item("Report needed", read: false)]),
    Item("Spam", isFolder: true,
         children: [Item("[SPAM] Open now!"),
                    Item("[SPAM] Limited time offer")]),
    Item("Trash", isFolder: true,
         children: []),
]

@main
struct macosTreeListPlayApp: App {
    @StateObject private var model = AppModel(items: TestData)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}

//
//  File.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 19/11/2021.
//

import Foundation
import os

class AppModel: ObservableObject {
    @Published var items: Array<Item> = []

    static let DELTA: TimeInterval = TimeInterval(31536000.0) /// Default time interval to use when open ended priority needed + yr )plenty of space

    init(addTestData: Bool = false) {
        if addTestData {
            self.addTestData()
        }
    }
}

extension AppModel {
    func addTestData() {
        func postInc() -> Date {
            let t = d
            d = d + Self.DELTA
            let f = D + t
            // log.debug("postInc f = \(f)")
            return f
        }

        let D = Date()
        var d = Self.DELTA

        /// Simplest test data, assign to items to use
        _ = [
            Item("Blah 1", priority: postInc()),
            Item("Blah 2", priority: postInc()),
            Item("Blah 3", priority: postInc()),
            Item("Blah 4", priority: postInc()),
        ]

        /// Slight more complicated test data
        _ = [
            Item("Bob 1", priority: postInc()),
            Item("Bob 2", priority: postInc()),
            Item(
                "Inbox",
                priority: postInc(),
                isParent: true,
                movable: false,
                children: [
                    Item("Blah Blah blah", priority: postInc()),
                    Item("Friends",
                         priority: postInc(),
                         isParent: true,
                         children: [
                             Item("Foo 1",
                                  priority: postInc()
                             ),
                             Item("Foo 2", priority: postInc()),
                         ]
                    ),
                ]
            ),
            Item("Blah 2", priority: postInc()),
            Item("Blah 3", priority: postInc()),
        ]

        /// Most complicated test data
        items = [
            Item(
                "Inbox",
                priority: Date(),
                isParent: true,
                movable: false,
                children: [
                    Item("Friends",
                         priority: Date(),
                         isParent: true,
                         children: [
                             Item("Birthday party",
                                  priority: Date(),
                                  isParent: true,
                                  children: [
                                      Item("Blah 1", priority: Date()),
                                      Item("Blah 2", priority: Date()),
                                  ]
                             ),
                             Item("Re: Birthday party", priority: Date()),
                         ]),
                    Item("Work",
                         priority: Date(),
                         isParent: true,
                         children: [
                             Item("Next meeting", priority: Date()),
                             Item("Team building", priority: Date()),
                         ]),
                    Item("Holidays!", priority: Date()),
                    Item("Report needed", priority: Date()),
                ]
            ),
            Item(
                "Spam",
                priority: Date(),
                isParent: true,
                movable: false,
                children: [
                    Item("[SPAM] Open now!", priority: Date()),
                    Item("[SPAM] Limited time offer", priority: Date()),
                ]
            ),
            Item("Trash",
                 priority: Date(),
                 isParent: true,
                 movable: false,
                 children: []),
        ]
    }
}

fileprivate let log = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: #file.components(separatedBy: "/").last ?? ""
)

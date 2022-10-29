//
//  FolderRow+DropDelegate.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 24/10/2022.
//

import SwiftUI

extension Parent: DropDelegate {
    func dropEntered(info: DropInfo) {
        isTargeted = true
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func validateDrop(info: DropInfo) -> Bool {
        true
//        return appModel.itemsToMoveIsValid(for: , into: item)
    }

    func performDrop(info: DropInfo) -> Bool {
        info.itemProviders(for: [.text])
            .forEach { p in
                _ = p.loadObject(ofClass: String.self) { text, _ in
                    appModel.providerDecode(loadedString: text)
                        .forEach { itemDropped in
                            DispatchQueue.main.async {
                                print("On drop parent = \(item.name) adopting \(itemDropped.name)")
                                withAnimation {
                                    item.adopt(child: itemDropped)
                                }
                            }
                        }
                }
            }
        return true
    }
}

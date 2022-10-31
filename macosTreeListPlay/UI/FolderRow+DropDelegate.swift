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
        info.itemProviders(for: [.text]).count > 0 ? true : false
        /// All we can do is check we've got an accepted type.
        /// Cannot do any other validation here bc the decoding happens asynchronously and we therefore do not have the ability
        /// to inspect the payload more thoroughly.
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

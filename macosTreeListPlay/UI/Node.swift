//
//  Node.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 29/10/2022.
//

import SwiftUI

struct Node: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var parent: Item

    @State var items: Array<Item>

    var body: some View {
        ForEach(items) { (item: Item) in
            if item.isFolder == false {
                Label(item.name, systemImage: "doc.text")
                    .onDrag {
                        appModel.providerEncode(id: item.id)
                    }

            } else {
                Parent(item: item)
            }
        }

        .onInsert(of: [.text]) { edgeIdx, providers in
            print("Got edgeIdx = \(edgeIdx), parent = \(parent.name) provider count = \(providers.count)")
            providers.forEach { p in
                _ = p.loadObject(ofClass: String.self) { text, _ in

                    appModel.providerDecode(loadedString: text)
                        .forEach { item in
                            DispatchQueue.main.async {
                                print("New parent = \(parent.name) adopting \(item.name)")
                                self.parent.adopt(child: item)
                            }
                        }
                }
            }
        }
        .onReceive(parent.children.publisher, perform: { newArray in
            items = newArray
        })
    }
}

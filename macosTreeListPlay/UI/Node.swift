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

    @State var children: Array<Item>

    var body: some View {
        ForEach(children) { (childItem: Item) in
            if childItem.isFolder == false {
                Label(childItem.name, systemImage: "doc.text")
                    .onDrag {
                        appModel.providerEncode(id: childItem.id)
                    }

            } else {
                Parent(item: childItem)
            }
        }

//        .onInsert(of: [.text]) { edgeIdx, providers in
//            print("Got edgeIdx = \(edgeIdx), parent = \(parent.name) provider count = \(providers.count)")
//            providers.forEach { p in
//                _ = p.loadObject(ofClass: String.self) { text, _ in
//
//                    appModel.providerDecode(loadedString: text)
//                        .forEach { item in
//                            DispatchQueue.main.async {
//                                print("New parent = \(parent.name) adopting \(item.name)")
//                                self.parent.adopt(child: item)
//                            }
//                        }
//                }
//            }
//        }
        .onReceive(parent.children.publisher, perform: { newArray in
            print("Parent \(parent.name), got a kids update")
//            DispatchQueue.main.async {
                withAnimation {
                    children = newArray
                }
//            }
            
        })
    }
}

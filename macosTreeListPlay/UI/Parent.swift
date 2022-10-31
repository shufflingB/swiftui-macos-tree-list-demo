//
//  Parent.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 29/10/2022.
//

import SwiftUI
// Not great ...
// 1) Drag has to be on the actual item, can't just grab the row.
// 2) Dragging preview for structured items is not a nice preview of the structure from which the items
// were selected.
// Cannot select root level items
// 3) Appearance not very macOS native like

struct Parent: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var item: Item

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Node(parent: item)
        } label: {
            Group {
                if item.parent == nil { // Has no parent
                    Label(item.name, systemImage: "folder.badge.questionmark")
                } else {
                    Label(item.name, systemImage: "folder")
                        .onDrag {
                            appModel.providerEncode(id: item.id)
                        }
                }
            }
            .onDrop(of: [.text], delegate: self)
        }
        .onTapGesture() {
            isExpanded.toggle()
        }
    }

    @State internal var isTargeted: Bool = false
    @State private var isExpanded: Bool = false
}

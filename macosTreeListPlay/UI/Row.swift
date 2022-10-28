//
//  Row.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 26/10/2022.
//

import SwiftUI

struct Row: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var item: Item

    var body: some View {
        Group {
            
            if item.isFolder {
                if item.parent == nil { /// i.e. Prevent dragging of root items
                    Label(item.name, systemImage: "folder.fill")
                } else {
                    Label(item.name, systemImage: "folder.fill")
                        .onDrag {
                            NSItemProvider(object: item.id.uuidString as NSString)
                        }
                        
                
                }

            } else {
                Button {
                    item.read.toggle()
                } label: {
                    Label(item.name, systemImage: item.read ? "mail" : "mail.fill")
                        .onDrag {
                            NSItemProvider(object: item.id.uuidString as NSString)
                        }
                }
                .buttonStyle(.plain)
                //                Text(item.name)
                Spacer()
            }
        }
        .onChange(of: item.read) { _ in
            appModel.objectWillChange.send()
        }
        .preference(key: RowPrefDataKey.self, value: RowPrefData(name: item.name, id: item.id))
        /// The preference key is used to feed the Item's identity information up to the style delegate that actually renders the row so that it knows on whiich folder the
        /// the item was dropped.
    }
}

struct RowPrefData: Equatable {
    let name: String
    let id: UUID
}

struct RowPrefDataKey: PreferenceKey {
    typealias Value = RowPrefData

    static var defaultValue: RowPrefData = RowPrefData(name: "", id: UUID())

    static func reduce(value: inout RowPrefData, nextValue: () -> RowPrefData) {
        value = nextValue()
    }
}

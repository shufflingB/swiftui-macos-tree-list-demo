//
//  ItemRow.swift
//  TreeViewPlay
//
//  Created by Jonathan Hume on 17/10/2022.
//

import SwiftUI

struct DefaultRow: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var item: Item
    @Binding var selectionIds: Selection
    @Binding var draggingIds:Selection
    
    var body: some View {
        HStack {
            Toggle("", isOn: $item.read)
            Label(item.name, systemImage: "envelope")
            Spacer()
        }
        .onDrag {
            draggingIds = draggingSelection
            /// Can use any string here we like, just need to provide something for NSItemProvider to satisfy D&D requirements.
            ///  for why see comment in `FolderRow`
            return NSItemProvider(object: "Message from \(item.name)" as NSString)
        }
        .onChange(of: item.read) { newValue in
            appModel.objectWillChange.send()
        }
    }
    
    private var draggingSelection: Selection {
        selectionIds.count == 0 || selectionIds.contains(item.uuid) == false
            ? [item.uuid]
            : selectionIds
    }
}

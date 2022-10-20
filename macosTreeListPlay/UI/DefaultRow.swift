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
    @Binding var selection: Selection
    
    var body: some View {
        HStack {
            Toggle("", isOn: $item.read)
            Label(item.name, systemImage: "envelope")
            Spacer()
        }
        .onDrag {
            // print("dragging \(draggingSelection.description)")
            let msg = draggingSelection.map({ $0.uuidString }).joined(separator: ",")
            return NSItemProvider(object: msg as NSString)
        }
        .onChange(of: item.read) { newValue in
            appModel.objectWillChange.send()
        }
    }
    
    private var draggingSelection: Selection {
        selection.count == 0 || selection.contains(item.uuid) == false
            ? [item.uuid]
            : selection
    }
}

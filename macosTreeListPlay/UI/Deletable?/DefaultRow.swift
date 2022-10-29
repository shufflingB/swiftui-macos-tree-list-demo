//
//  DefaultRow.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 17/10/2022.
//

import SwiftUI

struct DefaultRow: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var item: Item
    @Binding var selectionIds: AppModel.Selection
    @Binding var draggingIds: AppModel.Selection

    var body: some View {
        HStack {
            Toggle("", isOn: $item.read)
            Label(item.name, systemImage: "envelope")
            Spacer()
        }
        .onDrag({
            draggingIds = AppModel.Selection(appModel.itemIdsToMove(
                dragItemId: item.id,
                selectionIds: selectionIds
            ))
            self.appModel.isDragging = true

            /// Can use any string here we like, just need to provide something for NSItemProvider to satisfy D&D requirements.
            ///  for why see comment in `FolderRow`
            return NSItemProvider(object: "Message from \(item.name)" as NSString)
        }
        , preview: {
            DraggingPreview(
                draggingSelectionItems: appModel.itemsToMove(
                    dragItemId: item.id,
                    selectionIds: selectionIds
                )
            )
            .onDisappear {
                self.appModel.isDragging = false
            }

        })
        .onChange(of: item.read) { _ in
            appModel.objectWillChange.send()
        }
    }
}

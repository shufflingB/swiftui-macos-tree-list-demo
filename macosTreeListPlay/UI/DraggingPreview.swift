//
//  DraggingPreview.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 23/10/2022.
//

import SwiftUI

struct DraggingPreview: View {
    let draggingSelectionItems: Array<Item>

    var body: some View {
        // NB:  Don't use List here bc SwiftUI's built in styling for List's in the  context of the drag preview
        // does not know what it is doing and renders it basically as invisible. (easy to forgive A this foible given it does know how
        // to handle Watches, TV, mac and iPhones)
        VStack(alignment: .leading) {
            ForEach(draggingSelectionItems) { item in
                if item.isFolder {
                    TreePreview(item: item)
                } else {
                    RowPreview(item: item)
                }
            }
        }
    }
}

extension DraggingPreview {
    struct TreePreview: View {
        let item: Item

        var body: some View {
            if item.isFolder {
                FolderPreview(item: item)

            } else {
                RowPreview(item: item)
            }
        }
    }

    struct FolderPreview: View {
        let item: Item

        var body: some View {
            DisclosureGroup(
                isExpanded: .constant(true),
                content: {
                    ForEach(item.children ?? [], id: \.uuid) { item in
                        FolderPreview(item: item)
                    }
                },
                label: {
                    HStack {
                        Text(item.name)
                        Spacer()
                    }
                }
            )
        }
    }

    struct RowPreview: View {
        let item: Item
        var body: some View {
            Text(item.name)
        }
    }
}

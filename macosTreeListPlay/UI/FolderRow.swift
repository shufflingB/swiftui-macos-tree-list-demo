//
//  FolderRow.swift
//  TreeViewPlay
//
//  Created by Jonathan Hume on 17/10/2022.
//

import SwiftUI

struct FolderRow: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var aet: AutoExpandedTracker

    @ObservedObject var folderItem: Item
    @Binding var selection: Selection

    /// How many seconds after a folder stops being the drop target is it kept open for in order to allow the user to browse to an alternative folder below it in the hierarchy
    /// (Current mechanism only sets a drop target on  Folders, so if a possible drop target is at the bottom of a long list this might need to be longer)
    // TODO: Add something that stops collapse when user is hovering over normal items as well as folders.
    static let DisclosureGroupHoldOffTimeCollapse = 2.0

    /// How many seconds to hold of expanding a folder so that the user doesn't inadvertantly auto expand all folder they browse over
    static let DisclosureGroupHoldOffTimeExpand = 1.0

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                ForEach(folderItem.children ?? [], id: \.uuid) { item in
                    Row(item: item, selection: $selection)
                }
            },
            label: {
                HStack {
                    Text(folderItem.name)
                    Spacer()
                }
                .onDrop(of: [.text], isTargeted: $isDropTgt, perform: onDropHdlr)
                .onDrag( {
                    let msg = draggingSelection.map({ $0.uuidString }).joined(separator: ",")
                    return NSItemProvider(object: msg as NSString)
                }, preview: {
                    if folderItem.parent == nil {
                        Image(systemName: "nosign")
                            .font(.largeTitle)
                    } else {
                        Text("Valid to drag")
                    }
                })
                .onChange(of: isDropTgt) { newValue in
                    if newValue == true {
                        withAnimation {
                            selection = [folderItem.uuid]
                        }

                        dwiTriggerDelayedFolderExpand = DispatchWorkItem {
                            if isDropTgt == true {
                                dwiTriggerDelayedFolderCollapse?.cancel()

                                aet.push(ifNotFirstOut: folderItem) // Don't push onto stack multiple times

                                selectionCache = selection
                                isExpandedCache = isExpanded

                                withAnimation {
                                    isExpanded = true
                                }
                            }
                        }
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + Self.DisclosureGroupHoldOffTimeExpand,
                            execute: dwiTriggerDelayedFolderExpand!
                        )

                    } else {
                        withAnimation {
                            selection = selectionCache
                        }

                        /// A work item is used to  collapse of the DisclosureGroup  after giving the user a bit of time to browse to an item below it
                        dwiTriggerDelayedFolderCollapse = DispatchWorkItem {
                            if aet.firstOut == folderItem {
                                dwiTriggerDelayedFolderExpand?.cancel()
                                /// Then we have:
                                /// 1) This job only runs when the user doesn't have this item as the DropTarget
                                /// 2)  And the user isn't browsed somewhere else below it so we do not need to worry about keeping it open.
                                /// QED: we should be okay to collapse the folder if that was the user previously had set
                                withAnimation {
                                    isExpanded = isExpandedCache
                                }
                                _ = aet.pop()
                            }
                        }

                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + Self.DisclosureGroupHoldOffTimeCollapse,
                            execute: dwiTriggerDelayedFolderCollapse!
                        )
                    }
                }
                .onChange(of: aet.firstOut) { newFirstOut in
                    if newFirstOut == folderItem && isDropTgt == false {
                        DispatchQueue.main.async {
                            withAnimation {
                                isExpanded = isExpandedCache
                            }
                            _ = aet.pop()
                        }
                    }
                }
            }
        )
    }

    @State private var isDropTgt: Bool = false
    @State private var selectionCache: Selection = []
    @State private var isExpanded: Bool = false
    @State private var isExpandedCache: Bool = false
    @State private var dwiTriggerDelayedFolderCollapse: DispatchWorkItem? = nil
    @State private var dwiTriggerDelayedFolderExpand: DispatchWorkItem? = nil

    private var draggingSelection: Selection {
        selection.count == 0 || selection.contains(folderItem.uuid) == false
            ? [folderItem.uuid]
            : selection
    }

    private var draggingSelectionItems: Array<Item> {
        draggingSelection.compactMap { uuid in
            model.itemFind(uuid: uuid)
        }
    }

    private func onDropHdlr(_ providers: Array<NSItemProvider>) -> Bool {
        print("On drop tirggered providers count = \(providers.count)")

        providers.forEach { p in
            _ = p.loadObject(ofClass: String.self) { text, _ in

                guard let itemIdsConcatenated: String = text as String? else {
                    return
                }

                let potentiallyMovedItems: Array<UUID> = itemIdsConcatenated
                    .split(separator: ",")
                    .map { String($0) }
                    .compactMap({ UUID(uuidString: $0) })

                model.itemsMove(potentiallyMovedItems, into: folderItem)
            }
        }
        return true
    }
}

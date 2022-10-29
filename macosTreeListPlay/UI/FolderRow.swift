//
//  FolderRow.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 17/10/2022.
//

import SwiftUI

struct FolderRow: View {
    @EnvironmentObject var appModel: AppModel

    @ObservedObject var folderItem: Item
    @Binding var selectionIds: AppModel.Selection
    @Binding var draggingIds: AppModel.Selection

    /// How many seconds after a folder stops being the drop target is it kept open for in order to allow the user to browse to an alternative folder below it in the hierarchy
    static let DisclosureGroupHoldOffTimeCollapse = 2.0

    /// How many seconds to hold of expanding a folder so that the user doesn't inadvertantly auto expand all folder they browse over
    static let DisclosureGroupHoldOffTimeExpand = 1.0

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                ForEach(folderItem.children ?? [], id: \.id) { item in
                    Tree(item: item, selectionIds: $selectionIds, draggingIds: $draggingIds)
                }
                .onInsert(of: [.text]) { (_: Int, _: Array<NSItemProvider>) in
                    let insertItems = appModel.itemsFind(ids: draggingIds)
                    insertItems.forEach { item in
                        folderItem.adopt(child: item)
                    }
                    selectionIds = draggingIds
                    draggingIds = []
                }
            },
            label: {
                HStack {
                    Text(folderItem.name)
                    Spacer()
                }
                .id(folderItem.id)

                .onDrop(of: [.text], delegate: self)
                .onDrag({
                    /// To make dragging work we have to return and NSItemProvider. However, what's actually being dragged is not actually being communicated via the
                    /// that mechanism. Instead it is done through setting the`draggingIds` variable.
                    ///
                    /// Gone down this back channel route  (rather than the alternative of either creating our own UTType or enconding into a string, as discussed
                    /// in places such as https://www.waldo.com/blog/modern-swiftui-drag-and-drop-tutorial) and with example code illustration end of this file) because:
                    ///
                    /// 1)  The app has no need to provide functionallity for drag the Items into or out of it.
                    /// 2) The  full on route means having to employ  an onerous, slow decoding on drop process to verify what arrives at the drop targets.
                    ///  (see example of a decoding  the end of this file)
                    /// 3) Even when its onerous, the ability to verify the sanity of what is being dragged is limited due to having async loading of the dragged Items i.e. it
                    /// uses a completion handler, which make very unweildy to provide a visual (or otherwise) indication that. The most obvious instance of which being in this
                    /// instance the difficulty of providng feedback that folder's can't be dropped onto themselves (the receiver needs to know what's been dragged in order to
                    /// check it against the target, but the receiver does not know what's been dragged until it async loads the object. A works around this in their apps by allowing
                    /// the drop, but then triggering an annimated response that indicates what's happened, e.g. no movement with Finder,
                    draggingIds = AppModel.Selection(appModel.itemIdsToMove(dragItemId: folderItem.id, selectionIds: selectionIds))
                    appModel.isDragging = true

                    /// Can use any string here we like, just need to provide something for NSItemProvider to satisfy D&D requirements.
                    return NSItemProvider(object: "Message from \(folderItem.name)" as NSString)
                }, preview: {
                    if folderItem.parent == nil {
                        Image(systemName: "nosign")
                            .font(.largeTitle)
                            .onDisappear {
                                self.appModel.isDragging = false
                            }

                    } else {
                        DraggingPreview(
                            draggingSelectionItems: appModel.itemsToMove(
                                dragItemId: folderItem.id,
                                selectionIds: selectionIds
                            )
                        )
                        .onDisappear {
                            self.appModel.isDragging = false
                        }
                    }

                })

                .onChange(of: isDropTgt) { newValue in
                    if newValue == true {
                        // Cache the current list selection and then make List high light the drop target by setting it as the
                        // List's selection
                        selectionCache = selectionIds
                        withAnimation {
                            selectionIds = [folderItem.id]
                        }

                        // Have the list auto expand the moment the user mouses over is a bit 💩. Instead queue a job that will
                        // expand it only if the user is still hovering of the drop target at some point in the future.
                        dwiTriggerDelayedFolderExpand = DispatchWorkItem {
                            if isDropTgt == true {
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
                        // Restor the previous List selection
                        withAnimation {
                            selectionIds = selectionCache
                        }
                    }
                }
                .onChange(of: appModel.isDragging, perform: { newValue in
                    guard newValue == false && isExpanded != isExpandedCache else {
                        return
                    }
                    // Kill any queued job to expand this group.
                    dwiTriggerDelayedFolderExpand?.cancel()

                    // Restore to the pre-mouse over expansion state
                    DispatchQueue.main.asyncAfter(deadline: .now() + Self.DisclosureGroupHoldOffTimeCollapse) {
                        withAnimation {
                            isExpanded = isExpandedCache
                        }
                    }
                })
            }
        )
    }

    @State internal var isDropTgt: Bool = false
    @State private var selectionCache: AppModel.Selection = []
    @State private var isExpanded: Bool = false
    @State private var isExpandedCache: Bool = false
    @State private var dwiTriggerDelayedFolderCollapse: DispatchWorkItem? = nil
    @State private var dwiTriggerDelayedFolderExpand: DispatchWorkItem? = nil
}

/// Example  of how a similiar drag and drop operation could be done using the full-fat, supports export and import from other apps etc approach.
///
/// Add encoding provider modifier to  the items where drag is allow to commence from e.g. folder AND ordinary items.
///
///     .onDrag( {
///         let msg = draggingSelection.map({ $0.uuidString }).joined(separator: ",")
///         return NSItemProvider(object: msg as NSString)
///     }
///
/// Then add decoding functionallity to the onDrop targets and wire it into something that decodes what has been dragged into the app  e.g.
///
///         onDrop(of: [.text], $isDropTgt, perform: onDropHdlr)`
///
///
///         func onDropHdlr(_ providers: Array<NSItemProvider>) -> Bool {
///             print("On drop tirggered providers count = \(providers.count)")
///             providers.forEach { p in
///                 _ = p.loadObject(ofClass: String.self) { text, _ in
///
///                 guard let itemIdsConcatenated: String = text as String? else {
///                     return
///                 }
///
///                 let potentiallyMovedItems: Array<UUID> = itemIdsConcatenated
///                     .split(separator: ",")
///                     .map { String($0) }
///                     .compactMap({ UUID(uuidString: $0) })
///
///                 appModel.itemsMove(potentiallyMovedItems, into: folderItem)
///             }
///         }
///         return true
///     }
///
/// Decoding process is nearly identical when using a full fat `DropDelegate`, but setting `isDropTagt` type variables more a pita.
///


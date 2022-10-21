//
//  FolderRow.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 17/10/2022.
//

import SwiftUI

struct FolderRow: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var aet: AutoExpandedTracker

    @ObservedObject var folderItem: Item
    @Binding var selectionIds: Selection
    @Binding var draggingIds: Selection

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
                    Row(item: item, selectionIds: $selectionIds, draggingIds: $draggingIds)
                }
            },
            label: {
                HStack {
                    Text(folderItem.name)
                    Spacer()
                }

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
                    draggingIds = draggingSelection

                    /// Can use any string here we like, just need to provide something for NSItemProvider to satisfy D&D requirements.
                    return NSItemProvider(object: "Message from \(folderItem.name)" as NSString)
                }) // , preview: {
//                    if folderItem.parent == nil {
//                        Image(systemName: "nosign")
//                            .font(.largeTitle)
//
//                    } else {
//                        Text("Dragging \(draggingIds.count) items").font(.largeTitle)
//                    }
//
//                })

                .onChange(of: isDropTgt) { newValue in
                    if newValue == true {
                        withAnimation {
                            selectionIds = [folderItem.uuid]
                        }

                        dwiTriggerDelayedFolderExpand = DispatchWorkItem {
                            if isDropTgt == true {
                                dwiTriggerDelayedFolderCollapse?.cancel()

                                aet.push(ifNotFirstOut: folderItem) // Don't push onto stack multiple times

                                selectionCache = selectionIds
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
                            selectionIds = selectionCache
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
        selectionIds.count == 0 || selectionIds.contains(folderItem.uuid) == false
            ? [folderItem.uuid]
            : selectionIds
    }

    private var draggingSelectionItems: Array<Item> {
        draggingSelection.compactMap { uuid in
            appModel.itemFind(uuid: uuid)
        }
    }
}

extension FolderRow: DropDelegate {
    func dropEntered(info: DropInfo) {
        isDropTgt = true
    }

    func dropExited(info: DropInfo) {
        isDropTgt = false
    }

    func validateDrop(info: DropInfo) -> Bool {
        return appModel.itemsMoveIsValid(for: Array(draggingIds), into: folderItem)
    }

    func performDrop(info: DropInfo) -> Bool {
        appModel.itemsMove(Array(draggingIds), into: folderItem)
        draggingIds = []
        return true
    }
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

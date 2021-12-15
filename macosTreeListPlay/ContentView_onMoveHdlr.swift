//
//  ContentView_onMoveHdlr.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 13/12/2021.
//
import Foundation
import os


extension ContentView {
    func onMoveHdlr(_ fromOffsets: IndexSet, _ toOffset: Int) {
        log.debug("======================== onMoveHdlr ==================================")

        let (priorityBeforeBlock, priorityAfterBlock) = getBeforeAndAfterBlockPriorities(toOffset: toOffset)
        log.debug("priorityBeforeBlock = \(priorityBeforeBlock), priorityAfterBlock = \(priorityAfterBlock)")

        ///
        /// Remove any items from the list of items to move that are already included by dint of one or more of their parents being included.
        ///
        let endMarkerFiltered: IndexSet = fromOffsets.filteredIndexSet { offset in
            displayItems[offset].markerItem == false
        }
        
        let setOfParentItemsInMove: Set<UUID> = Set(
            fromOffsets
                .map({ displayItems[$0].item })
                .filter({ $0.isParent == true })
                .map({ $0.id })
        )
//        let parentFilteredFromOffsets: IndexSet = fromOffsets.filteredIndexSet { offset in
        let parentFilteredFromOffsets: IndexSet = endMarkerFiltered.filteredIndexSet { offset in
            let thisItemsAncestors: Array<UUID> = displayItems[offset].item.ancestors.map({ $0.id })
            if setOfParentItemsInMove.isDisjoint(with: thisItemsAncestors) {
                return true
            } else {
                return false
            }
        }
        
        guard parentFilteredFromOffsets.count > 0 else {
            log.debug("After filtering for end markers etc, nothing left to move")
            return
        }

        ///
        /// Use the built in array move method to actually move the items to the correct location because its fast and works - even if we will still need to update the relationship model for
        /// items afterwards.
        ///
        let allMovedDis: Array<DisplayItem> = {
            var t = displayItems
//            let noMarkersOffsets:IndexSet = IndexSet( moveRowsFromOffsets.filter({ displayItems[$0].markerItem == false }) )
            t.move(fromOffsets: parentFilteredFromOffsets, toOffset: toOffset)
            return t
        }()

        ///
        /// Re-calculate and update the relationships model for the items. We do that using the moved moved copy of the original array, and because of that
        /// in order to know where the moved block ended up we need to also know whether the block was dragged up our down
        ///
        let numItemsBeingMoved = parentFilteredFromOffsets.count
        let isDraggedUp: Bool = toOffset <= parentFilteredFromOffsets.sorted().first! ? true : false
        log.debug("Dragging up = \(String(describing: isDraggedUp))")
        let firstToOffset = isDraggedUp
            ? toOffset
            : toOffset - numItemsBeingMoved

        let lastToOffset = firstToOffset + numItemsBeingMoved - 1
        log.debug("First offset in updated = \(firstToOffset), last = \(lastToOffset) ")

        var expectedParentItem: Item? = getParentItem(toOffset: toOffset)

        var previousParentItem: Array<Item?> = []
        let movedDis = allMovedDis[firstToOffset ... lastToOffset]

        guard isNotCyclicTarget(parentItemForItemAtOffset: expectedParentItem, itemsBeingMoved: movedDis.map { $0.item }) else {
            log.debug("Not moving as detected a cyclic move")
            return
        }

        log.debug("Initial expectedParentItem for first moved item = \(expectedParentItem?.title ?? "no parent")")

        /// Iterate over the moved block and update the items parent and child relationships as necessary.
        movedDis.forEach { di in

            log.debug(" updating parent for item = \(di.item.title)")
            if di.item.parent == expectedParentItem {
                log.debug("No need to adjust parent")
            } else {
                log.debug("Need to adjust from current parent = \(di.item.parent?.title ?? "none") to tgt parent = \(expectedParentItem?.title ?? "none")")
                /// Remove from old parent if needed
                if di.item.parent != nil {
                    di.item.parent?.children = di.item.parent?.children?.filter { $0 != di.item }
                }
                /// Add to new parent if needed
                if expectedParentItem != nil {
                    expectedParentItem?.children?.append(di.item)
                }
                /// Finally ...
                di.item.parent = expectedParentItem

                if di.item.isParent {
                    previousParentItem.append(expectedParentItem)
                    expectedParentItem = di.item
                }

                if di.markerItem {
                    /// Adjust currentParent item to be previous parent item
                    if let item = previousParentItem.popLast() {
                        expectedParentItem = item
                    } else {
                        log.error("Unable to pop a previous parent item")
                    }
                }
            }
        }

        /// Determine priorities before and after the block we're going to impolate the moved block's priority values between.

        let stepSize: TimeInterval =
            (priorityAfterBlock.timeIntervalSince1970 - priorityBeforeBlock.timeIntervalSince1970) / Double(numItemsBeingMoved + 1)

        for (idx, di) in movedDis.enumerated() {
            di.item.priority = Date(timeIntervalSince1970: priorityBeforeBlock.timeIntervalSince1970 + Double(idx + 1) * stepSize)
        }

        /// Get rid of any marker items before we update what we have stored in the appModel
        let movedItemDis = movedDis.filter { $0.markerItem == false }
        log.debug("Update items to sync back to appModel.items\n \(movedItemDis.map { "\($0.item.title), parent = \($0.item.parent?.title ?? "root"), priority = \($0.item.priority)" }.joined(separator: "\n "))")

        /// Finallly! all thats needed now it to move any from root that need it and add any that have moved to root.  (priorities and non-root moves should already be sorted)
        let rootFilteredItems: Array<Item> = appModel.items.filter { $0.parent == nil }
        let addToRootItems: Array<Item> = movedItemDis.map { $0.item }.filter { $0.parent == nil && !rootFilteredItems.contains($0) }

        appModel.items = rootFilteredItems + addToRootItems /// Update our appModel and sync changes to any other observers
    } /// end of onMoveHdlr
    


    /// Avoid dragging a target onto a child of itself i.e. cyclic
    private func isNotCyclicTarget(parentItemForItemAtOffset: Item?, itemsBeingMoved: Array<Item>) -> Bool {
        guard let parentItemForItemAtOffset = parentItemForItemAtOffset else {
            log.debug("ReturningisNotCyclicTarget true because parent is root ")
            return true
        }
        ///log.debug("toOffsets parents = \(toOffsetParentItem.getParentItems().map({ $0.title }).joined(separator: ">>"))")
        let thisParentsParents: Set<UUID> = Set(parentItemForItemAtOffset.ancestors.map({ $0.id })).union([parentItemForItemAtOffset.id])
        let itemsBeingMovedSet: Set<UUID> = Set(itemsBeingMoved.map({ $0.id }))
        return thisParentsParents.isDisjoint(with: itemsBeingMovedSet)
    }

    private func getParentItem(toOffset: Int) -> Item? {
        if toOffset >= 1 { // then not at the top, if at the top then there is no parentItem
            if displayItems[toOffset - 1].markerItem == false {
                if displayItems[toOffset - 1].item.isParent {
                    return displayItems[toOffset - 1].item
                } else {
                    return displayItems[toOffset - 1].item.parent
                }
            } else { /// Scan up looking for the paretn at the same depth as the end marker and its' parent is the parent item we want
                let matchingParentLevel = displayItems[toOffset - 1].depth - 1
                for idxToCheck in (0 ... (toOffset - 2)).reversed() {
                    if displayItems[idxToCheck].depth == matchingParentLevel && displayItems[idxToCheck].item.isParent {
                        return displayItems[idxToCheck].item.parent
                    }
                }
                // Haven't found suitable so return a nil
                log.debug("Didn't find anything")
                return nil
            }
        } else {
            return nil
        }
    }

    private func getBeforeAndAfterBlockPriorities(toOffset: Int) -> (Date, Date) {
        var before = Date()
        var after = Date()

        switch toOffset {
        case 0:
            let ai = displayItems[0].item
            log.debug("Moved to beginning of list, after priority from \(ai.title)")
            after = ai.priority
            before = after + (-AppModel.DELTA)
        case displayItems.count:
            let bi = displayItems[toOffset - 1].item
            log.debug("Moved to end of list, before priority from \(bi.title)")
            before = bi.priority
            after = before + AppModel.DELTA
        default:
            let bi = displayItems[toOffset - 1].item
            let ai = displayItems[toOffset].item
            log.debug("Moved between \(bi.title) and \(ai.title)")
            before = bi.priority
            after = ai.priority
        }

        return (before, after)
    }
}

fileprivate let log = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: #file.components(separatedBy: "/").last ?? ""
)

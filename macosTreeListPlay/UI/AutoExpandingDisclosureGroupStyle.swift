//
//  ListTreeStyle.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 26/10/2022.
//

import Introspect
import SwiftUI

// protocol DisclosureGroupStyleE: DisclosureGroupStyle where Configuration.Content: DynamicViewContent {
// }

// extension DisclosureGroupStyle where Self ==  ListTreeStyle {
//
//
// }

// extension DisclosureGroupStyleConfiguration {
//    static let poop = ""
// }

struct AutoExpandingDisclosureGroupStyle: DisclosureGroupStyle {
    @EnvironmentObject var appModel: AppModel

    let level: Int

    init(level: Int = 0) {
        self.level = level
    }

    @State var isDropTarget = false
    @State var isExpandedCache = false

    @State var rowPreferenceData: RowPrefData? = nil

    func makeBody(configuration: DisclosureGroupStyleConfiguration) -> some View {
        return Group {
            HStack {
                Button {
                    withAnimation {
                        configuration.isExpanded.toggle()
                    }
                } label: {
                    configuration.isExpanded
                        ? Image(systemName: "chevron.down")
                        : Image(systemName: "chevron.right")
                }
                HStack {
                    configuration.label
                        .onPreferenceChange(RowPrefDataKey.self) { prefData in
                            rowPreferenceData = prefData
                        }

                    Spacer()
                }

                .onDrop(of: [.text], isTargeted: $isDropTarget) { providers in
//                    print(Str(reflecting: configuration.label))
                    print("On drop triggered for item = \(rowPreferenceData)  providers count = \(providers.count)")
                    providers.forEach { p in
                        _ = p.loadObject(ofClass: String.self) { text, _ in

                            guard let itemIdsConcatenated: String = text as String? else {
                                return
                            }
                            let potentiallyMovedItems: Array<UUID> = itemIdsConcatenated
                                .split(separator: ",")
                                .map { String($0) }
                                .compactMap({ UUID(uuidString: $0) })

//                            appModel.itemsMove(potentiallyMovedItems, into: folderItem)
                        }
                    }
                    return true
                }

                .onChange(of: isDropTarget) { newValue in

                    if newValue {
                        isExpandedCache = configuration.isExpanded
                        print("Got targetted")
                        configuration.isExpanded = true
                    } else {
                        configuration.isExpanded = isExpandedCache
                    }
                }
            }

            .buttonStyle(.plain) // <- Magic, enables selection to pick individual rows in the expanded discloure group
            .animation(nil, value: configuration.isExpanded)

            if configuration.isExpanded {
                configuration
                    .content
                    .alignmentGuide(.leading, computeValue: { _ in CGFloat(level + 1) * -20.00 })
                    .listStyle(.plain)
                    .disclosureGroupStyle(AutoExpandingDisclosureGroupStyle(level: level + 1))
            }
        }
        .frame(alignment: .leading)
    }

    func renderContent(_ content: DisclosureGroupStyleConfiguration.Content) -> some View {
        func dvc<T: DynamicViewContent>(_ content: T) -> some View {
            return content
        }

        return content
    }
}

// extension ListTreeStyle: DropDelegate {
//    func dropEntered(info: DropInfo) {
//        isDropTarget = true
//    }
//
//    func dropExited(info: DropInfo) {
//        isDropTarget = false
//    }
//
//    func validateDrop(info: DropInfo) -> Bool {
//        return appModel.itemsToMoveIsValid(for: Array(draggingIds), into: folderItem)
//    }
//
//    func performDrop(info: DropInfo) -> Bool {
//        appModel.itemsMove(Array(draggingIds), into: folderItem)
//        selectionIds = draggingIds
//        draggingIds = []
//        return true
//    }
// }

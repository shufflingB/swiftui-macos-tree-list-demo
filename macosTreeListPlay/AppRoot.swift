//
//  macosTreeListPlayApp.swift
//  macosTreeListPlay
//
//  Created by Jonathan Hume on 19/11/2021.
//

import SwiftUI

@main
struct AppRoot: App {
    
    @StateObject private var appModel = AppModel(addTestData: true)
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }
    }
}

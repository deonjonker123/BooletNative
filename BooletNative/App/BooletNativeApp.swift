//
//  BookletApp.swift
//  Booklet
//
//  App entry point
//

import SwiftUI

@main
struct BookletApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1400, height: 900)
    }
}

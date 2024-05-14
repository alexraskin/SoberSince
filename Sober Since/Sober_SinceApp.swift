//
//  QuoteFetcher.swift
//  Sober Since
//
//  Created by Alex Raskin on 5/13/24.
//

import SwiftUI

@main
struct MyApp: App {
    @StateObject private var timerManager = TimerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
        }
    }
}

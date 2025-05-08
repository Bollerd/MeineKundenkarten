//
//  MeineKundenkartenWatchApp.swift
//  MeineKundenkartenWatch Watch App
//
//  Created by Dirk Boller on 26.12.2024.
//

import SwiftUI

@main
struct MeineKundenkartenWatch_Watch_AppApp: App {
    @StateObject private var watchReceiveModel = WatchReceiveModel()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(watchReceiveModel).onAppear {
                _ = WatchConnectivityManager.shared.setWatchReceiveModel(watchReceiveModel) // Initialisiere die WCSession
            }
        }
    }
}

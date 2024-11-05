//
//  Meine_KundenkartenApp.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 21.12.23.
//

import SwiftUI
import TipKit

@main
struct Meine_KundenkartenApp: App {
    @StateObject var launchScreenState = LaunchScreenStateManager()
    @Environment(\.keyboardShowing) var keyboardShowing
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView().environmentObject(Model())
                if ENABLE_LAUNCH_SCREEN {
                    if launchScreenState.state != .finished {
                        LaunchScreenView()
                    }
                }
            }.environmentObject(launchScreenState).addKeyboardVisibilityToEnvironment()
        }
    }
    
   init() {
       if #available(iOS 17.0, *) {
       //    try? Tips.resetDatastore()
        //   print("datastore was reset")
           try? Tips.configure([
            .displayFrequency(.hourly),
            .datastoreLocation(.applicationDefault)
        ])
       } else {
           // Fallback on earlier versions
       }
    }
}

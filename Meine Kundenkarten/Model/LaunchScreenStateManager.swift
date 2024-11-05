//
//  LaunchScreenStateManager.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 02.01.24.
//

import Foundation

final class LaunchScreenStateManager: ObservableObject {

@MainActor
    @Published private(set) var state: LaunchScreenStep = .firstStep

    @MainActor
    func dismiss() {
        Task {
            state = .secondStep

            try? await Task.sleep(for: Duration.seconds(1))

            self.state = .finished
        }
    }
}

enum LaunchScreenStep {
    case firstStep
    case secondStep
    case finished
}

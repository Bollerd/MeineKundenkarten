//
//  LaunchScreenView.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 02.01.24.
//

import SwiftUI

struct LaunchScreenView: View {
    @EnvironmentObject private var launchScreenState: LaunchScreenStateManager // Mark 1

    @State private var firstAnimation = false  // Mark 2
    @State private var secondAnimation = false // Mark 2
    @State private var startFadeoutAnimation = false // Mark 2
    
    @ViewBuilder
    private var image: some View {  // Mark 3
        VStack {
            Spacer(minLength: 50)
            //Image(systemName: "hurricane")
            Image(systemName: "creditcard")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .rotationEffect(firstAnimation ? Angle(degrees: 900) : Angle(degrees: 1800)) // Mark 4
                .scaleEffect(secondAnimation ? 0 : 1) // Mark 4
                .offset(y: secondAnimation ? 400 : 0) // Mark 4
            Spacer(minLength: 20)
            Text("Deine Karten").font(.title).padding()
            Text("Deine Karten, deine Daten, rasend schnell!")
            Text("Made with ❤️ in SwiftUI by Dirk Boller").font(.footnote)
        }
    }
    
    @ViewBuilder
    private var backgroundColor: some View {  // Mark 3
        Color.accentColor.ignoresSafeArea()
    }
    
    private let animationTimer = Timer // Mark 5
        .publish(every: 0.5, on: .current, in: .common)
        .autoconnect()
    
    var body: some View {
        ZStack {
            backgroundColor  // Mark 3
            image  // Mark 3
        }.onReceive(animationTimer) { timerValue in
            updateAnimation()  // Mark 5
        }.opacity(startFadeoutAnimation ? 0 : 1)
    }
    
    private func updateAnimation() { // Mark 5
        switch launchScreenState.state {
        case .firstStep:
            withAnimation(.easeInOut(duration: 0.9)) {
                firstAnimation.toggle()
            }
        case .secondStep:
            if secondAnimation == false {
                withAnimation(.linear) {
                    self.secondAnimation = true
                    startFadeoutAnimation = true
                }
            }
        case .finished:
            // use this case to finish any work needed
            break
        }
    }
    
}

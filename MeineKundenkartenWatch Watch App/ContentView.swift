//
//  ContentView.swift
//  MeineKundenkartenWatch Watch App
//
//  Created by Dirk Boller on 26.12.2024.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var exchangeModel: WatchReceiveModel
    
    var body: some View {
       // Text(exchangeModel.message).font(.caption2)
        NavigationView {
            if exchangeModel.cards.isEmpty {
                Text("Keine Karten auf der Uhr gespeichert")
                Text(exchangeModel.initMessage).font(.caption2)
            } else {
                List($exchangeModel.cards) { card in
                    NavigationLink(destination: DetailView( card: card )) {
                        Text("\(card.description.wrappedValue)").frame(maxWidth: .infinity) // Vollständige Breite
                            .padding()
                            .background(card.cardColor.wrappedValue.toSwiftUIColor()) // Hintergrundfarbe
                            .foregroundColor(card.fontColor.wrappedValue.toSwiftUIColor()) // Textfarbe
                            .cornerRadius(8)
                            //.foregroundColor(card.fontColor.wrappedValue.toSwiftUIColor())//    .background(card.cardColor.wrappedValue.toSwiftUIColor())
                    }.listRowBackground(Color.clear)
                }
            }
        }
        
    }
}

struct DetailView: View {
    @EnvironmentObject var exchangeModel: WatchReceiveModel
    @Binding var card: DataObject
    var body: some View {
        card.generateJSBarcode().frame(width: 140, height: 140)
    }
}

struct ContentView2: View {
    @EnvironmentObject var exchangeModel: WatchReceiveModel
    
    var body: some View {
        ScrollView {
            exchangeModel.barcode
                .resizable()
                    .interpolation(.high)
                    .scaledToFit().foregroundStyle(.tint).frame(width: 140, height: 140)
            Text(exchangeModel.message).font(.caption2)
            Button("Daten senden") {
                WatchConnectivityManager.shared.sendDataToiPhone(data: "Hallo vom Watch! \(Date())")
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(WatchReceiveModel())
}

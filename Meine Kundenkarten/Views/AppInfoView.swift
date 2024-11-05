//
//  AppInfoView.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 04.01.24.
//

import SwiftUI

struct AppInfoView: View {
    var body: some View {
        ScrollView {
            Text("Meine Kundenkarten").font(.title).padding(.bottom)
            Text("Diese App bietet dir die Möglichkeit deine Kundenkarten digital zu speichern, um alle Karten mit einer App verwenden zu können. Deine Daten werden nur über deine eigene iCloud für den Abgleich zwischen deinen Geräte geteilt.").frame(maxWidth: .infinity,alignment: .leading).padding(.bottom)
            Text("Über die 'Import / Export' Funktion kannst du deine Kartendaten auch mit anderen Familienmitgliedern, die einen eigenen iCloud Accout besitzen, austauschen. Beim Import können entweder alle vorhandenen Daten ersetzt werden oder es werden nur die Kundenkarten neu importiert, die noch nicht vorhanden sind bzw bei vorhandenen Karten nur die GPS Position, die bisher nicht gespeichert waren.").frame(maxWidth: .infinity,alignment: .leading).padding(.bottom)
            Text("Durch den 'Auto Check In' kann die erste Karte für die aktuelle GPS Position automatisch geöffnet werden. Dies funktioniert aktuell nur, wenn die App komplett neu gestartet wurde.").frame(maxWidth: .infinity,alignment: .leading).padding(.bottom)
            Text("Die App unterstützt Barcodes nach den Standards QR-Code, EAN-8, EAN-13, Code 93, Code 128, Aztec, PDF417, ITF-14 und ITF.").frame(maxWidth: .infinity,alignment: .leading)
            Text("Verwendete Grafiken").font(.headline).padding()
            Text("**Barcode Icon** Das Barcodebild oben im App Icons stammt von freepik [Designed by freepik](https://www.freepik.com)").frame(maxWidth: .infinity,alignment: .leading)
            Text("Verwendete externe Bibliotheken").font(.headline).padding()
            Text("**CodeScanner** Swift Paket von Paul Hudson zum Scannen von Barcodes [Link](https://github.com/twostraws/CodeScanner)").frame(maxWidth: .infinity,alignment: .leading)
            Text("**jsBarcode** JavaScript Bibliothek von John Lindell für die Anzeige von EAN-13, EAN-8, ITF-14, ITF und Code 39 Barcodes [Link](https://lindell.me/JsBarcode/)").frame(maxWidth: .infinity, alignment: .leading)
        }.padding()
    }
}

#Preview {
    AppInfoView()
}

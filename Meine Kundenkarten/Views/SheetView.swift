//
//  SheetView.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 02.01.24.
//

import SwiftUI

struct SheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var model: Model
    
    var body: some View {
        VStack {
            Text("Export / Import")
                .padding(5)
            TextEditor(text: $model.encodedData)
                .padding(5).border(Color.gray.opacity(0.5), width: 1) // Hier wird die hellere graue Farbe hinzugefügt
                .cornerRadius(10) // Hier werden die Ecken abgerundet
            //  Text("Der Text wurde automatisch in die Zwischenablage kopiert").font(.footnote)
            ShareLink(item: self.model.encodedData, preview: SharePreview("App Daten teilen")) {
                Image(systemName: "square.and.arrow.up")
                Text("Inhalt teilen")
            }.buttonStyle(.borderedProminent).padding(.top)
            Menu {
                Button("Import (vorher löschen)") {
                    self.model.importDataObjects()
                    dismiss()
                }
                /*
                Button("Import (überschreiben) und speichern") {
                    self.model.importDataObjects()
                    self.model.encodeData()
                    dismiss()
                }
                 */
                Button("Import (Neue hinzufügen, Gleiche überschreiben)") {
                    self.model.importDataObjectsComparing(overrideExisting: true)
                    dismiss()
                }
                Button("Import (nur Neue hinzufügen)") {
                    self.model.importDataObjectsComparing()
                    dismiss()
                }
                /*
                Button("Import (nur Neue hinzufügen) und speichern") {
                    self.model.importDataObjectsComparing()
                    self.model.encodeData()
                    dismiss()
                }
                 */
                Button("Feld löschen für Import") {
                    self.model.encodedData = ""
                    self.model.encodedHiddenData = ""
                }
                Button("Text kopieren") {
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = self.model.encodedData
                }
            } label: {
                Label("Import", systemImage: "ellipsis.circle")
            }.buttonStyle(.borderedProminent)
            Button("Schließen") {
                dismiss()
            }.buttonStyle(.borderedProminent)
        }.padding(5)
    }
}


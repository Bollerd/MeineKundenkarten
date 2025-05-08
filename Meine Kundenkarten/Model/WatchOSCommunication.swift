//
//  WatchOSCommunication.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 26.12.2024.
//

import WatchConnectivity
import SwiftUI

class iPhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var model: SharedModel?
    var phoneModel: Model?
    
    init(model: SharedModel) {
        super.init()
        self.model = model
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate methods
    
    // Wird aufgerufen, wenn sich der Status der Sitzung ändert (z. B. Verbindung hergestellt oder verloren)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            let msg = "WCSession konnte nicht aktiviert werden: \(error.localizedDescription)"
            print(msg)
            self.model?.messageFromPhone = msg
        } else {
            var msg = "WCSession erfolgreich aktiviert mit Status: \(activationState.rawValue)"
            print(msg)
            self.model?.messageFromPhone = msg
        }
    }
    
    // Nur für iOS notwendig: Wird aufgerufen, wenn die Watch-App installiert oder deinstalliert wird
    func sessionDidBecomeInactive(_ session: WCSession) {
        let msg = "WCSession wurde inaktiv."
        print(msg)
        self.model?.messageFromPhone = msg
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        var msg = "WCSession wurde deaktiviert."
        print(msg)
        self.model?.messageFromPhone = msg
        // Wichtig: Sobald deaktiviert, muss eine neue Sitzung aktiviert werden
        WCSession.default.activate()
    }
    
    // Empfangene Nachricht von der Watch verarbeiten
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let receivedData = message["key"] as? String {
                print("Daten von der Watch empfangen: \(receivedData)")
                // Verarbeite die empfangenen Daten hier
                self.model?.messageFromPhone = receivedData
                self.sendDataToWatch(data: "Pong \(Date())")
                
                
                self.phoneModel?.getCurrentLocation()
                self.phoneModel?.selectItemForAutoCheckin()
                if let item = self.phoneModel?.selectedItem {
                    if item.barcodeValue != "" {
                        let jsBarcodeType = item.getJSBarcodeType()
                        
                        if jsBarcodeType != "" {
                            self.transferImageToWatch(image: item.generateJSBarcodeUIImage())
                        } else {
                            self.transferImageToWatch(image: UIImage(data: item.generateBarcode()!)!)
                        }
                    } else {
                        self.transferImageToWatch(image: UIImage(named: "1.lane") ?? UIImage())
                    }
                } else {
                    self.transferImageToWatch(image: UIImage(named: "2.brakesignal") ?? UIImage())
                }
            
                
              //  self.transferImageToWatch()
            }
        }
    }
    
    // Daten an die Watch senden
    func sendDataToWatch(data: String) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["key": data], replyHandler: nil, errorHandler: { error in
                var msg = "Fehler beim Senden der Daten an die Watch: \(error.localizedDescription)"
                print(msg)
                self.model?.messageFromPhone = msg
            })
        }
    }
    
    func syncAppDataToWatch(appData: String) {
        // Speichere das Bild als Datei (z. B. PNG)
        guard let data = appData.data(using: .utf8 ) else {
            print("Fehler: String konnte nicht konvertiert werden")
            return
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("watch_appdata.json")
        
        do {
            try data.write(to: fileURL)
            // Datei übertragen
            WCSession.default.transferFile(fileURL, metadata: ["description": "App Json für Watch"])
        } catch {
            print("Fehler beim Speichern der Datendatei: \(error.localizedDescription)")
        }
    }
    
    func transferImageToWatch(image: UIImage) {
        // Skalieren des Bildes auf maximale Breite von 300 px
        let scaledImage = scaleImageToWidth(image: image, maxWidth: WATCH_IMAGE_SIZE)
            
        // Speichere das Bild als Datei (z. B. PNG)
        guard let imageData = scaledImage.pngData() else {
            print("Fehler: Bild konnte nicht konvertiert werden")
            return
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("watch_image.png")
        
        do {
            try imageData.write(to: fileURL)
            // Datei übertragen
            WCSession.default.transferFile(fileURL, metadata: ["description": "Bild für Watch"])
        } catch {
            print("Fehler beim Speichern der Bilddatei: \(error.localizedDescription)")
        }
    }
    
    // Funktion zum Skalieren eines Bildes auf eine maximale Breite
    func scaleImageToWidth(image: UIImage, maxWidth: CGFloat) -> UIImage {
        let size = image.size
        
        // Skalieren nur, wenn das Bild breiter als maxWidth ist
        if size.width > maxWidth {
            let scale = maxWidth / size.width
            let newSize = CGSize(width: maxWidth, height: size.height * scale)
            
            // Neues Bild rendern
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return scaledImage ?? image
        }
        
        // Bild unverändert zurückgeben, wenn es kleiner als maxWidth ist
        return image
    }
}

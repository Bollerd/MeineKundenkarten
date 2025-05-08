//
//  iOSCommunication.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 26.12.2024.
//

import WatchConnectivity
import SwiftUI
class WatchReceiveModel: ObservableObject {
    @Published var message: String = ""
    @Published var initMessage: String = ""
    @Published var barcode = Image(systemName: "0.circle")
    @Published var cards: [DataObject] = []
}

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    var watchReceiveModel: WatchReceiveModel?
    
    override init() {
        print("this is init of WatchConnectivityManager")
        super.init()
        if WCSession.isSupported() {
            print("WCSession is supported")
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func setWatchReceiveModel(_ model: WatchReceiveModel) {
        self.watchReceiveModel = model
        self.watchReceiveModel?.initMessage = "S"
        if let savedData = readDataFromFile(fileName: "appData.json") {
            do {
                self.watchReceiveModel?.message += "F"
                let encodedData = try JSONDecoder().decode(DataObjects.self, from: savedData)
                self.watchReceiveModel?.cards = encodedData
                self.watchReceiveModel?.message = "\(self.watchReceiveModel?.message) - \(self.watchReceiveModel?.cards.count) cards"
                self.watchReceiveModel?.initMessage += "C\(self.watchReceiveModel?.cards.count)"
            } catch {
                print("Error decoding JSON into object")
                print(error)
                self.watchReceiveModel?.initMessage += "E1"
            }
        } else {
            self.watchReceiveModel?.initMessage += "N"
            if SIMULATE_DATA == true {
                var data = DataObjects()
                //let img = UIImage(named: "2.circle") ?? UIImage()
               // let imgData = img.pngData()
                let base64String = ""
                //imgData!.base64EncodedString()
                data.append(DataObject(description: "Test", barcodeType: "any", barcodeValue: "12", cardColor: Color.green, fontColor: Color.pink, base64String: base64String))
                data.append(DataObject(description: "Test2", barcodeType: "any", barcodeValue: "12", cardColor: Color.yellow, fontColor: Color.brown, base64String: base64String))
                self.watchReceiveModel?.cards = data
            }
        }
    }

    
    // MARK: - WCSessionDelegate methods

    // Wird aufgerufen, wenn die Sitzung aktiviert wird
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        var msg = ""
        if let error = error {
            msg = "WCSession konnte nicht aktiviert werden: \(error.localizedDescription)"
        } else {
            msg = "WCSession erfolgreich aktiviert mit Status: \(activationState.rawValue)"
        }
        
        print(msg)
        DispatchQueue.main.async {
            self.watchReceiveModel?.message = msg
        }
        
    }

    // Empfangene Nachricht vom iPhone verarbeiten
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        var msg = "this is session function"
        print(msg)
        DispatchQueue.main.async {
            if let receivedData = message["key"] as? String {
                var msg2 = "Daten vom iPhone empfangen: \(receivedData)"
                print(msg2)
                // Verarbeite die empfangenen Daten hier
                self.watchReceiveModel?.message = msg2
                msg += "\n" + msg2
            } else {
                msg += "\nkeine Daten empfangen"
                self.watchReceiveModel?.message = msg
            }
        }
        DispatchQueue.main.async {
            self.watchReceiveModel?.message = msg
        }
    }

    private func writeDataToFile(data: Data, fileName: String) {
        // Hole das temporäre Verzeichnis
        let tempDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            // Schreibe die Daten in die Datei
            try data.write(to: fileURL)
            print("Datei erfolgreich geschrieben: \(fileURL.path)")
        } catch {
            // Fehlerbehandlung
            print("Fehler beim Schreiben der Datei: \(error.localizedDescription)")
        }
    }
    
    private func readDataFromFile(fileName: String) -> Data? {
        // Pfad zur Datei bestimmen
        let tempDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            // Dateiinhalt lesen
            let data = try Data(contentsOf: fileURL)
            print("Datei erfolgreich gelesen: \(fileURL.path)")
            return data
        } catch {
            // Fehlerbehandlung
            print("Fehler beim Lesen der Datei: \(error.localizedDescription)")
            return nil
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("Datei erhalten: \(file.fileURL)")
        let fileURL = file.fileURL
        let metadata = file.metadata
        
        // Hier wird nach "description" gesucht und geprüft
            if let description = metadata?["description"] as? String, description == "Bild für Watch" {
                print("Die empfangene Datei ist ein Bild.")
                // Hier kannst du die Datei weiterverarbeiten
                
                // Lade das Bild
                if let imageData = try? Data(contentsOf: file.fileURL),
                   let image = UIImage(data: imageData) {
                    // Nutze das Bild, z. B. um es in einem Interface zu zeigen
                    DispatchQueue.main.async {
                        // Beispiel: Setze das Bild in ein Interface-Element
                        self.watchReceiveModel?.barcode = Image(uiImage: image)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.watchReceiveModel?.barcode = Image(systemName: "1.brakesignal")
                    }
                }
            } else {
                if let description = metadata?["description"] as? String, description == "App Json für Watch" {
                    self.watchReceiveModel?.initMessage += "R"
                    // Lade die AppDaten
                    if let appData = try? Data(contentsOf: file.fileURL),
                       let appText = String(data: appData, encoding: .utf8) {
                        // Nutze das Bild, z. B. um es in einem Interface zu zeigen
                        self.writeDataToFile(data: appData, fileName: "appData.json")
                        DispatchQueue.main.async {
                            // Beispiel: Setze das Bild in ein Interface-Element
                            self.watchReceiveModel?.message = String(appText.lengthOfBytes(using: .utf8))
                            do {
                                let encodedData = try JSONDecoder().decode(DataObjects.self, from: appData)
                                DispatchQueue.main.async {
                                    self.watchReceiveModel?.cards = encodedData
                                    self.watchReceiveModel?.message = "\(self.watchReceiveModel?.message) - \(self.watchReceiveModel?.cards.count) cards"
                                    self.watchReceiveModel?.initMessage += "C\(self.watchReceiveModel?.cards.count)"
                                }
                            } catch {
                                print("Error decoding JSON into object")
                                print(error)
                                DispatchQueue.main.async {
                                    self.watchReceiveModel?.initMessage += "E3"
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.watchReceiveModel?.message = "failed appData import"
                            self.watchReceiveModel?.initMessage += "E2"
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.watchReceiveModel?.message = "received something unknown"
                    }
                }
               
            }
        
       
    }
    
    // Daten an das iPhone senden
    func sendDataToiPhone(data: String) {
        var msg = "this is sendDataToiPhone function"
        print(msg)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["key": data], replyHandler: nil, errorHandler: { error in
                var msg2 = "Fehler beim Senden der Daten an das iPhone: \(error.localizedDescription)"
                print(msg2)
                msg = msg + "\n" + msg2
                DispatchQueue.main.async {
                    self.watchReceiveModel?.message = msg
                }
            })
        } else {
            var msg2 = "not reachable"
            print(msg2)
            msg = msg + "\n" + msg2
            DispatchQueue.main.async {
                self.watchReceiveModel?.message = msg
            }
        }
    }
}

    /*
     if WCSession.default.isReachable {
         print("Die Gegenstelle ist erreichbar.")
     } else {
         print("Die Gegenstelle ist derzeit nicht erreichbar.")
     }

     */

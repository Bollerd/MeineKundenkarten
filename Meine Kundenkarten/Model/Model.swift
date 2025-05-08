//
//  Model.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 02.01.24.
//

import SwiftUI
import LocalAuthentication
import SwiftHelperExtensions
import SwiftHelperUIKitExtensions

let DEBUG = false
let DEBUG_PLACEMARK = false
var ENABLE_LAUNCH_SCREEN = false
let VERSION = "1.1.2"
let BUILD = "32"
let ICLOUD_CONTAINER_NAME = "iCloud.de.bollernet.meinekundenkarten"
let ICLOUD_FILE_NAME = "kundenkarten.json"
let COMPANY_COLOR_NONE = "Keine Auswahl"
let WATCH_IMAGE_SIZE: CGFloat = 140.0

class ICloudFileHandler: iCloudFileHelperModel {
    var model: Model?
    var fileName: String
    var fileContent: String {
        didSet {
            if let decodedData: [DataObject] = she.convertJSONStringToObject(jsonString: fileContent) {
                if let appModel = self.model {
                    appModel.dataObjects = decodedData
                    
                    var jsBarcodes: [Base64Barcodes] = []
                    for object in appModel.dataObjects {
                        if object.getJSBarcodeType() != "" {
                            jsBarcodes.append(Base64Barcodes(type: object.getJSBarcodeType(), value: object.barcodeValue, base64: ""))
                        }
                        
                        for usedLocation in object.usedAtLocations {
                            usedLocation.setName(name: object.description)
                            
                            if usedLocation.placemark == "unknown" {
                                usedLocation.updatePlacemark()
                            }
                        }
                    }
                    
                    if jsBarcodes.count == 0 {
                        jsBarcodes.append(Base64Barcodes(type: "EAN13", value: "1234567890128", base64: ""))
                    }
                    
                    Background.shared.setup(barcodes: jsBarcodes, model: appModel)
                }
            } else {
                var jsBarcodes: [Base64Barcodes] = []
                jsBarcodes.append(Base64Barcodes(type: "EAN13", value: "1234567890128", base64: ""))
               
                if let appModel = self.model {
                    Background.shared.setup(barcodes: jsBarcodes, model: appModel)
                }
            }
        }
    }
    
    init(fileName: String) {
        self.fileName = fileName
        self.fileContent = ""
    }
    
    func setModel(model: Model) {
        self.model = model
    }
}

class SharedModel: ObservableObject {
    @Published var messageFromPhone = "Initialized"
    //let model = Model()
}

class Model: ObservableObject {
    @Published var dataObjects = [DataObject]()
    @Published var encodedData = ""
    @Published var encodedHiddenData = ""
    @Published var redrawView = false
    @Published var searchText = ""
    @Published var base64String = ""
    @AppStorage("autoCheckIn") var autoCheckIn = true
    @AppStorage("showMaps") var showMaps = false
    @AppStorage("protectApp") var protectApp = false
    @AppStorage("storageModelVersion") var storageModelVersion = "v1"
    @Published var selectedItem: DataObject?
    @Published var updateUi = false
    @Published var isUnlocked = false
    @Published var unlockError = ""
    @Published var messageFromPhone = ""
    @Published var importFromFile = false
    @Published var fileContent = ICloudFileHandler(fileName: ICLOUD_FILE_NAME)
    @Published var companyColors: [CompanyColor] = [CompanyColor(background: Color.blue, fontcolor: Color.white, company: COMPANY_COLOR_NONE)]
    @Published var watchModel = SharedModel()
    
    private var companyColorsUnsorted: [CompanyColor] = [
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "cc2d1b")), fontcolor: Color.white, company: "Mediamarkt"),
        CompanyColor(background: Color.black, fontcolor: Color.white, company: "Saturn"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "d5443b")), fontcolor: Color.white, company: "Görtz"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "f5da4c")), fontcolor: Color(uiColor: UIColor.hexStringToUIColor(hex: "2457a5")), company: "IKEA"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "bb2929")), fontcolor: Color.white, company: "REWE"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "173da9")), fontcolor: Color.white, company: "Payback"),
        CompanyColor(background: Color.white, fontcolor: Color(uiColor: UIColor.hexStringToUIColor(hex: "b32533")), company: "Rossmannn"),
        CompanyColor(background: Color.white, fontcolor: Color(uiColor: UIColor.hexStringToUIColor(hex: "bb2a20")), company: "Toom"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "fcf150")), fontcolor: Color(uiColor: UIColor.hexStringToUIColor(hex: "204fa4")), company: "Lidl"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "5cbb3a")), fontcolor: Color.white, company: "Wasgau"),
        CompanyColor(background: Color.white, fontcolor: Color(uiColor: UIColor.hexStringToUIColor(hex: "243580")), company: "DM Drogerie"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "f6ce46")), fontcolor: Color(uiColor: UIColor.hexStringToUIColor(hex: "c22a23")), company: "DHL"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "f4d047")), fontcolor: Color(uiColor: UIColor.hexStringToUIColor(hex: "cb352e")), company: "Shell"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "367bb7")), fontcolor: Color.white, company: "Decathlon"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "f7ce46")), fontcolor: Color.black, company: "ADAC"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "21397a")), fontcolor: Color(uiColor: UIColor.hexStringToUIColor(hex: "f4e34c")), company: "Edeka"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "50276b")), fontcolor: Color(uiColor: UIColor.hexStringToUIColor(hex: "eaba3f")), company: "Deutschland Card"),
        CompanyColor(background: Color.white, fontcolor: Color(uiColor: UIColor.hexStringToUIColor(hex: "e06d3a")), company: "Müller Drogerie"),
        CompanyColor(background: Color(uiColor: UIColor.hexStringToUIColor(hex: "cbe9e4")), fontcolor: Color.black, company: "Douglas")]
    var listText: String {
        get {
            return "Karten"
        }
    }
    var showDataExport = true
    var i = 2
    var searchResults: [DataObject] {
        get {
            if searchText.isEmpty {
                return self.dataObjects
            } else {
                return self.dataObjects.filter { $0.description.uppercased().contains(searchText.uppercased()) }
            }
        }
        set { }
    }
    var counter: String {
        get {
            var t = 0
            t = dataObjects.count
            return "\(t)"
        }
        set { }
    }
    var dataChanged = false
    private var locationFetcher = LocationFetcher()
    private var locationRetries = 0
    var appleWatch: iPhoneConnectivityManager
    
    init() {
        let watchInitModel = SharedModel()
        self.appleWatch = iPhoneConnectivityManager(model: watchInitModel)
        self.watchModel = watchInitModel
        self.companyColors = self.companyColorsUnsorted.sorted { $0.company < $1.company }
        self.companyColors.insert(contentsOf: [CompanyColor(background: Color.blue, fontcolor: Color.white, company: COMPANY_COLOR_NONE)], at: 0)
        self.readiCloudFileData()
        locationFetcher.start()
        if self.protectApp == true {
            self.authenticateWithFaceID()
        }
        self.selectItemForAutoCheckin()
        self.setWatchCommunication()
    }
    
    func setWatchCommunication() {
        self.appleWatch = iPhoneConnectivityManager(model: self.watchModel)
        self.appleWatch.phoneModel = self
    }
    
    func selectItemForAutoCheckin() {
        if self.autoCheckIn == true {
            let location = self.getCurrentLocation()
            
            if location.latitude == 0.0 && location.longitude == 0.0 {
                if DEBUG {
                    print("no location determined")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.setSelectedItem()
                }
            } else {
                for item in dataObjects {
                    let isMarkedPosition = item.checkForMarkedPosition(location: location)
                    
                    if isMarkedPosition == true && self.autoCheckIn == true {
                        if selectedItem == nil {
                            selectedItem = item
                        }
                    }
                }
            }
        }
    }
    
    func readiCloudFileData() {
        self.fileContent.fileContent = ""
        self.fileContent.setModel(model: self)
        if self.storageModelVersion == "v1" {
            she.readCloudFile(containerId: ICLOUD_CONTAINER_NAME, fileName: self.fileContent.fileName, fileModel: self.fileContent)
            self.storageModelVersion = "v2"
            self.encodeData()
        } else {
            she.readCloudFile(containerId: ICLOUD_CONTAINER_NAME, fileName: self.fileContent.fileName, fileModel: self.fileContent, unzip: true)
            
            if self.fileContent.fileContent == "" {
                let filename = getDocumentsDirectory().appendingPathComponent(ICLOUD_FILE_NAME)

                do {
                    let filedata = try String(contentsOf: filename)
                //    if let decodedData: [DataObject] = she.convertJSONStringToObject(jsonString: filedata) {
                        self.fileContent.fileContent = filedata
                 //   }
                } catch {
                    // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                }
            }
        }
        
    }
    
    func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to unlock the app"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    } else {
                        // Handle authentication failure
                        self.unlockError = String(authenticationError?.localizedDescription ?? "unbekannter Fehler")
                    }
                }
            }
        } else {
            // Face ID not available, use fallback or show error message
        }
    }
    
    func setSelectedItem() {
        if DEBUG {
            print("try to solve no location determined in setselecteditem")
        }
        self.locationRetries += 1
        if selectedItem == nil {
            let location = self.getCurrentLocation()
            
            if location.latitude == 0.0 && location.longitude == 0.0 {
                if DEBUG {
                    print("still no location determined")
                }
                if self.locationRetries < 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.setSelectedItem()
                    }
                }
                return
            }
            
            for item in dataObjects {
                if selectedItem == nil {
                    let isMarkedPosition = item.checkForMarkedPosition(location: location)
                    if DEBUG {
                        print("no location check for: \(item.description) \(isMarkedPosition) at \(location.longitude) / \(location.latitude): \(item.usedAtLocations)")
                    }
                    
                    if isMarkedPosition == true && self.autoCheckIn == true {
                        if DEBUG {
                            print("no location check: set item to \(item.description)")
                        }
                        selectedItem = item
                    }
                }
            }
        } else {
            if DEBUG {
                print("already found selected item")
            }
        }
    }
    
    func addNewObject() {
        self.dataChanged = true
        self.dataObjects.insert(DataObject.getNewObject(), at: 0)
    }
    
    func getCurrentLocation(name: String = "No info") -> ShowedAtLocation {
        if let lastLocation = locationFetcher.lastKnownLocation {
            if DEBUG {
                print("getcurrentlocation found \(lastLocation.coordinate.longitude) / \(lastLocation.coordinate.latitude) for \(name)")
            }
            return ShowedAtLocation(latitude: lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude, name: name)
        } else {
            return ShowedAtLocation(latitude: 0.0, longitude: 0.0, name: name)
        }
    }
  
    func setEncodedData(singleItem: DataObject = DataObject(description: "", barcodeType: "", barcodeValue: "", cardColor: .black, fontColor: .black)) {
        do {
            // we create here new local objects to avoid saving the very long base64 image string and to avoid to save all the placemark info data
            var localDataObjects = [DataObject]()
            
            if singleItem.description != "" && singleItem.barcodeType != "" && singleItem.barcodeValue != "" {
                var cleanedItem = DataObject(description: singleItem.description, info: singleItem.info ?? "", barcodeType: singleItem.barcodeType, barcodeValue: singleItem.barcodeValue, cardColor: singleItem.cardColor.toSwiftUIColor(), fontColor: singleItem.fontColor.toSwiftUIColor())
                
                for location in singleItem.usedAtLocations {
                    var cleanedLocation = ShowedAtLocation(latitude: location.latitude, longitude: location.longitude, name: "")
                    
                    cleanedItem.usedAtLocations.append(cleanedLocation)
                }
                
                localDataObjects.append(cleanedItem)
            } else {
                for item in self.dataObjects {
                    var cleanedItem = DataObject(description: item.description, info: item.info ?? "", barcodeType: item.barcodeType, barcodeValue: item.barcodeValue, cardColor: item.cardColor.toSwiftUIColor(), fontColor: item.fontColor.toSwiftUIColor())
                    
                    for location in item.usedAtLocations {
                        var cleanedLocation = ShowedAtLocation(latitude: location.latitude, longitude: location.longitude, name: "")
                        
                        cleanedItem.usedAtLocations.append(cleanedLocation)
                    }
                    
                    localDataObjects.append(cleanedItem)
                }
            }
            
            
            self.encodedData = String(decoding: try JSONEncoder().encode(localDataObjects), as: UTF8.self)
        } catch {
            self.encodedData = "Encoding error"
        }
    }
    
    func setEncodedDataFull(singleItem: DataObject = DataObject(description: "", barcodeType: "", barcodeValue: "", cardColor: .black, fontColor: .black)) {
        do {
            // we create here new local objects to avoid saving the very long base64 image string and to avoid to save all the placemark info data
            var localDataObjects = [DataObject]()
            
            if singleItem.description != "" && singleItem.barcodeType != "" && singleItem.barcodeValue != "" {
                var cleanedItem = DataObject(description: singleItem.description, info: singleItem.info ?? "", barcodeType: singleItem.barcodeType, barcodeValue: singleItem.barcodeValue, cardColor: singleItem.cardColor.toSwiftUIColor(), fontColor: singleItem.fontColor.toSwiftUIColor())
                
                for location in singleItem.usedAtLocations {
                    var cleanedLocation = ShowedAtLocation(latitude: location.latitude, longitude: location.longitude, name: "")
                    
                    cleanedItem.usedAtLocations.append(cleanedLocation)
                }
                
                localDataObjects.append(singleItem)
            } else {
                for item in self.dataObjects {
                    var cleanedItem = DataObject(description: item.description, info: item.info ?? "", barcodeType: item.barcodeType, barcodeValue: item.barcodeValue, cardColor: item.cardColor.toSwiftUIColor(), fontColor: item.fontColor.toSwiftUIColor())
                    
                    
                    cleanedItem.setBase64String(imageString: item.getBase64String())
                    
                    for location in item.usedAtLocations {
                        var cleanedLocation = ShowedAtLocation(latitude: location.latitude, longitude: location.longitude, name: "")
                        
                        cleanedItem.usedAtLocations.append(cleanedLocation)
                    }
                    
                    localDataObjects.append(cleanedItem)
                }
            }
            
            self.encodedData = String(decoding: try JSONEncoder().encode(localDataObjects), as: UTF8.self)
        } catch {
            self.encodedData = "Encoding error"
        }
    }
    
    func importDataObjects() {
        do {
            if let encoded = self.encodedData.data(using: .utf8) {
                self.dataObjects = try JSONDecoder().decode([DataObject].self, from: encoded)
                
                var jsBarcodes: [Base64Barcodes] = []
                
                for item in self.dataObjects {
                    if item.getJSBarcodeType() != "" {
                        jsBarcodes.append(Base64Barcodes(type: item.getJSBarcodeType(), value: item.barcodeValue, base64: ""))
                    }
                    
                    for usedLocation in item.usedAtLocations {
                        usedLocation.updatePlacemark()
                    }
                }
                
                if jsBarcodes.count == 0 {
                    jsBarcodes.append(Base64Barcodes(type: "EAN13", value: "1234567890128", base64: ""))
                }
                
                Background.shared.update(barcodes: jsBarcodes)
                
                if DEBUG {
                    print("Restoring objects array back from file: \(self.dataObjects.count)")
                }
            }
        } catch {
            print("Error decoding dataObjects from import")
            print(error.localizedDescription)
        }
    }
    
    func importDataObjectsComparing(overrideExisting: Bool = false) {
        do {
            if let encoded = self.encodedData.data(using: .utf8) {
                var localDataObjects = [DataObject]()
                
                localDataObjects = try JSONDecoder().decode([DataObject].self, from: encoded)
                
                var jsBarcodes: [Base64Barcodes] = []
                
                for item in localDataObjects {
                    // now check if this item is already existing
                    var isExisting = false
                    if var result = self.dataObjects.first(where: { $0.barcodeValue == item.barcodeValue && $0.barcodeType == item.barcodeType && $0.description == item.description }) {
                        // found the record
                        isExisting = true
                        
                        if overrideExisting == true {
                            result = item
                        } else {
                            for usedLocation in item.usedAtLocations {
                                // check if the current location is stored and if not, append it
                                if let resultLocation = result.usedAtLocations.first(where: { $0.latitude == usedLocation.latitude && $0.longitude == usedLocation.longitude }) {
                                    // existing location - we need nothing to do
                                } else {
                                    // not saved location
                                    usedLocation.updatePlacemark()
                                    result.usedAtLocations.append(usedLocation)
                                }
                            }
                        }
                    } else {
                        // new record
                        self.dataObjects.append(item)
                    }
                    
                    if isExisting == false {
                        if item.getJSBarcodeType() != "" {
                            jsBarcodes.append(Base64Barcodes(type: item.getJSBarcodeType(), value: item.barcodeValue, base64: ""))
                        }
                        
                        for usedLocation in item.usedAtLocations {
                            usedLocation.updatePlacemark()
                        }
                    }
                }
                
                if jsBarcodes.count == 0 {
                    jsBarcodes.append(Base64Barcodes(type: "EAN13", value: "1234567890128", base64: ""))
                }
                
                Background.shared.update(barcodes: jsBarcodes)
                
                if DEBUG {
                    print("Restoring objects array back from file: \(self.dataObjects.count)")
                }
            }
        } catch {
            print("Error decoding dataObjects from import")
            print(error.localizedDescription)
        }
    }
   
    func encodeData() {
        do {
            self.dataChanged = false
            self.fileContent.fileContent = ""
            let encoded = try JSONEncoder().encode(self.dataObjects)
            if self.storageModelVersion == "v1" {
                she.writeCloudFile(containerId: ICLOUD_CONTAINER_NAME, fileName: self.fileContent.fileName, fileContent: encoded)
            } else {
                she.writeCloudFile(containerId: ICLOUD_CONTAINER_NAME, fileName: self.fileContent.fileName, fileContent: encoded, zip: true)
                she.readCloudFile(containerId: ICLOUD_CONTAINER_NAME, fileName: self.fileContent.fileName, fileModel: self.fileContent, unzip: true)
                
                if self.fileContent.fileContent == "" {
                    let filename = getDocumentsDirectory().appendingPathComponent(ICLOUD_FILE_NAME)

                    do {
                        var str = String(decoding: encoded, as: UTF8.self)
                        try str.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
                    } catch {
                        // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                    }
                }
            }
            
        } catch {
            print("Error encoding objects to JSON")
            print(error)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

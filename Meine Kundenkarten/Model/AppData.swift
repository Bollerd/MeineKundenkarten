//
//  AppData.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 02.01.24.
//

import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreLocation
import WebKit
let context = CIContext()

struct CompanyColor: Identifiable, Hashable {
    let id = UUID()
    let background: Color
    let fontcolor: Color
    let company: String
    
    static func == (lhs: CompanyColor, rhs: CompanyColor) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class WebLoader {
    let webView: WKWebView
    let model: Model
    
    init(model: Model) {
        let webConfiguration = WKWebViewConfiguration()
        self.model = model
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        //    self.webView.navigationDelegate = self
    }
    
    func loadURL(url: URL) {
        let request = URLRequest(url: url)
        self.webView.load(request)
    }
}

struct MyColor: Codable, Equatable {
    let id = UUID()
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    static func == (lhs: MyColor, rhs: MyColor) -> Bool {
        return lhs.id == rhs.id // Hier id mit einem geeigneten Attribut ersetzen, das die Identität der Person repräsentiert
    }
    
    init(color: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }
    
    init(swiftUIColor: Color) {
        let uiColor = UIColor(swiftUIColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }
    
    func toUIColor() -> UIColor {
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    func toSwiftUIColor() -> Color {
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

struct AnnotationItem: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

class ShowedAtLocation: Codable, Identifiable, ObservableObject {
    var id: UUID? = UUID()
    var latitude: Double
    var longitude: Double
    var name: String? = "null"
    var placemark: String? = "initial" {
        willSet { newValue
            if DEBUG && DEBUG_PLACEMARK {
                print("placemark \(longitude) / \(latitude) will set to \(String(describing: newValue))")
            }
        }
    }
    var annotations: [AnnotationItem]? {
        get {
            return [AnnotationItem(name: self.name ?? "No Name", coordinate: CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude))]
        }
    }
    
    init(latitude: Double, longitude: Double, name: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        updatePlacemark()
    }
    
    func updatePlacemark() {
        if DEBUG && DEBUG_PLACEMARK {
            print("updateplacemark is started for \(longitude) / \(latitude)")
        }
        self.placemark = "unknown"
        if self.latitude == 0.0 && self.longitude == 0.0 {
            self.placemark = "none"
        } else {
            getAddressFromCoordinates(latitude: self.latitude, longitude: self.longitude) { address in
                if let address = address {
                    if DEBUG {
                        print("The address of \(self.longitude) / \(self.latitude) is: \(address)")
                    }
                    self.placemark = address
                } else {
                    if DEBUG {
                        print("Failed to get the address.")
                    }
                }
            }
        }
    }
    
    func setName(name: String) {
        self.name = name
    }
    
    private func getAddressFromCoordinates(latitude: Double, longitude: Double, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding failed with error: \(error.localizedDescription)")
                completion(nil)
            } else if let placemark = placemarks?.first {
                let address = "\(placemark.name ?? "") \(placemark.thoroughfare ?? ""), \(placemark.locality ?? "")"
                completion(address)
            } else {
                completion(nil)
            }
        }
    }
}

class DataObject: Codable, Identifiable, Hashable, ObservableObject {
    var id = UUID()
    var description: String
    var info: String?
    var cardColor: MyColor
    var fontColor: MyColor
    var lastViewed: Int
    var barcodeType: String
    var barcodeValue: String
    var usedAtLocations: [ShowedAtLocation]
    var ciBarcodeType: String {
        get {
            switch self.barcodeType {
            case AVMetadataObject.ObjectType.qr.rawValue:
                return "CIQRCodeGenerator"
            case AVMetadataObject.ObjectType.pdf417.rawValue:
                return "CIPDF417BarcodeGenerator"
            case AVMetadataObject.ObjectType.code128.rawValue:
                return "CICode128BarcodeGenerator"
                //  case AVMetadataObject.ObjectType.ean13.rawValue:
                //      return "CIAztecCodeGenerator"
            case AVMetadataObject.ObjectType.aztec.rawValue:
                return "CIAztecCodeGenerator"
            default:
                return ""
            }
        }
    }
    private var base64String: String? = ""
    
    static func == (lhs: DataObject, rhs: DataObject) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(description: String, info: String = "", barcodeType: String, barcodeValue: String, cardColor: Color, fontColor: Color) {
        self.description = description
        self.barcodeValue = barcodeValue
        self.barcodeType = barcodeType
        self.cardColor = MyColor(swiftUIColor: cardColor)
        self.fontColor = MyColor(swiftUIColor: fontColor)
        self.info = info
        self.lastViewed = 0
        self.usedAtLocations = []
    }
    
    static func getNewObject() -> DataObject {
        return DataObject(description: "",info: "", barcodeType:"", barcodeValue: "", cardColor: Color.red, fontColor: Color.black)
    }
    
    func checkForMarkedPosition(location: ShowedAtLocation) -> Bool {
        if location.latitude == 0.0 && location.longitude == 0.0 {
            return false
        }
        let abwLong = 0.000282
        let abwLat = 0.000899
        print("this is checkformarkedposition for \(location.longitude) / \(location.latitude) of card \(self.description)")
        for usedLocation in self.usedAtLocations {
            if self.description == "REWE" {
                print(usedLocation.longitude)
                print(usedLocation.latitude)
                if ( location.latitude - abwLat ) <= usedLocation.latitude  {
                    print("returning true 1")
                    
                }
                if  ( location.latitude + abwLat ) >= usedLocation.latitude  {
                    print("returning true 2")
                }
                if  ( location.longitude - abwLong) <= usedLocation.longitude  {
                    print("returning true 3")
                    
                }
                if  ( location.longitude + abwLong ) >= usedLocation.longitude {
                    print("returning true 4")
                    
                }
            }
            if ( location.latitude - abwLat ) <= usedLocation.latitude && ( location.latitude + abwLat ) >= usedLocation.latitude && ( location.longitude - abwLong) <= usedLocation.longitude && ( location.longitude + abwLong ) >= usedLocation.longitude {
                print("returning true")
                return true
            }
        }
        return false
    }
    
    func setDisplayed() {
        self.lastViewed = Int(Date().timeIntervalSince1970)
    }
    
    func setBase64String(imageString: String) {
        self.base64String = imageString
    }
    
    func getJSBarcodeType() -> String {
        var returnType = ""
        switch self.barcodeType {
        case "org.gs1.EAN-8":
            returnType = "EAN8"
        case "org.iso.Code39":
            returnType = "CODE39"
        case "org.gs1.EAN-13":
            returnType = "EAN13"
        case "org.gs1.ITF14":
            returnType = "itf14"
        case "org.ansi.Interleaved2of5":
            returnType = "itf"
        default:
            returnType = ""
        }
        return returnType
    }
    
    func getBarcodeWidth() -> CGFloat {
        var returnWidth = 200.0
        switch self.barcodeType {
        case "org.iso.Code128":
            returnWidth = 350.0
        default:
            returnWidth = 200.0
        }
        return returnWidth
    }
    
    func getBarcodeHeight() -> CGFloat {
        var returnHeigth = 200.0
        switch self.barcodeType {
        case "org.iso.Code128":
            returnHeigth = 150.0
        default:
            returnHeigth = 200.0
        }
        return returnHeigth
    }
    
    func generateBarcode() -> Data? {
        let data = self.barcodeValue.data(using: String.Encoding.ascii)
        let codeType = self.ciBarcodeType
        if let barcodeFilter = CIFilter(name: codeType) {
            barcodeFilter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 20, y: 20)
            
            if let output = barcodeFilter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output).pngData()!
            }
        }
        return UIImage(systemName: "xmark.circle")!.pngData() ?? UIImage().pngData()
    }
    
    func generateJSBarcode() -> AnyView {
        if let imageData = Data(base64Encoded: base64String ?? ""),
           let uiImage = UIImage(data: imageData) {
            return AnyView(
                Image(uiImage: uiImage)
                    .resizable().interpolation(.high).scaledToFit()
            )
        } else {
            return AnyView(
                Image(systemName: "barcode.viewfinder")
                .resizable().aspectRatio(contentMode: .fit)
            )
        }
    }
}

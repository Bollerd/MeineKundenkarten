//
//  Background.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 02.01.24.
//

import Foundation
import WebKit

struct Base64Barcodes {
    let type: String
    let value: String
    let base64: String
    var origType: String {
        get {
            var returnType = ""
            switch self.type {
            case "EAN8":
                returnType = "org.gs1.EAN-8"
            case "CODE39":
                returnType = "org.iso.Code39"
            case "EAN13":
                returnType = "org.gs1.EAN-13"
            case "itf14":
                returnType = "org.gs1.ITF14"
            case "itf":
                returnType = "org.ansi.Interleaved2of5"
            default:
                returnType = ""
            }
            return returnType
        }
    }
}

class Background : NSObject, WKScriptMessageHandler
{
    private var _webView: WKWebView?;
    public static let shared = Background();
    private var _bSetupInvoked = false;
    private var _aReceivedBase64: [Base64Barcodes] = []
    private var _aSetupBarcodes: [Base64Barcodes] = []
    private var _bReceivedFirstResponse = false
    private var _oModel: Model?
    override init() {
        super.init();
    }
    
    private func readFile(_ url: URL) -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        }
        catch {
            let message = "Could not load file at: \(url)"
            fatalError(message)
        }
    }
    
    public func setup (barcodes: [Base64Barcodes], model: Model)
    {
        if(self._bSetupInvoked == true) {
            self.update(barcodes: barcodes)
        }
     
        self._oModel = model
        self._aSetupBarcodes = barcodes
        
        let webConfiguration = WKWebViewConfiguration()
     
        let startScript = Bundle(for: Background.self).url(forResource: "bg_script", withExtension: "js")!
        let scripts = readFile(startScript)
        let script = WKUserScript(source: scripts, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
        
        let contentController: WKUserContentController = WKUserContentController()
        contentController.addUserScript(script)
       
        contentController.add(self, name: "backgroundListener")
        webConfiguration.userContentController = contentController
        
        self._webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self._webView!.customUserAgent = "my-Bridge"
        
        /// JSBarcode
        guard let jsURL = Bundle.main.url(forResource: "JsBarcode", withExtension: "js") else {
            return
        }
        
        var barcodeHTMLString = ""
        var barcodeData = ""
        var barcodeType = "EAN13"
        
        if let firstEntry = self._aSetupBarcodes.first {
            barcodeData = firstEntry.value
            barcodeType = firstEntry.type
        }
        
        do {
            let jsCode = try String(contentsOf: jsURL)
            let script = "var script = document.createElement('script'); script.type = 'text/javascript'; script.text = \(jsCode); document.head.appendChild(script);"
            let barcodeScript = "JsBarcode('#barcode', '\(barcodeData)', {format: '\(barcodeType)',displayValue: true,height:100});window.JsBarcode = JsBarcode;"
             barcodeHTMLString = "<html><head><script>\(script)</script></head><body><img id=\"barcode\"/><script>\(barcodeScript)</script></body></html>"
        } catch {
            print("Error loading JsBarcode.js: \(error)")
        }
        
        /// JSBarcode
        
        let html : String = barcodeHTMLString
        self._webView!.loadHTMLString(html, baseURL: nil)
        
        self._bSetupInvoked = true;
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        //Here we will recieve data from background js script
        
        let val1 = message.name;
        let val2 = message.body as! String;
        self._bReceivedFirstResponse = true
        
        if let range = val2.range(of: "src=\"data:image/png;base64,") {
            let barcodeStart = range.upperBound
            let barcode = val2[barcodeStart...]
            if let endRange = barcode.range(of: "\"") {
                let barcodeValue = barcode[..<endRange.lowerBound]
                if DEBUG {
                    print("base64 encoded JSBarcode Image")
                    print(barcodeValue)
                }
                
                var type = ""
                var value = ""
                var origType = ""
                if let firstEntry = self._aSetupBarcodes.first {
                    type = firstEntry.type
                    value = firstEntry.value
                    origType = firstEntry.origType
                }
                
                let base64Barcode = Base64Barcodes(type: type, value: value, base64: String(barcodeValue))
                self._aReceivedBase64.append(base64Barcode)
        
                if let model = self._oModel {
                    if let result = model.dataObjects.first(where: { $0.barcodeValue == value && $0.barcodeType == origType }) {
                        result.setBase64String(imageString: String(barcodeValue))
                    }
                }
                
                self._aSetupBarcodes.removeFirst()
                
                if self._aSetupBarcodes.count > 0 {
                    if let firstEntry = self._aSetupBarcodes.first {
                        self.update(barcodeData: firstEntry.value, barcodeType: firstEntry.type)
                    }
                }
            }
        } else {
            if DEBUG {
                NSLog("received data from WKWebView")
                NSLog(val1)
                NSLog(val2)
            }
        }
    }
    
    func update (barcodeData: String, barcodeType: String) {
        if self._bSetupInvoked == false {
            return
        }
        let myString = "{\"type\":\"\(barcodeType)\",\"data\":\"\(barcodeData)\"}"
        self.sendMessage(payload: myString)
    }
    
    public func update(barcodes: [Base64Barcodes]) {
        if self._bSetupInvoked == false {
            return
        }
       
        var startRequired = true
        
        if self._aSetupBarcodes.count > 1 {
            startRequired = false
        }
        
        for barcode in barcodes {
            self._aSetupBarcodes.append(barcode)
        }
        
        if startRequired {
            if self._aSetupBarcodes.count > 0 {
                if let firstEntry = self._aSetupBarcodes.first {
                    self.update(barcodeData: firstEntry.value, barcodeType: firstEntry.type)
                }
            }
        }
    }
    
    func sendMessage(payload : String)
    {
        self._webView?.evaluateJavaScript("handleMessage('\(payload)');", completionHandler: { result, error in
            if let val = result as? String {
                if DEBUG {
                    NSLog(val)
                }
            }
            else {
                if DEBUG {
                    NSLog("result is NIL")
                }
            }
        })
    }
}

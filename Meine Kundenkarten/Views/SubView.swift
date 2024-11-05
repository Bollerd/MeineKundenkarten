//
//  SubView.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 02.01.24.
//

import SwiftUI
import SwiftHelperExtensions
import CodeScanner
import MapKit

struct SubView: View {
    @Environment(\.keyboardShowing) var keyboardShowing
    @Environment(\.scenePhase) var scenePhase
    @Binding var item: DataObject
    @EnvironmentObject var model: Model
    @State var redrawView = false
    @State private var showingSheet = false
    @State var editMode = false
    @State var codeValue = "bitte warten...."
    @State var codeType = ""
    @State var updateUI = true
    @State var resfreshRate = 0.25
    @State var scanCode = false
    @State var searchTerm = ""
    @State private var selectedColor = Color.red
    @State private var selectedFontColor = Color.black
    @FocusState private var isFocused: Bool
    @State private var location: ShowedAtLocation = ShowedAtLocation(latitude: 0.0, longitude: 0.0, name: "")
    @State private var isMarkedLocation = false
    @State private var enableManualBarcode = false
    @State private var selectedColorCode = CompanyColor(background: Color.blue, fontcolor: Color.white, company: COMPANY_COLOR_NONE)
    private var safeAreaInset: CGFloat {
        get {
            if self.keyboardShowing == true {
                return 200.0
            }
            return 0.0
        }
    }
    @EnvironmentObject private var launchScreenState: LaunchScreenStateManager
    var filteredCompanyColors: [CompanyColor] {
        model.companyColors.filter {
            searchTerm.isEmpty ? true : $0.company.lowercased().contains(searchTerm.lowercased()) || $0.company.lowercased().contains("keine auswahl")
        }
    }
    
    var body: some View {
       VStack {
            HeadlineView()
            VStack {
                EditView()
                BarcodeDisplayView()
                VStack {
                    StoredLocationsView()
                }.sheet(isPresented: $scanCode, content: {
                    scannerSheet().frame(width: 300, height: 300, alignment: .center)
                }).presentationDetents([.medium])
            }
            .onChange(of: item.cardColor) { newValue in
                self.selectedColor = newValue.toSwiftUIColor()
                if DEBUG {
                    print("onChange der item.cardcolor \(newValue)")
                }
            }
            .onChange(of: item.fontColor) { newValue in
                self.selectedFontColor = newValue.toSwiftUIColor()
                if DEBUG {
                    print("onChange der item.fontcolor \(newValue)")
                }
            }
            .onChange(of: item.id) { newValue in
                if DEBUG {
                    print("setting position in changeof id \(newValue)")
                }
                self.location = model.getCurrentLocation()
                if let newItem = self.model.dataObjects.first(where: { $0.id == newValue }) {
                    self.isMarkedLocation = newItem.checkForMarkedPosition(location: self.location)
                } else {
                    self.isMarkedLocation = item.checkForMarkedPosition(location: self.location)
                }
                self.model.updateUi.toggle()
            }
            .onChange(of: item.description) { newValue in
                if newValue == "" {
                    self.editMode = true
                }
                self.model.updateUi.toggle()
            }
            .onAppear {
                self.selectedColor = self.item.cardColor.toSwiftUIColor()
                self.selectedFontColor = self.item.fontColor.toSwiftUIColor()
            }
        }
        .onAppear {
            if DEBUG {
                print("setting position in onappear")
            }
            if self.item.description == "" {
                self.editMode = true
            }
            if ENABLE_LAUNCH_SCREEN {
                ENABLE_LAUNCH_SCREEN = false
                self.launchScreenState.dismiss()
            }
            self.location = model.getCurrentLocation(name:item.description)
            self.isMarkedLocation = item.checkForMarkedPosition(location: self.location)
        }
        .safeAreaInset(edge: .top, alignment: .center, spacing: 0) {
            Color.clear
                .frame(height: self.safeAreaInset)
                .background(Material.bar)
        }
        .sheet(isPresented: $showingSheet) {
            SheetView()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            secondaryToolbarItems()
        }
    }
    
    /// -----------------
    ///  View Layouts
    /// -----------------
   
    /// Colored box at the top with card/shop name
    /// - Returns: the view for the info box at the view header
    func HeadlineView() -> AnyView {
        let nonOptionalInfoBinding = Binding(
            get: { self.item.info ?? "" },
            set: { self.item.info = $0 }
        )
        
        return AnyView(
            VStack {
                HStack {
                    if editMode == true {
                        Text("Firmenname").foregroundStyle(item.fontColor.toSwiftUIColor())
                        TextField("Firmenname", text: $item.description).focused($isFocused).textFieldStyle(.roundedBorder).onAppear {
                            isFocused = true
                        }
                    } else {
                        Text("\($item.description.wrappedValue)").font(.title).foregroundStyle(item.fontColor.toSwiftUIColor())
                    }
                }.padding(.horizontal)
                HStack {
                    if editMode == true {
                        Text("Beschreibung").foregroundStyle(item.fontColor.toSwiftUIColor())//.padding()
                        TextField("Beschreibung", text: nonOptionalInfoBinding).textFieldStyle(.roundedBorder)
                    } else {
                        Text($item.info.wrappedValue ?? "").foregroundStyle(item.fontColor.toSwiftUIColor())
                    }
                }.padding(.horizontal)
            }.padding(10).frame(maxWidth: .infinity).background(item.cardColor.toSwiftUIColor()).cornerRadius(10.0).padding(10)
        )
    }
    
    /// Part of the view in edit mode to select the colors
    /// - Returns: the view for the input fields for color selection
    func EditView() -> AnyView {
        return AnyView(
            VStack {
                if self.editMode == true {
                    HStack {
                        Text("Farbschema für")
                        Spacer()
                        Picker("Farbschema", selection: $selectedColorCode) {
                            ForEach(filteredCompanyColors, id: \.id) { companyColor in
                                Text(companyColor.company).tag(companyColor)
                            }
                        }.onChange(of: selectedColorCode) {
                            newvalue in
                            if newvalue.company != COMPANY_COLOR_NONE {
                                item.cardColor = MyColor.init(swiftUIColor: newvalue.background)
                                selectedColor = newvalue.background
                                item.fontColor = MyColor.init(swiftUIColor: newvalue.fontcolor)
                                selectedFontColor = newvalue.fontcolor
                            }
                        }.onAppear {
                            self.selectedColorCode = self.model.companyColors[0]
                        }
                    }.padding(.horizontal)
                    SearchBar(text: $searchTerm, placeholder: "Farbschema filtern")
                    HStack {
                        ColorPicker("Wähle eine Hintergrundfarbe", selection: $selectedColor)
                            .onChange(of: selectedColor) { newValue in
                                item.cardColor = MyColor.init(swiftUIColor: newValue)
                            }//.padding(.horizontal)
                    }.padding(.horizontal)
                }
                if self.editMode == true {
                    HStack {
                        ColorPicker("Wähle eine Schriftfarbe", selection: $selectedFontColor)
                            .onChange(of: selectedFontColor) { newValue in
                                item.fontColor = MyColor.init(swiftUIColor: newValue)
                            }//.padding(.horizontal)
                    }.padding(.horizontal)
                }
            }
        )
    }
    
    /// Part of the part of the view with the barcode data
    /// - Returns: a view
    func BarcodeDisplayView() -> AnyView {
        return AnyView(
            VStack {
                VStack {
                    if editMode == true && enableManualBarcode == true {
                        HStack {
                            Text("Barcode Type")
                            TextField("Barcode Type", text: $item.barcodeType).textFieldStyle(.roundedBorder)
                        }
                        HStack {
                            Text("Barcode Wert")
                            TextField("Barcode Wert", text: $item.barcodeValue).textFieldStyle(.roundedBorder)
                        }
                    } else {
                        Text("\($item.barcodeType.wrappedValue)").font(.caption2)
                    }
                }
                if item.barcodeValue != "" {
                    let jsBarcodeType = item.getJSBarcodeType()
                    
                    if jsBarcodeType != "" {
                        item.generateJSBarcode().frame(width: 400, height: 200)
                    } else {
                        Image(uiImage: UIImage(data: item.generateBarcode()!)!).resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: item.getBarcodeWidth(), height: item.getBarcodeHeight())
                    }
                }
                VStack {
                    Text("\($item.barcodeValue.wrappedValue)").font(.footnote)
                }
            }
        )
    }
    
    /// Part of the part of the view with the stored locations and button to save location
    /// - Returns: a view
    func StoredLocationsView() -> AnyView {
        return AnyView(
            VStack {
                List($item.usedAtLocations, id: \.id, editActions: .all) { usedLocation in
                    HStack {
                        Text(usedLocation.placemark.wrappedValue ?? "default")
                        Spacer()
                        Text(String(format: "%.4f /\n %.4f", usedLocation.longitude.wrappedValue, usedLocation.latitude.wrappedValue))
                            .font(.footnote).multilineTextAlignment(.trailing)
                    }
                    if #available(iOS 17.0, *) {
                        if self.model.showMaps {
                            mapView(usedLocation: usedLocation).frame(height: 150)
                        }
                    }
                }.listStyle(InsetGroupedListStyle())
                Spacer(minLength: 12)
                if self.isMarkedLocation == true {
                    Image(systemName: "mappin.and.ellipse.circle.fill", variableValue: 1.00)
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(Color.accentColor)
                        .font(.largeTitle)
                } else {
                    Button("Check In speichern") {
                        self.model.dataChanged = true
                        let location = model.getCurrentLocation(name: item.description)
                        item.usedAtLocations.append(location)
                        model.updateUi.toggle()
                        
                        Task {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                model.updateUi.toggle()
                            }
                        }
                    }.buttonStyle(.borderedProminent)
                }
            }
        )
    }
    
    @available(iOS 17.0, *)
    func mapView17(usedLocation: Binding<ShowedAtLocation>) -> AnyView {
        @State var annotations = [AnnotationItem(name: usedLocation.name.wrappedValue ?? "No Info" ,coordinate: CLLocationCoordinate2D(latitude:usedLocation.latitude.wrappedValue,longitude:usedLocation.longitude.wrappedValue))]
        @State var position: MapCameraPosition =
            .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: usedLocation.latitude.wrappedValue, longitude: usedLocation.longitude.wrappedValue), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
        
        return AnyView(
            Map(position: $position, interactionModes: .all) {
                ForEach(annotations, id: \.id) { place in
                    Marker(
                        place.name,
                        coordinate: place.coordinate
                    )
                }
            }.mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
        )
    }
    
    @available(iOS 17.0, *)
    func mapView(usedLocation: Binding<ShowedAtLocation>) -> AnyView {
        @State var annotations = [AnnotationItem(name: usedLocation.name.wrappedValue ?? "No Info" ,coordinate: CLLocationCoordinate2D(latitude:usedLocation.latitude.wrappedValue,longitude:usedLocation.longitude.wrappedValue))]
        
        return AnyView(
            Map(coordinateRegion: .constant(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: usedLocation.latitude.wrappedValue, longitude: usedLocation.longitude.wrappedValue),
                                                               span:  MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                                              )), annotationItems: annotations) { annotation in
                                                                  MapMarker(coordinate: annotation.coordinate)
                                                              }
        )
    }
    
    /// Display the scan interface for the camera
    /// - Returns: a view displayed as sheet
    func scannerSheet() -> AnyView {
        return AnyView(
            CodeScannerView(codeTypes: [.qr,.code128,.code39,.ean8,.ean13,.code39Mod43,.pdf417,.aztec,.itf14,.interleaved2of5],  scanMode: .continuous, manualSelect: true,scanInterval: resfreshRate * 4,simulatedData: "no data") { response in
                switch response {
                case .success(let result):
                    if DEBUG {
                        print("Found code: \(result.string)")
                        print("QR Type \(result.type.rawValue)")
                    }
                    codeType = result.type.rawValue
                    codeValue = result.string
                    item.barcodeType = result.type.rawValue
                    item.barcodeValue = result.string
                    // dismiss scanner UI
                    self.scanCode = false
                    if item.getJSBarcodeType() != "" {
                        Background.shared.update(barcodes: [Base64Barcodes(type: item.getJSBarcodeType() , value: codeValue, base64: "")])
                    }
                    updateUI.toggle()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        )
    }
    
    
    /// -----------------
    ///  Toolbar content
    /// -----------------
    
    /// Displays the secondary action buttons of the overview
    /// - Returns: some toolbar content
    private func secondaryToolbarItems() -> some ToolbarContent {
        return ToolbarItemGroup(placement: .secondaryAction) {
            if self.editMode == true {
                Button("Anzeigen") {
                    self.editMode.toggle()
                    self.model.updateUi.toggle()
                }
            } else {
                Button("Ändern") {
                    self.model.dataChanged = true
                    self.editMode.toggle()
                }
                // if app enters background at iPad after a detail was selected, the app crashes when the data is saved because the $model
                // is not set ... workaround to bypass crash on iPad OS
                if (self.scenePhase == .active) {
                    Toggle(isOn: $model.showMaps, label: {
                        Text("Karte anzeigen")
                    })
                }
            }
            Button("Scan") {
                self.scanCode.toggle()
            }
            if (self.scenePhase == .active) {
                if (model.showDataExport == true) {
                    Button("Export/Import") {
                        self.model.setEncodedData(singleItem: self.item)
                        self.showingSheet.toggle()
                        /*
                         let pasteboard = UIPasteboard.general
                         pasteboard.string = self.model.encodedData
                         */
                    }
                }
            }
        }
    }
}


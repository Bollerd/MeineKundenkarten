//
//  ContentView.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 21.12.23.
//

import SwiftUI
import TipKit

struct ContentView: View {
    @EnvironmentObject var model: Model
    @State private var showingSheet = false
    @State private var showingInfo = false
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject private var launchScreenState: LaunchScreenStateManager
    @State private var location: ShowedAtLocation = ShowedAtLocation(latitude: 0.0, longitude: 0.0, name: "")
    @State var importingFile = false
    var body: some View {
        VStack {
            if #available(iOS 17.0, *) {
                TipView(GetStartedTip())
                //         TipView(FavoriteTip())
            }
            NavigationSplitView {
                overview()
                    .onAppear {
                        if ENABLE_LAUNCH_SCREEN {
                            ENABLE_LAUNCH_SCREEN = false
                            self.launchScreenState.dismiss()
                        }
                        if model.autoCheckIn == true {
                            self.location = self.model.getCurrentLocation()
                           // self.model.selectItemForAutoCheckin()
                        }
                    }
                    .sheet(isPresented: $showingSheet) {
                        SheetView()
                    }
                    .sheet(isPresented: $showingInfo) {
                        AppInfoView().presentationDetents([.medium, .large])
                    }
                    .refreshable {
                        self.model.readiCloudFileData()
                    }
                    .navigationBarTitle(Text("\(self.model.listText) \(self.model.counter)"))
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        primaryToolbarItems()
                        secondaryToolbarItems()
                    }
            } detail: {
                // detail page
                if ( self.model.selectedItem != nil) {
                    /*
                    SubView(item: Binding(
                        get: { self.model.selectedItem ?? DataObject(description: "", barcodeType: "", barcodeValue: "", cardColor: .white, fontColor: .black) },
                        set: { self.model.selectedItem = $0 }
                    ))
                     */
                } else {
                    NavigationStack {
                        if self.model.dataObjects.count == 0  {
                            Text("Noch keine Daten gepflegt").font(.largeTitle)
                        } else {
                            Text("Kein Listeneintrag gewählt").font(.largeTitle)
                        }
                    }.navigationTitle("Keine Auswahl").navigationBarTitleDisplayMode(.inline)
                }
            }.onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    print("Active")
                    if model.autoCheckIn == true && !( model.isUnlocked == false && model.protectApp == true ) {
                        self.location = self.model.getCurrentLocation()
                        self.model.selectItemForAutoCheckin()
                    }
                } else if newPhase == .inactive {
                    print("Inactive")
                } else if newPhase == .background {
                    print("Background")
                    // if app enters background mode we perform an auto save
                    
                    if self.model.dataObjects.count > 0 && self.model.dataChanged == true {
                        print("Triggered auto save on background")
                        self.model.encodeData()
                    }
                    
                    // reset to open main view tp be able to navigate to current store
                    self.model.selectedItem = nil
                    
                    if self.model.protectApp == true {
                        self.model.isUnlocked = false
                    }
                } else {
                    print("Unknown Scene phase")
                }
            }.searchable(text: $model.searchText)
            Text("Made with ❤️ in SwiftUI by Dirk Boller v\(VERSION) (\(BUILD))").frame(height: 15).font(.footnote)
          //  Text("\(model.watchModel.messageFromPhone)").font(.footnote)
        }
    }
    
    /// -----------------
    ///  View Layouts
    /// -----------------
    
    /// renders the colum of an item in the overview list
    /// - Parameter item: item to display in overview list
    /// - Returns: a view
    func displayViewCore(item: Binding<DataObject>) -> AnyView {
        let isMarkedPosition = item.wrappedValue.checkForMarkedPosition(location: self.location)
        
        return AnyView(
            HStack {
                VStack {
                    HStack {
                        Text("\(item.description.wrappedValue)").font(.title2).foregroundStyle(item.fontColor.wrappedValue.toSwiftUIColor())
                        if isMarkedPosition == true {
                            Image(systemName: "mappin.and.ellipse.circle.fill", variableValue: 1.00)
                                .symbolRenderingMode(.monochrome)
                                .foregroundColor(item.fontColor.wrappedValue.toSwiftUIColor())
                                .font(.title)
                        }
                        Spacer()
                        Text(item.info.wrappedValue ?? "").font(.caption).foregroundStyle(item.fontColor.wrappedValue.toSwiftUIColor())
                    }.padding(5)
                    //    Text(item.lastViewed.wrappedValue.textValue)
                }
            }//.background(item.cardColor.wrappedValue.toSwiftUIColor()).opacity(0.1)
        )
    }
    
    /// Displays a message that the app could not be unlocked and shows button to re-unlock the app
    /// - Returns: a view
    func unlockView() -> AnyView {
        return AnyView(
            VStack {
                Text("\(model.unlockError)")
                Button("Biometrisch entsperren") {
                    model.authenticateWithFaceID()
                    
                    if model.isUnlocked == true {
                        self.location = self.model.getCurrentLocation()
                        self.model.selectItemForAutoCheckin()
                    }
                }.buttonStyle(.borderedProminent)
            }
        )
    }
    
    /// shows the list of saved cards - either all or filtered list
    /// - Returns: a view
    func overview() -> AnyView {
        if model.isUnlocked || model.protectApp == false {
            if model.searchText == "" {
                return AnyView(
                    List {
                        ForEach($model.dataObjects, id: \.id, editActions: .all) { item in
                            NavigationLink(tag: item.wrappedValue, selection: $model.selectedItem, destination: {
                                SubView(item: item)
                            }, label: {
                                displayViewCore(item: item)
                            }).listRowBackground(item.cardColor.wrappedValue.toSwiftUIColor())
                        }.onDelete { indexSet in
                            self.model.dataChanged = true
                            self.model.dataObjects.remove(atOffsets: indexSet)
                        }.onMove { fromIndexSet, toIndexSet in
                            self.model.dataChanged = true
                            self.model.dataObjects.move(fromOffsets: fromIndexSet, toOffset: toIndexSet)
                        }
                    }
                )
            } else {
                return AnyView(
                    List($model.searchResults, id: \.id, editActions: .move) { item in
                        NavigationLink(destination: {
                            SubView(item: item)
                        }, label: {
                            displayViewCore(item: item)
                        }).listRowBackground(item.cardColor.wrappedValue.toSwiftUIColor())
                    }
                )
            }
        } else {
            return  unlockView()
        }
    }
    
    /// -----------------
    ///  Toolbar content
    /// -----------------
    
    /// Displays the primary action buttons of the overview
    /// - Returns: some toolbar content
    private func primaryToolbarItems() -> some ToolbarContent {
        return ToolbarItemGroup(placement: .primaryAction) {
            if !( model.isUnlocked == false && model.protectApp == true ) {
                Button("Neu") {
                    self.model.addNewObject()
                }
                Button("Check In") {
                    self.location = self.model.getCurrentLocation()
                    self.model.selectItemForAutoCheckin()
                }
            }
        }
    }
    
    /// Displays the secondary action buttons of the overview
    /// - Returns: some toolbar content
    private func secondaryToolbarItems() -> some ToolbarContent {
        return ToolbarItemGroup(placement: .secondaryAction) {
            if (model.searchText == "") {
                if !( model.isUnlocked == false && model.protectApp == true ) {
                    Button("Speichern") {
                        self.model.encodeData()
                    }
                    Toggle(isOn: $model.autoCheckIn, label: {
                        Text("Auto Check In")
                    })
                }
                if !( model.isUnlocked == false && model.protectApp == true ) {
                    Toggle(isOn: $model.protectApp, label: {
                        Text("Biometrisch schützen")
                    })
                }
                if !( model.isUnlocked == false && model.protectApp == true ) {
                    if (model.showDataExport == true) {
                        Button("Export/Import") {
                            self.model.setEncodedData()
                            self.model.importFromFile = false
                            self.showingSheet.toggle()
                            /*
                             let pasteboard = UIPasteboard.general
                             pasteboard.string = self.model.encodedData
                             */
                        }
                        Button(action: {
                            importingFile.toggle()
                        }) {
                            Text("Datei einlesen")
                        }.fileImporter(
                            isPresented: $importingFile,
                            allowedContentTypes: [.plainText,.json]
                        ) { result in
                            switch result {
                            case .success(let file):
                                print(file.absoluteString)
                                
                                // Zugriff auf Security-Scoped Resource
                                guard file.startAccessingSecurityScopedResource() else {
                                   return
                                }
                                
                                defer { file.stopAccessingSecurityScopedResource() }
                                
                                do {
                                    let importJson = try String(contentsOf: file)
                                    self.model.encodedData = importJson
                                    self.model.importFromFile = true
                                    self.showingSheet.toggle()
                                } catch {
                                    print("Fehler beim Lesen der Datei: \(error)")
                                }
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                        }
                    }
                    Button("Watch synchronisieren") {
                        self.model.setEncodedDataFull()
                        model.appleWatch.syncAppDataToWatch(appData: model.encodedData)
                    }
                }
                Button("App Information") {
                    self.showingInfo.toggle()
                }
                /*
                Button("Daten an die Watch senden") {
                    model.appleWatch.sendDataToWatch(data: "Hallo von iPhone! \(Date())")
                }
                */
                /*
                Button("Navigate") {
                    self.model.selectedItem = self.model.dataObjects[1]
                }
                Button("Auto Checkin Test") {
                    self.location = self.model.getCurrentLocation()
                    self.model.selectItemForAutoCheckin()
                }
                 */
            }
        }
        
    }
    
   
}


#Preview {
    ContentView().environmentObject(Model()).task {
        if #available(iOS 17.0, *) {
            try? Tips.resetDatastore()
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        } else {
            // Fallback on earlier versions
        }
    }
}

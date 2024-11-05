//
//  TipKit.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 17.01.24.
//

import TipKit

@available(iOS 17.0, *)
struct GetStartedTip: Tip {
    var id = UUID()
    
    var title: Text {
        Text("Einstieg")
    }
    
    var message: Text? {
        Text("Mit neu eine Karten anlegen oder über Export/Import Daten übernehmen")
    }
    
    var image: Image? {
        Image(systemName: "checkmark.shield")
    }
    
    var rules: [Rule] {
        #Rule(Self.$hasViewedGetStartedTip) { $0 == false }
    }
    
    @Parameter
    static var hasViewedGetStartedTip: Bool = false
}

struct FavoriteTip: Tip {
     var id = UUID()
     
    var title: Text {
        Text("Einstieg")
    }
    
    var message: Text? {
        Text("Mit neu eine Karten anlegen oder über Export/Import Daten übernehmen")
    }
 
        var image: Image? {
        Image(systemName: "checkmark.shield")
    }
}

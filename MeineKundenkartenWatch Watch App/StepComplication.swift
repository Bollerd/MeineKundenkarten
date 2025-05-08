//
//  StepComplication.swift
//  Meine Kundenkarten
//
//  Created by Dirk Boller on 09.01.2025.
//

//import HealthKit
import ClockKit
//import _ClockKit_SwiftUI
/*
 class StepCountProvider {
 private let healthStore = HKHealthStore()
 
 func requestAuthorization(completion: @escaping (Bool) -> Void) {
 let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
 let typesToRead: Set = [stepType]
 
 healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
 completion(success)
 }
 }
 
 func fetchSteps(completion: @escaping (Double) -> Void) {
 let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
 let now = Date()
 let startOfDay = Calendar.current.startOfDay(for: now)
 
 let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
 let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
 guard let result = result, let sum = result.sumQuantity() else {
 completion(0.0)
 return
 }
 completion(sum.doubleValue(for: HKUnit.count()))
 }
 healthStore.execute(query)
 }
 }
 */

/*
 class ComplicationController3: NSObject, CLKComplicationDataSource {
 
 private let stepCountProvider = StepCountProvider()
 
 func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
 stepCountProvider.fetchSteps { steps in
 let text = CLKSimpleTextProvider(text: "\(Int(steps)) Schritte")
 let template: CLKComplicationTemplate
 
 switch complication.family {
 case .modularSmall:
 template = CLKComplicationTemplateModularSmallSimpleText(textProvider: text)
 case .modularLarge:
 template = CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: CLKSimpleTextProvider(text: "Schritte"), body1TextProvider: text)
 default:
 handler(nil) // Komplikationstyp nicht unterstützt
 return
 }
 
 let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
 handler(entry)
 }
 }
 
 func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
 handler([])
 }
 
 
 // This method is for creating an actual live complication.
 func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
 guard
 let fullColorImage = UIImage(named: "Test"),
 let tintColorImage = UIImage(named: "Test")
 else { return nil }
 
 let tintColorImageProvider = CLKImageProvider(onePieceImage: tintColorImage)
 let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: fullColorImage, tintedImageProvider: tintColorImageProvider)
 
 switch complication.family {
 case .graphicCircular:
 let template = CLKComplicationTemplateGraphicCircularImage(imageProvider: fullColorImageProvider)
 return CLKComplicationTimelineEntry(date: .now, complicationTemplate: template)
 
 case .graphicCorner:
 let template = CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: fullColorImageProvider)
 return CLKComplicationTimelineEntry(date: .now, complicationTemplate: template)
 
 default:
 return nil
 }
 }
 
 func complicationDescriptors() async -> [CLKComplicationDescriptor] {
 [
 CLKComplicationDescriptor(identifier: "stepCount", displayName: "Schritte", supportedFamilies: [.graphicCircular,.graphicCorner])
 ]
 }
 
 func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
 guard let img = UIImage(named: "Test"), let img2 = UIImage(named: "Test") else { return nil }
 
 let imgProvider = CLKFullColorImageProvider(fullColorImage: img)
 
 switch complication.family  {
 /*
  case .graphicRectangular:
  let template = CLKComplicationTemplateGraphicRectangularText()
  template.textLine1 = "\(Int.random(in: 1...100))"
  template.textLine2 = "\(Int.random(in: 1...100))"
  template.textLine3 = "\(Int.random(in: 1...100))"
  return template
  */
 case .graphicCorner:
 let template = CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: imgProvider )
 return template
 case .graphicCircular:
 let template = CLKComplicationTemplateGraphicCircularImage(imageProvider: imgProvider )
 return template
 default : return nil
 }
 }
 }
 */

final class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // This method contains important information about your complication.
    func complicationDescriptors() async -> [CLKComplicationDescriptor] {
        [
            CLKComplicationDescriptor(
                identifier: "watch-complication-dirk", // This id should be unique and stable.
                displayName: "Kundenkarte",
                supportedFamilies: [.graphicCorner])
        ]
    }
    
    // This method is for creating a complication sample. It defines how it will look in Complication Picker Mode.
    func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
        guard let fullColorImage = UIImage(named: "complication_icon"), let tintedColorImage = UIImage(named: "complication_icon_tinted") else { return nil }
        let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: fullColorImage)
        let tintColorImageProvider = CLKFullColorImageProvider(fullColorImage: tintedColorImage)
       // let textProvider = CLKSimpleTextProvider(text: "Karten")
        switch complication.family {
              case .graphicCircular:
              let template = CLKComplicationTemplateGraphicCircularImage(imageProvider: fullColorImageProvider)
            return template
            
        case .graphicCorner:
           // let template = CLKComplicationTemplateGraphicCornerTextImage(textProvider: textProvider, imageProvider: tintColorImageProvider) //CLKComplicationTemplateGraphicCornerTextView(textProvider: textProvider, label: "hi")//
            let template =  CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: tintColorImageProvider)
            return template
            
        default:
            return nil
        }
    }
    
    // This method is for creating an actual live complication.
    func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
        guard
            let fullColorImage = UIImage(named: "complication_icon"),
            let tintColorImage = UIImage(named: "complication_icon_tinted")
        else { return nil }
        
        let tintColorImageProvider = CLKImageProvider(onePieceImage: tintColorImage)
        let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: fullColorImage, tintedImageProvider: tintColorImageProvider)
      //  let textProvider = CLKSimpleTextProvider(text: "Karten")
        
        switch complication.family {
        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularImage(imageProvider: fullColorImageProvider)
            return CLKComplicationTimelineEntry(date: .now, complicationTemplate: template)
            
        case .graphicCorner:
      //      let template = CLKComplicationTemplateGraphicCornerTextImage(textProvider: textProvider, imageProvider: fullColorImageProvider)
            let template = CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: fullColorImageProvider)
            return CLKComplicationTimelineEntry(date: .now, complicationTemplate: template)
            
        default:
            return nil
        }
    }
}

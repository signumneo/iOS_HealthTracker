//
//  StepCounterWidgetLive.swift
//  StepCounterWidgetLive
//
//  Created by Jacob Thomas on 7/26/24.
//

import WidgetKit
import SwiftUI
import HealthKit

struct Provider: TimelineProvider {
    let healthStore = HKHealthStore()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), stepCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), stepCount: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Fetch step count
        fetchSteps { stepCount in
            let entry = SimpleEntry(date: Date(), stepCount: stepCount)
            entries.append(entry)
            
            // Generate a timeline consisting of a single entry
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }

    func fetchSteps(completion: @escaping (Int) -> ()) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
            completion(stepCount)
        }
        healthStore.execute(query)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let stepCount: Int
}

struct StepCounterWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Steps: \(entry.stepCount)")
                .padding()
        }
        .containerBackground(Color.black, for: .widget)
    }
}

struct StepCounterWidget: Widget {
    let kind: String = "StepCounterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StepCounterWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Step Counter Widget")
        .description("Displays your step count.")
    }
}

@main
struct StepCounterWidgetLiveBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        StepCounterWidget()
    }
}

//
//  ContentView.swift
//  StepCounterWidget
//
//  Created by Jacob Thomas on 7/26/24.
//

import SwiftUI
import HealthKit
import CoreMotion

struct ContentView: View {
    @State private var stepCount = 0
    @State private var heartRate = 0
    @State private var activeEnergy = 0.0
    @State private var animationAmount: CGFloat = 1.0

    let healthStore = HKHealthStore()
    let pedometer = CMPedometer()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // Timer to refresh data every 5 seconds

    var body: some View {
        VStack {
            Text("Health Tracker")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .foregroundColor(.white)
                .shadow(radius: 10)

            VStack(spacing: 20) {
                HealthDataView(title: "Steps", value: "\(stepCount)", color: .green, icon: "figure.walk")
                HealthDataView(title: "Heart Rate", value: "\(heartRate) BPM", color: .red, icon: "heart.fill")
                HealthDataView(title: "Active Energy", value: String(format: "%.1f kcal", activeEnergy), color: .orange, icon: "flame.fill")
            }
            .padding()
            .onAppear {
                self.requestAuthorization()
                self.startPedometerUpdates()
                self.animationAmount = 1.2
            }
            .onReceive(timer) { _ in
                self.fetchHeartRate()
                self.fetchActiveEnergy()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .edgesIgnoringSafeArea(.all)
    }

    func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

        let healthTypes = Set([stepType, heartRateType, activeEnergyType])

        healthStore.requestAuthorization(toShare: nil, read: healthTypes) { success, error in
            if success {
                fetchHeartRate()
                fetchActiveEnergy()
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    func startPedometerUpdates() {
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { data, error in
                guard let data = data, error == nil else {
                    return
                }
                DispatchQueue.main.async {
                    self.stepCount = data.numberOfSteps.intValue
                }
            }
        }
    }

    func fetchHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, results, _ in
            guard let results = results as? [HKQuantitySample], let sample = results.first else {
                return
            }
            DispatchQueue.main.async {
                self.heartRate = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
            }
        }
        healthStore.execute(query)
    }

    func fetchActiveEnergy() {
        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            DispatchQueue.main.async {
                self.activeEnergy = sum.doubleValue(for: HKUnit.kilocalorie())
            }
        }
        healthStore.execute(query)
    }
}

struct HealthDataView: View {
    var title: String
    var value: String
    var color: Color
    var icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding()
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)

                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.leading, 8)

            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

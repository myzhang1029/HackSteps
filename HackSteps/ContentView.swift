//
//  ContentView.swift
//  HackSteps
//
//  Created by 张迈允 on 2021/8/30.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var isNotSupported = false;
    @State private var hasResult = false;
    @State private var resultStr = "";
    @State private var stepValue = 0.0;
    
    var body: some View {
        VStack {
            Spacer()
            Text("Congrats! Your device supports HealthKit!")
                .padding()
            Spacer()
            Text("Input your desired number of steps to add:")
                .padding()
            HStack {
                Spacer()
                Slider(
                    value: $stepValue,
                    in: 0...20000
                )
                Spacer()
                Text(String(format: "%.0f", stepValue))
                Spacer()
            }
            Button(action: commit, label: {
                Text("Commit Suicide")
            })
            Spacer()
        }
        .navigationBarTitle(Text("Step Count Modifier"))
        .alert(isPresented: $isNotSupported) { () -> Alert in
            return Alert(title: Text("Error"),
                         message: Text("Your device does not allow writing HealthKit!"),
                         dismissButton: .destructive(Text("Bye")) {
                            // TODO: Better exit
                            exit(0)
                         }
            )
        }
        .alert(isPresented: $hasResult) { () -> Alert in
            return Alert(title: Text("Result"),
                         message: Text(resultStr),
                         dismissButton: .default(Text("Dismiss"))
            )
        }
    }
    
    
    /// Terminate if HealthKit is not supported
    private func quitter() {
        print("Dying since permissions are not granted")
        self.isNotSupported = true
    }
    
    /// Get Step count type
    private func getStepCountType() -> HKQuantityType {
        guard let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("Step count is no longer available in HealthKit")
        }
        return stepCount
    }
    
    /// Function to check for permissions, etc
    private func loadStore() -> HKHealthStore {
        let stepCount = getStepCountType()
        let allTypes = Set([stepCount])
        if !HKHealthStore.isHealthDataAvailable() {
            quitter()
        }
        let healthStore = HKHealthStore()
        // Request for write permission
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, _) in
            if !success {
                quitter()
            }
        }
        // Check if the user agreed
        if healthStore.authorizationStatus(for: stepCount) != .sharingAuthorized {
            quitter()
        }
        print("HealthKit permissions granted")
        return healthStore
    }
    
    /// Commit the value to health
    private func commit() {
        let toAdd = stepValue
        let store = loadStore()
        print("Adding", UInt16(toAdd), "steps")
        // Create a unitless quantity
        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: toAdd)
        // TODO: Ask user for a date
        let date = Date()
        let sample = HKQuantitySample(type: getStepCountType(), quantity: quantity, start: date, end: date)
        store.save(sample) { (success, error) in
            if let error = error {
                print("Error saving: \(error.localizedDescription)")
            } else {
                print("Succeeded")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

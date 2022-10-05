//
//  ViewModel.swift
//  HKSample
//
//  Created by Isiah Marie Ramos Malit on 2022-10-04.
//

import Foundation
import HealthKit

class ViewModel: ObservableObject {
    
    let healthStore = HKHealthStore()
    var meditationData: [HKSample] = []
    
    func requestPermissions(){
        let typestoRead = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier:.mindfulSession)!,
            HKObjectType.workoutType(),
            HKObjectType.categoryType(forIdentifier:.sleepAnalysis)!,
            ])
        
        let typestoShare = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier:.mindfulSession)!,
            HKObjectType.workoutType(),
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
            ])
        
        self.healthStore.requestAuthorization(
            toShare: typestoShare,
            read: typestoRead
        ) { (success, error) -> Void in
            if success == false {
                NSLog(" Display not allowed")
            }
        }
    }
    
    func getStepsData() {
        
        let calendar = Calendar.current
        var anchorComponents = calendar.dateComponents([.day, .month,. year], from: Date())
        anchorComponents.hour = 0
        let anchorDate = calendar.date(from: anchorComponents)
        
        var interval = DateComponents()
        interval.day = 1
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("nil step type")
            return
        }
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: anchorDate ?? Date(),
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { query, results, error in
            if error != nil {
                print ("error in steps")
            }
            
            results?.enumerateStatistics(
                from: calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                to: Date()
            ) { statResults, isStop in
                print(statResults.sumQuantity())
            }
        }
        
        self.healthStore.execute(query)
    }
    
    func getMindfulnessData() {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            print("nil mindfulness type")
            return
        }
        
        let query = HKSampleQuery(
            sampleType: mindfulType,
            predicate: nil,
            limit: 0,
            sortDescriptors: nil
        ) { [weak self] query, samples, error in
            if error != nil {
                print("error in mindfulness")
            }
            
            if let samples = samples {
                self?.displaySamples(samples: samples)
                self?.meditationData = samples
            }
        }
        
        self.healthStore.execute(query)
    }
    
    func getWorkoutData() {
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: nil,
            limit: 0,
            sortDescriptors: nil
        ) { [weak self] query, samples, error in
            if error != nil {
                print("error in workout")
            }
            
            if let samples = samples {
                self?.displaySamples(samples: samples)
            }
        }
        
        self.healthStore.execute(query)
    }
    
    func getSleepData() {
        guard let sleepData = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("nil sleep data")
            return
        }
        
        //get sleep data from 1 day before
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-1.0 * 60 * 60 * 24)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: []
        )
        
        let query = HKSampleQuery(
            sampleType: sleepData,
            predicate: predicate,
            limit: 0,
            sortDescriptors: nil
        ) { [weak self] query, samples, error in
            if error != nil {
                print("error in sleep")
            }
            
            if let samples = samples {
                self?.displaySamples(samples: samples)
            }
        
        }
        self.healthStore.execute(query)
    }
    
    private func displaySamples(samples: [HKSample]) {
        print(samples)
        for sample in samples {
            print(sample)
        }
    }
    
    func syncDisplay() {
        print("syncing display")
        print(meditationData)
    }
}

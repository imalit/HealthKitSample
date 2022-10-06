//
//  ViewModel.swift
//  HKSample
//
//  Created by Isiah Marie Ramos Malit on 2022-10-04.
//

import Foundation
import HealthKit
import Combine

enum ActivityType {
    case mindfulness
    case steps
    case workout
    case sleep
}

protocol HealthModule: AnyObject {
    var healthStore: HKHealthStore? { get set }
    var isHKAvailable: Bool { get }
    
    // Returns true iff request permission is successful.
    // Returns error if there's an error in requesting auth.
    func requestReadWritePermission(toShare: Set<HKSampleType>?,
                                    toRead: Set<HKSampleType>?) -> Future<Bool, Error>
    
    // Returns a publisher that contains either a list of all activity samples, or error
    func getData(activityType: ActivityType) -> AnyPublisher<[HKSample]?, Error>
}

extension HealthModule {
    var isHKAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    func requestReadWritePermission(toShare: Set<HKSampleType>?,
                                    toRead: Set<HKSampleType>?) -> Future<Bool, Error> {
        
        let toShareTypes = getSampleTypes(sampleTypes: toShare)
        let toReadTypes = getSampleTypes(sampleTypes: toRead)
        
        return Future { [weak self] promise in
            self?.healthStore?.requestAuthorization(
                toShare: toShareTypes,
                read: toReadTypes
            ) { authSuccess, error in
                guard error == nil else {
                    promise(.failure(error!))
                    return
                }
                promise(.success(authSuccess))
            }
        }
    }
    
    func getData(activityType: ActivityType) -> AnyPublisher<[HKSample]?, Error> {
        let subject = PassthroughSubject<[HKSample]?, Error>()
        
        //setup sample type
        let sampleType = getSampleType(fromActivity: activityType)
        guard let sampleType = sampleType else {
            NSLog("No samples!")
            subject.send(completion: .finished)
            return subject.eraseToAnyPublisher()
        }
        
        //setup predicate and get data from 1 day before
        let predicate = getPredicateOneDay()
        
        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: 0,
            sortDescriptors: nil
        ) { _, samplesFromQuery, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let samplesFromQuery = samplesFromQuery else {
                subject.send(completion: .finished)
                return
            }
            
            subject.send(samplesFromQuery)
            subject.send(completion: .finished)
            
        }

        self.healthStore?.execute(query)
        return subject.eraseToAnyPublisher()
    }
}

private extension HealthModule {
    func getSampleTypes(sampleTypes: Set<HKSampleType>?) -> Set<HKSampleType> {
        if let customSampleTypes = sampleTypes {
            return customSampleTypes
        } else {
            return Set([
                    HKObjectType.quantityType(forIdentifier: .stepCount)!,
                    HKObjectType.categoryType(forIdentifier:.mindfulSession)!,
                    HKObjectType.workoutType(),
                    HKObjectType.categoryType(forIdentifier:.sleepAnalysis)!,
                ])
        }
    }
    
    func getSampleType(fromActivity: ActivityType) -> HKSampleType? {
        var sampleType: HKSampleType?
        switch fromActivity {
        case .mindfulness:
            sampleType = HKObjectType.categoryType(forIdentifier: .mindfulSession)
        case .steps:
            sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)
        case .workout:
            sampleType = HKObjectType.workoutType()
        case .sleep:
            sampleType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        }
        return sampleType
    }
    
    func getPredicateOneDay() -> NSPredicate {
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-1.0 * 60 * 60 * 24)
        
        return HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: []
        )
    }
}

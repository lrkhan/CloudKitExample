//
//  CloudKitUtility.swift
//  CloudKit Utility Functions
//
//  Created by Luthfor Khan on 5/15/22.
//

import CloudKit
import Foundation
import SwiftUI

protocol CloudKitableProtocol {
    init?(record: CKRecord)
    
    var record: CKRecord { get }
}

class CloudKitUtility {
    static let NotificationOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
    
    enum CloudKitError: String, LocalizedError {
        case couldNotDetermine
        case available
        case restricted
        case noAccount
        case temporarilyUnavailable
        case unknown
        case iCloudPermissionError
        case FailedToFetchUserID
        case FailedToDiscoverUser
    }
}

// CK - User/iCloud Conectivity Check
extension CloudKitUtility {
    // Status of User's iCliud Account
    static func getiCloudStatus(completion: @escaping (Result<Bool, Error>) -> ()) {
        CKContainer.default().accountStatus { returnedStatus, returnedError in
            
            switch returnedStatus {
            case .couldNotDetermine:
                completion(.failure(CloudKitError.couldNotDetermine))
            case .available:
                completion(.success(true))
            case .restricted:
                completion(.failure(CloudKitError.restricted))
            case .noAccount:
                completion(.failure(CloudKitError.noAccount))
            case .temporarilyUnavailable:
                completion(.failure(CloudKitError.temporarilyUnavailable))
            @unknown default:
                completion(.failure(CloudKitError.unknown))
            }
        }
    }
    
    static func requestApplicationPersmission(completion: @escaping (Result<Bool, Error>) -> ()) {
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) {returnedStatus, returnedError in
            if returnedStatus == .granted {
                completion(.success(true))
            } else {
                completion(.failure(CloudKitError.iCloudPermissionError))
            }
            
        }
    }
    
    static private func fetchiCloudUserRecordID(completion: @escaping (Result<CKRecord.ID, Error>) -> ()) {
        CKContainer.default().fetchUserRecordID {returnedID, returnedErr in
            if let id = returnedID {
                completion(.success(id))
            } else {
                completion(.failure(CloudKitError.FailedToFetchUserID))
            }
        }
    }
    
    static private func discoveriCloudUser(id: CKRecord.ID, completion: @escaping (Result<String, Error>) -> ()) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) {returnedId, returnedErr in
            if let name = returnedId?.nameComponents?.givenName {
                completion(.success(name))
            } else {
                completion(.failure(CloudKitError.FailedToDiscoverUser))
            }
        }
    }
    
    static func discoverUserID(completion: @escaping (Result<String, Error>) -> ()) {
        fetchiCloudUserRecordID { result in
            switch result {
            case .success(let recordID):
                CloudKitUtility.discoveriCloudUser(id: recordID, completion: completion)
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}

// CK - CRUD Functions
extension CloudKitUtility {
    
    static func fetch<T:CloudKitableProtocol>(predicate: NSPredicate, recordType: CKRecord.RecordType, sortDescriptors: [NSSortDescriptor]? = nil, resultLimit: Int? = nil, completion: @escaping (_ items: [T]) -> ()) {
        
        // create operation
        let operation = createOperation(predicate: predicate, recordType: recordType, sortDescriptors: sortDescriptors, resultLimit: resultLimit)
        
        // get items in the query
        var returnedItems = [T]()
        addRecordMatchedBlock(operation: operation) { item in
            returnedItems.append(item)
        }
        
        // query completion
        addQueryResultBlock(operation: operation) { finished in
            completion(returnedItems)
        }
        
        // execute operation
        addOpperation(operation: operation)
    }
    
    static private func createOperation(predicate: NSPredicate, recordType: CKRecord.RecordType, sortDescriptors: [NSSortDescriptor]? = nil, resultLimit: Int? = nil) -> CKQueryOperation {
        
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        if let descriptors = sortDescriptors {
            query.sortDescriptors = descriptors
            //[NSSortDescriptor(key: "name", ascending: true)]
        }
        
        let queryOp = CKQueryOperation(query: query)
        // can limit the number of items returned from query
        
        if let limit = resultLimit {
            queryOp.resultsLimit = limit
        }
        
        return queryOp
    }
    
    static private func addRecordMatchedBlock<T: CloudKitableProtocol>(operation: CKQueryOperation, completion: @escaping (_ item: T) -> ()) {
        operation.recordMatchedBlock = { (returnedRecID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                guard let item = T(record: record) else {return}
                completion(item)
            case .failure(_):
                break
            }
        }
    }
    
    static private func addQueryResultBlock(operation: CKQueryOperation, completion: @escaping (_ finished: Bool) -> ()) {
        operation.queryResultBlock = {returnedRes in
            completion(true)
        }
    }
    
    static private func addOpperation(operation: CKDatabaseOperation) {
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    static func addOrUpdate<T:CloudKitableProtocol>(item: T, completion: @escaping (Result<Bool, Error>) -> ()) {
        // save to CloudKit
        saveItem(record: item.record, completion: completion)
    }
    
    static func saveItem(record: CKRecord, completion: @escaping (Result<Bool, Error>) -> ()) {
        CKContainer.default().publicCloudDatabase.save(record) {returnedRecord, returnedError in
            
            if let returnedError = returnedError {
                completion(.failure(returnedError))
            } else {
                completion(.success(true))
            }
        }
    }
    
    static func delete<T:CloudKitableProtocol>(item: T, completion: @escaping (Result<Bool, Error>) -> ()) {
        CloudKitUtility.delete(record: item.record, completion: completion)
    }
    
    static private func delete(record: CKRecord, completion: @escaping (Result<Bool, Error>) -> ()) {
        CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) { returnedRecordID, returnedError in
            if let returnedError = returnedError {
                completion(.failure(returnedError))
            } else {
                completion(.success(true))
            }
        }
    }
}

// CK - Notifications
extension CloudKitUtility {
    
    static func requestNotificationPersmission() {
        UNUserNotificationCenter.current().requestAuthorization(options: CloudKitUtility.NotificationOptions) { succes, error in
            if let error = error {
                print(error)
            } else if succes {
                print("Successful")
                
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Failure")
            }
        }
    }
    
    func subscribeTo(_ type: String, for optionType: CKQuerySubscription.Options) {
        
        var subID = "\(type)"
        
        switch optionType {
        case .firesOnRecordCreation:
            subID += "New"
        case .firesOnRecordDeletion:
            subID += "Deletetion"
        case .firesOnRecordUpdate:
            subID += "Updates"
        default:
            subID += "Other"
        }
        
        let predicate = NSPredicate(value: true)
        let sub = CKQuerySubscription(recordType: type, predicate: predicate, subscriptionID: subID, options: optionType)
        
        let not = CKSubscription.NotificationInfo()
        
        not.title = "There is a new \(type)"
        not.alertBody = "Click me to check it out!"
        not.soundName = "default"
        
        sub.notificationInfo = not
        
        CKContainer.default().publicCloudDatabase.save(sub) { returnedSub, returnedErr in
            if let returnedErr = returnedErr {
                print(returnedErr)
            } else {
                print("The user subscribed to \(subID)")
            }
        }
    }
    
    func unsubscribeFrom(_ type: String, for optionType: CKQuerySubscription.Options) {
        
        var subID = "\(type)"
        
        switch optionType {
        case .firesOnRecordCreation:
            subID += "New"
        case .firesOnRecordDeletion:
            subID += "Deletetion"
        case .firesOnRecordUpdate:
            subID += "Updates"
        default:
            subID += "Other"
        }
        
        // check the subscriptions the user has
//        CKContainer.default().publicCloudDatabase.fetchAllSubscriptions
        
        CKContainer.default().publicCloudDatabase.delete(withSubscriptionID: subID) { returnedID, returnedErr in
            if let returnedErr = returnedErr {
                print(returnedErr)
            } else {
                print("The user was unsubscribed from \(subID)")
            }
        }
    }
}

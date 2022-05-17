//
//  CKPushNot.swift
//  CloudKitEx
//
//  Created by Luthfor Khan on 5/15/22.
//

import CloudKit
import SwiftUI

class CKPushNotVM: ObservableObject {
    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
    func requestPersmission() {
        UNUserNotificationCenter.current().requestAuthorization(options: options) { succes, error in
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
    
    func subscribeToNot() {
        let predicate = NSPredicate(value: true)
        let sub = CKQuerySubscription(recordType: "Person", predicate: predicate, subscriptionID: "FruitAddedToDataBase", options: .firesOnRecordCreation)
        
        let not = CKSubscription.NotificationInfo()
        
        not.title = "There is a new Fruit"
        not.alertBody = "Open to Check"
        not.soundName = "default"
        
        sub.notificationInfo = not
        
        CKContainer.default().publicCloudDatabase.save(sub) { returnedSub, returnedErr in
            if let returnedErr = returnedErr {
                print(returnedErr)
            } else {
                print("CK Subed")
            }
        }
    }
    
    func unSubToNot() {
        // check the subscriptions the user has
//        CKContainer.default().publicCloudDatabase.fetchAllSubscriptions
        
        CKContainer.default().publicCloudDatabase.delete(withSubscriptionID: "FruitAddedToDataBase") { returnedID, returnedErr in
            if let returnedErr = returnedErr {
                print(returnedErr)
            } else {
                print("UnSubbed")
            }
        }
    }
}

struct CKPushNot: View {
    @StateObject private var vm = CKPushNotVM()
    
    var body: some View {
        VStack(spacing: 40) {
            Button {
                vm.requestPersmission()
            } label: {
                Text("Request Persmission")
            }
            .padding()
            
            Button {
                vm.subscribeToNot()
            } label: {
                Text("SubScribe To Notfiy")
            }
            .padding()
            
            Button {
                vm.unSubToNot()
            } label: {
                Text("UnSubscribe")
            }
            .padding()
            
        }
    }
}

struct CKPushNot_Previews: PreviewProvider {
    static var previews: some View {
        CKPushNot()
    }
}

//
//  ContentView.swift
//  CloudKitEx
//
//  Created by Luthfor Khan on 5/9/22.
//

import CloudKit
import SwiftUI

class CloudKitModel: ObservableObject {
    @Published var iCloudIn: Bool = false
    @Published var status = ""
    @Published var userName = ""
    @Published var permissionStat: Bool = false
    @Published var ckReckordID: String?
    
    
    init () {
        getiCloudStatus()
        requestPermission()
        fetchiCloudUserRecordID()
    }
    
    private func getiCloudStatus() {
        CKContainer.default().accountStatus { returnedStats, returnedErr in
            DispatchQueue.main.async {
                switch returnedStats {
                case .couldNotDetermine:
                    self.status = iCloudAccountErr.couldNotDetermine.rawValue
                case .available:
                    self.status = iCloudAccountErr.available.rawValue
                    self.iCloudIn = true
                case .restricted:
                    self.status = iCloudAccountErr.restricted.rawValue
                case .noAccount:
                    self.status = iCloudAccountErr.noAccount.rawValue
                case .temporarilyUnavailable:
                    self.status = iCloudAccountErr.temporarilyUnavailable.rawValue
                @unknown default:
                    self.status = iCloudAccountErr.unknown.rawValue
                }
            }
        }
    }
    
    enum iCloudAccountErr: String {
        case couldNotDetermine, available, restricted, noAccount, temporarilyUnavailable, unknown
    }
    
    // user needs to grand permission to get iCloud name -> maybe add additional step incse they select don't allow
    func requestPermission() {
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) {[weak self] returnedStat, returnedErr in
            DispatchQueue.main.async {
                if returnedStat == .granted {
                    self?.permissionStat = true
                }
            }
        }
    }
    
    func fetchiCloudUserRecordID() {
        CKContainer.default().fetchUserRecordID {[weak self] returnedID, returnedErr in
            if let id = returnedID {
                self?.ckReckordID = id.recordName
                self?.discoveriCloudUser(id: id)
            }
        }
    }
    
    func discoveriCloudUser(id: CKRecord.ID) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self] returnedId, returnedErr in
            DispatchQueue.main.async {
                if let name = returnedId?.nameComponents?.givenName {
                    self?.userName = name
                }
            }
        }
    }
    
}

struct ContentView: View {
    @StateObject private var vm =  CloudKitModel()
    
    var body: some View {
        VStack {
            Text("Signed In?: \(vm.iCloudIn.description.uppercased())")
                .padding()
            Text("Status: \(vm.status)")
                .padding()
            Text("Permissed: \(vm.permissionStat.description.uppercased())")
                .padding()
            Text("Name: \(vm.userName)")
                .padding()
            Text("Record: \(vm.ckReckordID ?? "nil")")
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  CRUDView.swift
//  CloudKitEx
//
//  Created by Luthfor Khan on 5/10/22.
//

import CloudKit
import SwiftUI

struct Person: Hashable {
    let name: String
    let id: String
    let record: CKRecord
}

enum Location {
    case publicDir, privateDir
}

class CloudPublicNPrivate: ObservableObject {
    @Published var text: String = ""
    //@Published var fruits = [FruitModel]()
    @Published var fPublic = [Person]()
    @Published var fPrivate = [Person]()
    
    init() {
        fetchItems(from: .publicDir)
        fetchItems(from: .privateDir)
    }
    
    func addButton(to location: Location) {
        guard !text.isEmpty else {return}
        
        addItem(name: text, to: location)
    }
    
    private func addItem(name: String, to: Location) {
        // if new type iCloud will make a new type
        let newPerson = CKRecord(recordType: "Person")
        
        // dict - create
        newPerson["name"] = name
        newPerson["id"] = UUID().uuidString
        
        // code foradding image to CK Assets
//        guard
//            let img = UIImage(named: "key"),
//            let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("key.jpg"),
//            let data = img.jpegData(compressionQuality: 1.0)
//        else {return}
//
//        do {
//            try data.write(to: path)
//
//            let asset = CKAsset(fileURL: path)
//
//            newFruit["image"] = asset
//        } catch let err {
//            print(err)
//        }
        
        saveItem(record: newPerson, to: to)
    }
    
    private func saveItem(record: CKRecord, to loc: Location) {
        
        switch loc {
        case .publicDir:
            CKContainer.default().publicCloudDatabase.save(record) {[weak self] returnedRec, returnedErr in
                print("Public Error")
                print("Record: \(String(describing: returnedRec))")
                print("Error: \(String(describing: returnedErr))")
                
                //asyncAfter(deadline: .now() + 0.5)
                DispatchQueue.main.async {
                    self?.text = ""
                    
                    // better for smaller apps
                    self?.fetchItems(from: loc)
                }
            }
        case .privateDir:
            CKContainer.default().privateCloudDatabase.save(record) { [weak self] returnedRec, returnedErr in
                print("Private Error")
                print("Record: \(String(describing: returnedRec))")
                print("Error: \(String(describing: returnedErr))")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.text = ""
                    
                    // better for smaller apps
                    self?.fetchItems(from: loc)
                }
            }
        }
        
    }
    
    func fetchItems(from: Location) {
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "Person", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let queryOp = CKQueryOperation(query: query)
        // can limit the number of items returned from query
        
        var returnedItms = [Person]()
        
        queryOp.recordMatchedBlock = { (returnedRecID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                guard let name = record["name"] as? String else {return}
                guard let id = record["id"] as? String else {return}
//                let imgAsset = record["image"] as? CKAsset
//                let imgURL = imgAsset?.fileURL
                returnedItms.append(Person(name: name, id: id, record: record))
            case .failure(let err):
                print("RecordMatchError: \(err)")
            }
        }
        
        queryOp.queryResultBlock = {[weak self] returnedRes in
            print("Returned Result: \(returnedRes)")
            
            DispatchQueue.main.async {
                switch from {
                case .publicDir:
                    self?.fPublic = returnedItms
                case .privateDir:
                    self?.fPrivate = returnedItms
                }
            }
        }
        
        addOpperation(operation: queryOp, to: from)
    }
    
    func addOpperation(operation: CKDatabaseOperation, to loc: Location) {
        switch loc {
        case .publicDir:
            CKContainer.default().publicCloudDatabase.add(operation)
        case .privateDir:
            CKContainer.default().privateCloudDatabase.add(operation)
        }
        
    }
    
    func updateItem(person: Person, loc: Location){
        let record = person.record
        
        let newName = "\(person.name) \(Int.random(in: 0...100))"
        
        record["name"] = newName
        
        saveItem(record: record, to: loc)
    }
    
    func deleteItem(indexSet: IndexSet, from: Location) {
        switch from {
        case .publicDir:
            deleteItemPublic(indexSet: indexSet)
        case .privateDir:
            deleteItemPrivate(indexSet: indexSet)
        }
        
    }
    
    func deleteItemPublic(indexSet: IndexSet) {
        guard let index = indexSet.first else {return}
        
        print("In Private delete Function")
        
        let person = fPublic[index]
        
        let record = person.record
        
        CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) {[weak self] returnedRecID, returnErr in
            print("Public Delete")
            DispatchQueue.main.async {
                print("Aysnc Delete")
                self?.fPublic.remove(at: index)
            }
            
        }
    }
    
    func deleteItemPrivate(indexSet: IndexSet) {
        guard let index = indexSet.first else {return}
        
        print("In Private delete Function")
        
        let person = fPrivate[index]
        
        let record = person.record
        
        CKContainer.default().privateCloudDatabase.delete(withRecordID: record.recordID) {[weak self] returnedRecID, returnErr in
            print("Private Delete")
            DispatchQueue.main.async {
                print("Aysnc Delete")
                self?.fPrivate.remove(at: index)
            }
            
        }
    }
}

struct CRUDView2: View {
    @StateObject private var vm = CloudPublicNPrivate()
    
    var body: some View {
        NavigationView {
            VStack {
                refreshButton
                
                header
                
                txtField
                
                HStack {
                    addButtonPublic
                    
                    addButtonPrivate
                }
                
                publicList
                
                privateList
            }
            .padding()
            .navigationBarHidden(true)
            .refreshable {
                vm.fetchItems(from: .publicDir)
                vm.fetchItems(from: .privateDir)
            }
            .navigationTitle("CRUD - ☁️ CloudKit 🛠")
        }
        
    }
}

extension CRUDView2 {
    private var header: some View {
        Text("CRUD - ☁️ CloudKit 🛠")
            .font(.headline)
            .underline()
            .padding()
    }
    
    private var txtField: some View {
        TextField("Add Something", text: $vm.text)
            .padding(.horizontal)
            .frame(height: 55)
        
    }
    
    private var addButtonPublic: some View {
        Button {
            vm.addButton(to: .publicDir)
            hideKeyboard()
        } label: {
            Text("Add to Public")
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.mint)
                .cornerRadius(10)
        }
    }
    
    private var addButtonPrivate: some View {
        Button {
            vm.addButton(to: .privateDir)
            hideKeyboard()
        } label: {
            Text("Add to Private")
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.indigo)
                .cornerRadius(10)
        }
    }
    
    private var refreshButton: some View {
        HStack {
            Spacer()
            
            Button {
                vm.fetchItems(from: .publicDir)
                vm.fetchItems(from: .privateDir)
            } label: {
                Image(systemName: "arrow.clockwise")
                    .resizable()
                    .frame(width: 20, height: 25)
            }
            
        }
        
        //        Button {
        //            vm.fetchItems()
        //        } label: {
        //            Text("Refresh")
        //                .font(.headline)
        //                .foregroundColor(.white)
        //                .frame(height: 55)
        //                .frame(maxWidth: .infinity)
        //                .background(Color.pink)
        //                .cornerRadius(10)
        //        }
    }
    
    private var publicList: some View {
        VStack {
            Text("Public Data")
            List {
                ForEach(vm.fPublic, id: \.self) { person in
                    HStack {
//                        if let url = fruit.imgURL, let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
//                            Image(uiImage: img)
//                                .resizable()
//                                .frame(width: 30, height: 30)
//                                .clipShape(Circle())
//                                .padding(.horizontal)
//                        } else {
//                            Image(systemName: "person.circle")
//                                .resizable()
//                                .frame(width: 30, height: 30)
//                                .clipShape(Circle())
//                                .padding(.horizontal)
//                        }
                        
                        Text(person.name)
                    }
                    .onTapGesture {
                        vm.updateItem(person: person, loc: .publicDir)
                    }
                }
                .onDelete(perform: vm.deleteItemPublic)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var privateList: some View {
        VStack {
            Text("Private Data")
            List {
                ForEach(vm.fPrivate, id: \.self) { person in
                    HStack {
//                        if let url = fruit.imgURL, let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
//                            Image(uiImage: img)
//                                .resizable()
//                                .frame(width: 30, height: 30)
//                                .clipShape(Circle())
//                                .padding(.horizontal)
//                        } else {
//                            Image(systemName: "person.circle")
//                                .resizable()
//                                .frame(width: 30, height: 30)
//                                .clipShape(Circle())
//                                .padding(.horizontal)
//                        }
                        
                        Text(person.name)
                    }
                    .onTapGesture {
                        vm.updateItem(person: person, loc: .privateDir)
                    }
                }
                .onDelete(perform: vm.deleteItemPrivate)
            }
            .listStyle(PlainListStyle())
        }
    }
}


//struct CRUDView_Previews: PreviewProvider {
//    static var previews: some View {
//        CRUDView()
//    }
//}

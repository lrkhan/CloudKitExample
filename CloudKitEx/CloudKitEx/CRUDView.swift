//
//  CRUDView.swift
//  CloudKitEx
//
//  Created by Luthfor Khan on 5/10/22.
//

import CloudKit
import SwiftUI

struct FruitModel: Hashable {
    let name: String
    let imgURL: URL?
    let record: CKRecord
}

class Cloud: ObservableObject {
    @Published var text: String = ""
    @Published var fruits = [FruitModel]()
    
    init() {
        fetchItems()
    }
    
    func addButton() {
        guard !text.isEmpty else {return}
        
        addItem(name: text)
    }
    
    private func addItem(name: String) {
        // if new type iCloud will make a new type
        let newFruit = CKRecord(recordType: "Fruits")
        
        // dict - create
        newFruit["name"] = name
        
        guard
            let img = UIImage(named: "key"),
            let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("key.jpg"),
            let data = img.jpegData(compressionQuality: 1.0)
        else {return}
        
        do {
            try data.write(to: path)
            
            let asset = CKAsset(fileURL: path)
            
            newFruit["image"] = asset
        } catch let err {
            print(err)
        }
        
        saveItem(record: newFruit)
    }
    
    private func saveItem(record: CKRecord) {
        CKContainer.default().publicCloudDatabase.save(record) {[weak self] returnedRec, returnedErr in
            print("Record: \(String(describing: returnedRec))")
            print("Error: \(String(describing: returnedErr))")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.text = ""
                
                // better for smaller apps
                self?.fetchItems()
            }
        }
    }
    
    func fetchItems() {
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "Fruits", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let queryOp = CKQueryOperation(query: query)
        // can limit the number of items returned from query
        
        var returnedItms = [FruitModel]()
        
        queryOp.recordMatchedBlock = { (returnedRecID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                guard let name = record["name"] as? String else {return}
                let imgAsset = record["image"] as? CKAsset
                let imgURL = imgAsset?.fileURL
                returnedItms.append(FruitModel(name: name, imgURL: imgURL, record: record))
            case .failure(let err):
                print("RecordMatchError: \(err)")
            }
        }
        
        queryOp.queryResultBlock = {[weak self] returnedRes in
            print("Returned Result: \(returnedRes)")
            
            DispatchQueue.main.async {
                self?.fruits = returnedItms
            }
        }
        
        addOpperation(operation: queryOp)
    }
    
    func addOpperation(operation: CKDatabaseOperation) {
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func updateItem(fruit: FruitModel){
        let record = fruit.record
        
        let newName = "\(fruit.name) \(Int.random(in: 0...100))"
        
        record["name"] = newName
        
        saveItem(record: record)
    }
    
    func deleteItem(indexSet: IndexSet) {
        guard let index = indexSet.first else {return}
        let fruit = fruits[index]
        let record = fruit.record
        
        CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) {[weak self] returnedRecID, returnErr in
            DispatchQueue.main.async {
                self?.fruits.remove(at: index)
            }
            
        }
    }
}

struct CRUDView: View {
    @StateObject private var vm = Cloud()
    
    var body: some View {
        NavigationView {
            VStack {
                header
                
                txtField
                
                addButton
                
                refreshButton
                
                List {
                    ForEach(vm.fruits, id: \.self) { fruit in
                        HStack {
                            if let url = fruit.imgURL, let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                                    .padding(.horizontal)
                            } else {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                                    .padding(.horizontal)
                            }
                            
                            Text(fruit.name)
                        }
                            .onTapGesture {
                                vm.updateItem(fruit: fruit)
                            }
                    }
                    .onDelete(perform: vm.deleteItem)
                }
                .listStyle(PlainListStyle())
            }
            .padding()
            .navigationBarHidden(true)
        }
        
    }
}

extension CRUDView {
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
    
    private var addButton: some View {
        Button {
            vm.addButton()
        } label: {
            Text("Add")
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.mint)
                .cornerRadius(10)
        }
    }
    
    private var refreshButton: some View {
        Button {
            vm.fetchItems()
        } label: {
            Text("Refresh")
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.pink)
                .cornerRadius(10)
        }
    }
}

//struct CRUDView_Previews: PreviewProvider {
//    static var previews: some View {
//        CRUDView()
//    }
//}

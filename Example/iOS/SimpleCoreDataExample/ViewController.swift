//
//  ViewController.swift
//  SimpleCoreDataExample
//
//  Created by Munger on 2020/7/21.
//  Copyright © 2020 Munger. All rights reserved.
//

import UIKit
import SimpleCoreData

extension Person {
    public override var primeKey: String {
        return self.uid ?? ""
    }
}

class ViewController: UIViewController {
    
    let database:some Storage = DBFactory.openDB(objectModelName: "SimpleDataBase", dbName: "TestCoreData")

    override func viewDidLoad() {
        super.viewDidLoad()
        let observal = DBFactory.addObserver(database,type:Person.self)
        observal.observer { (persons) in
            for person in persons {
                switch person{
                case .insert(let content):
                    print(content)
                default:
                    break
                }
            }
        }
        print(database.storePath())
    }
    
    deinit {
        DBFactory.removeObserver(database, type: Person.self)
    }
    
    @IBAction func click(_ sender: Any) {
        createInMainThread()
    }
    
    @IBAction func queryData(_ sender: Any) {
        fetchFromMainThread()
    }
    
    func createInMainThread() {
        let user:Person = try! self.database.context.create()
        user.syncDictionary(["name":"hello","uid":"key"])
        try? self.database.context.saveData()
    }
    
    func createSubThread() {
        self.database.backgroundOperation({ (context, save) in
            let user:Person = try! context.create()
            user.name = "lili"
            user.uid = "bg"
            save()
        }) { (error) in
            
        }
    }
    
    func fetchFromThread() {
        self.database.backgroundOperation({ (context, _) in
            let request = FetchRequest<Person>(context).sorted(with: "name", ascending: true)
            let result = try? context.fetch(request)
            print(result ?? "NULL")
        }) { (hasError) in
    
        }
    }
    
    func fetchFromMainThread() {
        let request = FetchRequest<Person>(database.context).sorted(with: "name", ascending: true)
        let result = try? database.context.fetch(request)
        print(result ?? "NULL")
    }

}


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
    
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var modifyBtn: UIButton!
    @IBOutlet weak var queryBtn: UIButton!
    
    @IBOutlet weak var addNameTextField: UITextField!
    @IBOutlet weak var addAgeTextField: UITextField!
    @IBOutlet weak var queryNameTextField: UITextField!
    
    @IBOutlet weak var addContentTipLabel: UILabel!
    @IBOutlet weak var queryResultLabel: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var queryAllBtn: UIButton!
    
    let database:some Storage = DBFactory.openDB(objectModelName: "SimpleDataBase", dbName: "TestCoreData")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataBaseObserval()
        
        addBtn.layer.cornerRadius = 15.0
        modifyBtn.layer.cornerRadius = 15.0
        queryBtn.layer.cornerRadius = 15.0
        deleteBtn.layer.cornerRadius = 15.0
        queryAllBtn.layer.cornerRadius = 15.0
        
        addContentTipLabel.isHidden = true
    }
    
    func setupDataBaseObserval() {
        let observal = DBFactory.addObserver(database,type:Person.self)
        observal.observer { (persons) in
            for person in persons {
                switch person{
                case .insert(let content):
                    print("Insert: \(content)")
                case .delete(let content):
                    print("Delete: \(content)")
                case .update(let content):
                    print("Update: \(content)")
                default:
                    break
                }
            }
        }
        print(database.storePath())
    }
    
    @IBAction func addDataClick(_ sender: Any) {
        guard let addText = self.addNameTextField.text,let addAge = self.addAgeTextField.text,!addText.isEmpty && !addAge.isEmpty else {
            showTips(content: "Please input content to be added", isError: true)
            return;
        }
        createInMainThread(content: ["name":addText,"age":(Int(addAge) ?? 0)])
    }
    
    @IBAction func queryDataClick(_ sender: Any) {
        guard let queryText = self.queryNameTextField.text,!queryText.isEmpty else {
            showTips(content: "Please input content to be queried", isError: true)
            return;
        }
        if let result = fetchInMainThread(name: queryText) {
            let content = "Name: " + "\(result.name ?? "")" + " Age: " + "\(result.age)"
            queryResultLabel.text = content
            showTips(content: "Query data successful", isError: false)
        } else {
            showTips(content: "Query data is not exist", isError: true)
        }
    }
    
    @IBAction func modifyDataClick(_ sender: Any) {
        guard let queryText = self.queryNameTextField.text,!queryText.isEmpty else {
            showTips(content: "Please input content to be modified", isError: true)
            return;
        }
        let alert = UIAlertController(title: "Modify", message: "Input age", preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.placeholder = "Input Age"
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            if let text = alert.textFields?.first?.text,let age = Int(text) {
                self.modifyAge(name: queryText, age)
            }
        }
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func deleteClick(_ sender: Any) {
        guard let queryText = self.queryNameTextField.text,!queryText.isEmpty else {
            showTips(content: "Please input content to be deleted", isError: true)
            return;
        }
        do {
            try deleteInMainThread(name: queryText)
            showTips(content: "Delete data successfull", isError: false)
            self.queryResultLabel.text = ""
        } catch {
            showTips(content: "Delete data failed", isError: true)
        }
    }
    
    @IBAction func queryAllClick(_ sender: Any) {
        fetchAllDataAndShow()
    }
    
    deinit {
        DBFactory.removeObserver(database, type: Person.self)
    }
    
    func showTips(content: String, isError:Bool) {
        addContentTipLabel.isHidden = false
        if isError {
            self.addContentTipLabel.textColor = UIColor.red
        } else {
            self.addContentTipLabel.textColor = UIColor.green
        }
        self.addContentTipLabel.text = content;
    }
    
    func modifyAge(name: String,_ age: Int) {
        if let result = fetchInMainThread(name: name) {
            result.age = Int16(age)
            do {
                try database.context.saveData()
            } catch {
                showTips(content: "Modify data successful", isError: false)
            }
        } else {
            showTips(content: "Can not find data", isError: true)
        }
    }
    
    func fetchAllDataAndShow() {
        fetchAllData {[weak self] (result) in
            guard let self = self else {return}
            if let result = result {
                var allData = ""
                for content in result {
                    allData = allData + "Name: " + "\(content.name ?? "")"
                    allData = allData + " Age: " + "\(content.age)" + "\n"
                }
                DispatchQueue.main.sync {
                    self.queryResultLabel.text = allData
                    self.showTips(content: "Query all data successful", isError: false)
                }
            }
        }
    }
    
    func createInMainThread(content: [String:Any]) {
        let user:Person = try! self.database.context.create()
        var newContent = content
        newContent["uid"] = UUID().uuidString
        user.syncDictionary(newContent)
        do {
            try self.database.context.saveData()
            showTips(content: "You add Data successful", isError: false)
        } catch  {
            showTips(content: "You add Data failed", isError: true)
        }
    }
    
    func createInSubThread(content: [String:String],complete:@escaping (Bool) -> Void) {
        self.database.backgroundOperation({ (context, save) in
            let user:Person = try! context.create()
            user.syncDictionary(content)
            save()
            complete(true)
        }) { (error) in
            print(error?.localizedDescription ?? "error")
            complete(false)
        }
    }
    
    func fetchAllData(complete:@escaping ([Person]?) -> Void) {
        self.database.backgroundOperation({ (context, _) in
            let request = FetchRequest<Person>(context).sorted(with: "name", ascending: true)
            let result = try? context.fetch(request)
            complete(result)
        }) { (hasError) in
            print(hasError?.localizedDescription ?? "error")
            complete(nil)
        }
    }
    
    func fetchInMainThread(name: String) -> Person? {
        let request = FetchRequest<Person>(database.context).sorted(with: "name", ascending: true)
        let filter = NSPredicate(format: "name = %@", name)
        let result = try? database.context.fetch(request.filtered(with: filter))
        return result?.first
    }
    
    func deleteInMainThread(name: String) throws {
        if let result = fetchInMainThread(name: name) {
            try database.context.remove(result)
            try database.context.saveData()
        }
    }

}


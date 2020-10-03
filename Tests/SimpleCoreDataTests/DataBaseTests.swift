//
//  DataBaseTests.swift
//  DataBaseTests
//
//  Created by wang animeng on 2018/8/18.
//  Copyright © 2018年 Friends. All rights reserved.
//

import XCTest
import DataBase

extension Person:Entity {
    public var primeKey: String {
        return self.uid ?? ""
    }
}

class DataBaseTests: XCTestCase {
    let timeout: TimeInterval = 30.0
    var observal:CoreDataObservable<Person>?
    let database = CoreDataStorage(objectModelName: "test", fileName: "hehe",bundle:Bundle(for: DataBaseTests.self))
    
    override func setUp() {
        super.setUp()
        observal = CoreDataObservable<Person>(context: database.mainContext)
        
        observal?.observer({ (persons) in
            for person in persons {
                switch person{
                case .insert(let content):
                    print(content)
                default:
                    break
                }
            }
        })
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSubThreadCreate() {
        self.database.backgroundOperation({ (context, save) in
            let user:Person = try! context.create()
            user.name = "Lucas"
            user.uid = UUID().uuidString
            save()
        }) { (error) in
            
        }
    }
    
    func testSubThreadFetch() {
        let expectation = self.expectation(description: "exception complete")
        self.database.backgroundOperation({ (context, _) in
            let request = FetchRequest<Person>(context)
            request.sorted(with: "name", ascending: true)
            let result = try? context.fetch(request)
            print(result)
            expectation.fulfill()
        }) { (hasError) in
            XCTFail(hasError?.localizedDescription ?? "")
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testFetch() {
        let request = FetchRequest<Person>(database.mainContext)
        request.sorted(with: "name", ascending: true)
        let result = try? database.mainContext.fetch(request)
        print(request)
    }
    
    func testMainThreadCreate() {
        let user:Person = try! self.database.mainContext.create()
        user.name = "Anna"
        user.uid = UUID().uuidString
        try? self.database.mainContext.saveData()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

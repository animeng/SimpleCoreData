//
//  NSManagedObjectContext.swift
//  DataBase
//
//  Created by wang animeng on 2018/8/16.
//  Copyright © 2018年 Friends. All rights reserved.
//

import Foundation
import CoreData

func synchronized<T>(_ lock: Any, _ body: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try body()
}

extension NSManagedObject:Entity {
    @objc open var primeKey: String {
        // implement method in subclass
        return "\(objectID)"
    }
    
    @objc open func manageObjectDidCreate() {
        // implement method in subclass
    }
    
    open class var entityName: String? {
        return NSStringFromClass(self).components(separatedBy: ".").last
    }
    
    @objc open class func managerKeyMaps() -> [String : String]? {
        return nil
    }
    
    open func syncJson(_ jsonObject:[String:Any]) {
        var managerProperties:[String : String] = [:]
        for property in entity.properties {
            managerProperties[property.name] = property.name
        }
        if let map = type(of: self).managerKeyMaps() {
            managerProperties.merge(map) { (_, new) in new }
        }
        
        for (managerKey, jsonKey) in managerProperties {
            let jsonkeys = jsonKey.components(separatedBy: ".")
            var jsonValue:Any?
            var tempJson = jsonObject
            for (index,key) in jsonkeys.enumerated() {
                if let temp = tempJson[key] as? [String:Any],index < (jsonkeys.count - 1) {
                    tempJson = temp
                }
                else {
                    jsonValue = tempJson[key]
                }
            }
            
            if let value = jsonValue {
                setValue(value, forKey: managerKey)
            }
        }
    }
    
    open class func create(context:Context,
                           entityName:String,
                           by jsonObject: [String : Any]) -> NSManagedObject? {
        if let manageContext = context as? NSManagedObjectContext {
            let result = NSEntityDescription.insertNewObject(forEntityName: entityName, into: manageContext)
            result.syncJson(jsonObject)
            result.manageObjectDidCreate()
            return result
        }
        return nil
    }
    
}

extension NSManagedObjectContext: Context {
    
    func parentSave() throws {
        var saveError: Error?
        if let parent = self.parent {
            parent.perform {
                if parent.hasChanges {
                    do {
                        try parent.save()
                    }
                    catch {
                        saveError = error
                    }
                }
            }
        }
        if let hasError = saveError {
            throw hasError
        }
    }
    
    public func saveData() throws {
        var saveError: Error?
        self.perform { [weak self] in
            guard let `self` = self else { return }
            if self.hasChanges {
                do {
                    try self.save()
                    try self.parentSave()
                }
                catch {
                    saveError = error
                }
            }
        }
        if let hasError = saveError {
            throw hasError
        }
    }
    
    func coreDataFetchRequest<T: Entity>(_ request: FetchRequest<T>) throws -> NSFetchRequest<NSFetchRequestResult> {
        guard let entity = T.self as? NSManagedObject.Type,
            let entityName = entity.entityName
            else { throw StorageError.invalidType }
        let fetchRequest: NSFetchRequest =  NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = request.predicate
        fetchRequest.sortDescriptors = request.sortDescriptor.map {[$0]}
        fetchRequest.fetchOffset = request.fetchOffset
        fetchRequest.fetchLimit = request.fetchLimit
        return fetchRequest
    }
    
    public func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T] {
        let fetchRequest: NSFetchRequest = try coreDataFetchRequest(request)
        let results = try self.fetch(fetchRequest)
        let typedResults = results.compactMap { $0 as? T }
        return typedResults
    }
    
    public func asynFetch<T>(_ request: FetchRequest<T>, complete: (([T]) -> Void)? = nil) where T : Entity {
        do {
            let fetchRequest: NSFetchRequest = try coreDataFetchRequest(request)
            let asynFetch = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (result) in
                if let result = result.finalResult as? [T] {
                    complete?(result)
                } else {
                    complete?([])
                }
            }
            try execute(asynFetch)
        } catch  {
            complete?([])
        }
    }
    
    public func insert<T: Entity>(_ entity: T) throws {}
    
    public func create<T: Entity>() throws -> T {
        guard let entity = T.self as? NSManagedObject.Type,
                let entityName = entity.entityName
        else { throw StorageError.invalidType }
        let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self)
        if let inserted = object as? T {
            return inserted
        }
        else {
            throw StorageError.invalidType
        }
    }
    
    public func remove<T: Entity>(_ objects: [T]) throws {
        for object in objects {
            guard let object = object as? NSManagedObject else { continue }
            self.delete(object)
        }
        try saveData()
    }
    
    public func removeAll<T>(_ type: T.Type) throws where T : Entity {
        guard let entity = T.self as? NSManagedObject.Type,
            let entityName = entity.entityName
        else { throw StorageError.invalidType }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try execute(deleteRequest)
        try saveData()
    }
    
}

extension NSManagedObjectContext {
    
    func observe(inMainThread mainThread: Bool, saveNotification: @escaping (_ notification: Notification) -> Void) {
        let queue: OperationQueue = mainThread ? OperationQueue.main : OperationQueue()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave, object: self, queue: queue, using: saveNotification)
    }
    
    func observeToGetPermanentIDsBeforeSaving() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextWillSave, object: self, queue: nil, using: { [weak self] (notification) in
            guard let s = self else {
                return
            }
            if s.insertedObjects.count == 0 {
                return
            }
            
            _ = try? s.obtainPermanentIDs(for: Array(s.insertedObjects))
        })
    }
    
}
//
//  DBIocManager.swift
//  
//
//  Created by Munger on 2020/8/30.
//


import Foundation

let lock = NSConditionLock(condition: 1)

func synchronized<T>(_ lock: Any, _ body: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer {
        objc_sync_exit(lock)
    }
    return try body()
}

@available(iOS 13.0.0, *)
public class DBFactory {
    
    static var manager = DBFactory()
    
    var containers:[String:CoreDataStorage] = [:]
    
    static public func close(dbName:String) throws {
        _ = synchronized(lock, { () -> CoreDataStorage? in
            DBFactory.manager.containers.removeValue(forKey: dbName)
        })
    }
    
    static public func openDB(objectModelName: String, dbName: String) -> some Storage {
        if let db = DBFactory.manager.containers[dbName] {
            return db
        }
        let result = synchronized(lock, { () -> CoreDataStorage in
            let db = CoreDataStorage(objectModelName: objectModelName, fileName: dbName)
            DBFactory.manager.containers[dbName] = db
            return db
        })
        return result;
    }
    
}

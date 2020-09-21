/**
MIT License
Copyright (c) 2020 munger
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

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
    
    var observableList:[String:Any] = [:]
    
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
    
    static public func addObserver<T:Entity,S:Storage>(_ storage:S, type:T.Type) -> some DBObservable {
        let entityName = String(describing: type.self)
        let key:String = storage.storeFileName + entityName
        
        if let observable = DBFactory.manager.observableList[key] {
            return observable as! CoreDataObservable<T>
        }
        let result = synchronized(lock, { () -> CoreDataObservable<T> in
            let observal = CoreDataObservable<T>(context:storage.context)
            DBFactory.manager.observableList[key] = observal
            return observal
        })
        return result
    }
    
    static public func removeObserver<T:Entity,S:Storage>(_ storage:S, type:T.Type) {
        let entityName = String(describing: type.self)
        let key:String = storage.storeFileName + entityName
        
        _ = synchronized(lock, { 
            DBFactory.manager.observableList.removeValue(forKey: key)
        })
    }
    
}

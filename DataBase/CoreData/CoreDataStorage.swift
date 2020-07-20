//
//  CoreDataStorage.swift
//  DataBase
//
//  Created by wang animeng on 2018/8/16.
//  Copyright © 2018年 Friends. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataStorage: Storage {
    
    public var storeFileName: String
    /// 一般需要操作ui的时候建议使用maincontext获取数据
    public var mainContext: Context!
    /// 后台线程的context，一般修改，删除，插入保存数据时候，建议使用这个context
    private var privateContext:Context!
    private var saveContext: Context!
    private var objectModel:NSManagedObjectModel!
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    private var persistentStore: NSPersistentStore!
    
    required public init(objectModelName:String,fileName:String,bundle:Bundle? = Bundle.main) {
        self.storeFileName = fileName
        self.objectModel = initModel(name: objectModelName,bundle:bundle)
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        self.persistentStore = initPersistenStore()
        self.saveContext = initContext(concurrencyType: .privateQueueConcurrencyType)
        let parentContext = self.saveContext as! NSManagedObjectContext
        self.mainContext = initContext(concurrencyType: .mainQueueConcurrencyType,parent: parentContext)
        self.privateContext = initContext(concurrencyType: .privateQueueConcurrencyType, parent: parentContext)
        (privateContext as! NSManagedObjectContext).observe(inMainThread: true) {[weak self] (notification) in
            if let context = self?.mainContext as? NSManagedObjectContext {
                context.mergeChanges(fromContextDidSave: notification)
            }
        }
    }
    
    deinit {
        #if DEBUG
        print("coredata deinit")
        #endif
    }
    
    public var context: Context!{
        return mainContext
    }
    
    func documentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths[0]
    }
    
    public func storePath() -> URL {
        return URL(fileURLWithPath: documentsDirectory()).appendingPathComponent(storeFileName)
    }
    
    public func backgroundOperation(_ operation: @escaping (_ context:Context, _ save:@escaping () -> Void) -> (), completion: ((Error?) -> Void)? = nil) {
        let context: NSManagedObjectContext = self.privateContext as! NSManagedObjectContext
        var _error: Error!
        context.perform {
            operation(context, { () -> Void in
                do {
                    try context.save()
                }
                catch {
                    _error = error
                }
                completion?(_error)
            })
        }
    }
    
}

extension CoreDataStorage {
    
    func initModel(name:String,bundle:Bundle? = Bundle.main) -> NSManagedObjectModel {
        guard let modelURL = bundle?.url(forResource: name, withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        return mom
    }
    
    func initPersistenStore() -> NSPersistentStore {
        var sqliteOptions: [String: String] = [String: String] ()
        sqliteOptions["journal_mode"] = "DELETE"
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption:sqliteOptions
            ] as [String : Any]
        do {
            return try persistentStoreCoordinator
                .addPersistentStore(ofType: NSSQLiteStoreType,
                                    configurationName: nil,
                                    at: storePath(),
                                    options: options)
        } catch {
            fatalError("Error migrating store: \(error)")
        }
    }
    
    func initContext(concurrencyType: NSManagedObjectContextConcurrencyType,
                     parent:NSManagedObjectContext? = nil) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: concurrencyType)
        if let parent = parent {
            context.parent = parent
        } else {
            context.persistentStoreCoordinator = persistentStoreCoordinator
        }
        context.observeToGetPermanentIDsBeforeSaving()
        return context
    }
    
}

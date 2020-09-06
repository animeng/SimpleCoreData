//
//  CoreDataObserval.swift
//  DataBase
//
//  Created by wang animeng on 2018/8/17.
//  Copyright © 2018年 Friends. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataObservable<T:Entity>:NSObject,DBObservable,NSFetchedResultsControllerDelegate {
    
    public typealias Elment = T
    internal var observer: (([StorageDataChange<T>]) -> Void)?
    internal let fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>
    private var batchChanges: [StorageDataChange<T>] = []
    private var needFetch = false
    
    deinit {
        #if DEBUG
        print("coredata change deinit")
        #endif
    }
    
    required public init(context: Context) {
        guard let entity = T.self as? NSManagedObject.Type,
            let entityName = entity.entityName,
            let managerContext = context as? NSManagedObjectContext
        else {
            fatalError("is not NSManagedObjectContext")
        }
        
        let fetchRequest: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.sortDescriptors = []
        fetchRequest.fetchBatchSize = 1
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managerContext, sectionNameKeyPath: nil, cacheName: nil)
        super.init()
        self.fetchedResultsController.delegate = self
    }
    
    public init(context: Context,request:FetchRequest<T>) throws {
        guard let managerContext = context as? NSManagedObjectContext
            else { throw StorageError.invalidContext }
        let fetch = try managerContext.coreDataFetchRequest(request)
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: managerContext, sectionNameKeyPath: nil, cacheName: nil)
        self.needFetch = true
        super.init()
        self.fetchedResultsController.delegate = self
    }
    
    public func observer(_ closure: @escaping ([StorageDataChange<Elment>]) -> Void) {
        assert(self.observer == nil, "Observable can be observed only once")
        self.observer = closure
        do {
            try self.fetchedResultsController.performFetch()
            if needFetch {
                if let result = self.fetchedResultsController.fetchedObjects as? [T] {
                    let batchs = result.map { StorageDataChange.fetch($0) }
                    self.batchChanges.append(contentsOf: batchs)
                    if batchChanges.count > 0 {
                        self.observer?(batchChanges)
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            self.batchChanges.append(.delete(anObject as! T))
        case .insert:
            self.batchChanges.append(.insert(anObject as! T))
        case .update,.move:
            self.batchChanges.append(.update(anObject as! T))
        default: break
        }
    }
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.batchChanges = []
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if batchChanges.count > 0 {
            self.observer?(batchChanges)
        }
    }
}

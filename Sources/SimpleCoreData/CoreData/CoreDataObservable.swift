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

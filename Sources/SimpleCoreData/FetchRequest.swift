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

public struct FetchRequest<T: Entity>: Equatable {
    
    public let sortDescriptor: NSSortDescriptor?
    public let predicate: NSPredicate?
    public let fetchOffset: Int
    public let fetchLimit: Int
    let context: Context
    
    public init(_ context: Context, sortDescriptor: NSSortDescriptor? = nil, predicate: NSPredicate? = nil, fetchOffset: Int = 0, fetchLimit: Int = 0) {
        self.context = context
        self.sortDescriptor = sortDescriptor
        self.predicate = predicate
        self.fetchOffset = fetchOffset
        self.fetchLimit = fetchLimit
    }
    
    public func fetch() throws -> [T] {
        return try context.fetch(self)
    }
    
    public func asynfetch(_ complete:@escaping (([T]) -> Void)) {
        context.asynFetch(self, complete: { (result) in
            complete(result)
        })
    }
    
    public func filtered(with predicate: NSPredicate) -> FetchRequest<T> {
        return self.request(withPredicate: predicate)
    }
    
    public func filtered(with key: String, equalTo value: String) -> FetchRequest<T> {
        return self.request(withPredicate: NSPredicate(format: "\(key) == %@", value))
    }
    
    public func filtered(with key: String, in value: [String]) -> FetchRequest<T> {
        return self.request(withPredicate: NSPredicate(format: "\(key) IN %@", value))
    }
    
    public func filtered(with key: String, notIn value: [String]) -> FetchRequest<T> {
        return self.request(withPredicate: NSPredicate(format: "NOT (\(key) IN %@)", value))
    }
    
    public func sorted(with sortDescriptor: NSSortDescriptor) -> FetchRequest<T> {
        return self.request(withSortDescriptor: sortDescriptor)
    }
    
    public func sorted(with key: String?, ascending: Bool, comparator cmptr: @escaping Comparator) -> FetchRequest<T> {
        return self.request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending, comparator: cmptr))
    }
    
    public func sorted(with key: String?, ascending: Bool) -> FetchRequest<T> {
        return self.request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending))
    }
    
    public func sorted(with key: String?, ascending: Bool, selector: Selector) -> FetchRequest<T> {
        return self.request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending, selector: selector))
    }
    
    func request(withPredicate predicate: NSPredicate) -> FetchRequest<T> {
        return FetchRequest<T>(context, sortDescriptor: sortDescriptor, predicate: predicate)
    }
    
    func request(withSortDescriptor sortDescriptor: NSSortDescriptor) -> FetchRequest<T> {
        return FetchRequest<T>(context, sortDescriptor: sortDescriptor, predicate: predicate)
    }
    
}

public func == <T>(lhs: FetchRequest<T>, rhs: FetchRequest<T>) -> Bool {
    return lhs.sortDescriptor == rhs.sortDescriptor &&
        lhs.predicate == rhs.predicate
}

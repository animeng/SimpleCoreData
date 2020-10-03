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

public protocol DBObservable {
    associatedtype Elment:Entity
    init(context:Context)
    func observer(_ closure:@escaping ([StorageDataChange<Elment>]) -> Void) -> Void
}

public enum StorageDataChange<T:Entity> {
    
    case update(T)
    case delete(T)
    case insert(T)
    case fetch(T)
    
    public func object() -> T {
        switch self {
        case .update(let object): return object
        case .delete(let object): return object
        case .insert(let object): return object
        case .fetch(let object): return object
        }
    }
    
    public var isDeletion: Bool {
        if case .delete = self {
            return true
        }
        return false
    }
    
    public var isUpdate: Bool {
        if case .update = self {
            return true
        }
        return false
    }
    
    public var isInsertion: Bool {
        if case .insert = self {
            return true
        }
        return false
    }
    
    public var isFetch: Bool {
        if case .fetch = self {
            return true
        }
        return false
    }
    
}

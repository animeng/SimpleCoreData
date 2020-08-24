//
//  StorageDataChange.swift
//  DataBase
//
//  Created by wang animeng on 2018/8/16.
//  Copyright © 2018年 Friends. All rights reserved.
//

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

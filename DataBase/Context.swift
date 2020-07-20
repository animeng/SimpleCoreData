//
//  Context.swift
//  DataBase
//
//  Created by wang animeng on 2018/8/16.
//  Copyright © 2018年 Friends. All rights reserved.
//

import Foundation

public protocol Context {
    func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T]
    func asynFetch<T:Entity>(_ request: FetchRequest<T>,complete:(([T]) -> Void)?)
    func insert<T: Entity>(_ entity: T) throws
    func create<T: Entity>() throws -> T
    func remove<T: Entity>(_ objects: [T]) throws
    func remove<T: Entity>(_ object: T) throws
    func removeAll<T: Entity>(_ type:T.Type) throws
    func saveData() throws
}

public extension Context {
    
    func remove<T: Entity>(_ object: T) throws {
        return try self.remove([object])
    }
    
}

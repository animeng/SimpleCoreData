//
//  Stroage.swift
//  DataBase
//
//  Created by wang animeng on 2018/8/16.
//  Copyright © 2018年 Friends. All rights reserved.
//

import Foundation

public protocol Storage:CustomStringConvertible,Equatable {
    
    var storeFileName:String {get set}
    
    func storePath() -> URL
    
    var context: Context! { get }
    
    func backgroundOperation(_ operation: @escaping (_ context: Context, _ save: @escaping () -> Void) -> (), completion:((Error?) -> Void)?)
}

public func == <T:Storage>(lhs: T, rhs: T) -> Bool {
    return lhs.storeFileName == rhs.storeFileName
}

extension Storage {
    public var description: String {
        get {
            return "Store: \(self.storePath())"
        }
    }
}

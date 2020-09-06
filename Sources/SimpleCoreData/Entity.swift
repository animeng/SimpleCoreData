//
//  Entity.swift
//  DataBase
//
//  Created by wang animeng on 2018/8/16.
//  Copyright © 2018年 Friends. All rights reserved.
//

import Foundation

public protocol Entity:Equatable {
    var primeKey:String {get}
    func objectDidCreate()
}

public func == <T:Entity>(lhs: T, rhs: T) -> Bool {
    return lhs.primeKey == rhs.primeKey
}

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

public protocol Context {
    
    func asynFetch<T:Entity>(_ request: FetchRequest<T>,complete:(([T]) -> Void)?)
    
    func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T]
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

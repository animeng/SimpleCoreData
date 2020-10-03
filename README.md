# SimpleCoreData

Core Data is an object graph and persistence framework provided by Apple in the macOS and iOS operating systems. It allows data organized by the relational entity–attribute model to be serialized into XML, binary, or SQLite stores. The data can be manipulated using higher level objects representing entities and their relationships. Core Data manages the serialized version, providing object lifecycle and object graph management, including persistence. Core Data interfaces directly with SQLite, insulating the developer from the underlying SQL.

But Core Data is not easy for beginners. I design the framework to simplify these core data operations. You only use simple API to storage data in database.

## Design

The framework design dabase interface by Protocol-oriented programming. Follow the design pattern of interface dependence.The framework is easy to replace with realm、FMDB... for realisation layer by Inversion of Control.

<!-- ![UML1](https://mengtnt.com/images/simple-coredata.jpg) -->

<img src="https://mengtnt.com/images/simple-coredata.jpg" alt="uml" style="width:400px;">

## Installation

[Swift package](https://swift.org/package-manager/)

### xcode

Add swift package by xcode. Follow apple develop document for [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

### Terminal

#### Start

``` shell
 swift package init --type executable
```

modify `Package.swift` file

``` swift
let package = Package(
    name: "YourPorject",
    products: [
        .executable(name: "YourPorject", targets: ["YourPorject"]),
    ],
    dependencies: [
        // "from" is git tag
         .package(url: "https://github.com/animeng/SimpleCoreData.git",from:"0.0.2") 
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        .target(
            name: "YourPorject",
            dependencies: ["SimpleCoreData"]),
    ]
)
```

#### compile

``` shell
swift build
```

#### Excute

``` shell
swift run
```

## Usage

### Create

First you need create `YourDatabase.xcdatamodeld` file and use the code to create dababase.

``` swift
let database = CoreDataStorage(objectModelName: "YourDatabase", fileName: "testDatabase",bundle:nil)
```

if you use the framework only for ios 13.0 and you can use it by follows.

``` swift
let database:some Storage = DBFactory.openDB(objectModelName: "YourDatabase", dbName: "testDatabase")
```

Detailed usage for reference SimpleCoredataExample

### Entity

You need add entity in coredata model. Add `Person` model and select model to codegen `class definiton`

``` swift
extension Person {
    public override var primeKey: String {
        return self.uid ?? ""
    }
}
```

Then you can insert data for `Person` model

``` swift
let user:Person = try! self.database.context.create()
user.name = "Andy"
database.context.saveData()
```

### Fetch Data

Fetch data from main thread

``` swift 
let request = FetchRequest<Person>(database.context).sorted(with: "name", ascending: true)
let filter = NSPredicate(format: "name = %@", name)
let result = try? database.context.fetch(request.filtered(with: filter))
print(result?.first)
```

Fetch data from background thread

``` swift
self.database.backgroundOperation({ (context, _) in
    let request = FetchRequest<Person>(context).sorted(with: "name", ascending: true)
    let result = try? context.fetch(request)
    print(result)
}) { (hasError) in
    print(hasError?.localizedDescription ?? "error")
}
```

### Delete Data

First you need query data by condition and `remove` data by follows

``` swift
if let result = fetchInMainThread(name: name) {
    try database.context.remove(result)
    try database.context.saveData()
}
```

### Observal

You can Observer data changed by simple API.

``` swift
let observal:CoreDataObservable<Person>? = CoreDataObservable<Person>(context: database.mainContext)   
observal?.observer({ (persons) in
    for person in persons {
        switch person{
        case .insert(let content):
            print(content)
        default:
            break
        }
    }
})
```

Great than or equal to iOS 13.0

``` swift
let observal = DBFactory.addObserver(database,type:Person.self)
observal.observer { (persons) in
    for person in persons {
        switch person{
        case .insert(let content):
            print("Insert: \(content)")
        case .delete(let content):
            print("Delete: \(content)")
        case .update(let content):
            print("Update: \(content)")
        default:
            break
        }
    }
}
```

## Example

You can open the example and refer to the explanation. The file structure is as follows:

```
SimpleCoreDataExample
├── Sources
│   └── SimpleCoreDataExample
│       ├── AppDelegate.swift
│       ├── SceneDelegate.swift
│       └── ViewController.swift
└── Package.swift
```

## Problem

The framework has some issue and cann't be solved. The coredata object can not use relation object.
Entity method `syncDictionary` only analysis simple object and cann't sync associate relation object. For example:

```
department:
{"name":"IT","office":"3-403"}

person:
{"name":"Lucas","job":"engineer","Department":{"name":"IT","office":"3-403"}}
```
use 'syncDictionary' and cann't analysis Department in person

## Contributors

@munger

## License

[MIT](http://opensource.org/licenses/MIT)

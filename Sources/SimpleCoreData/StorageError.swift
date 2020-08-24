import Foundation

public indirect enum StorageError: String, Error {
    case invalidContext = "context is not coredata context"
    case invalidType = "object is not coredata"
    case databaseNotOpen = "database is not open"
}

extension StorageError: LocalizedError {
    public var errorDescription: String? {
        return rawValue
    }
}

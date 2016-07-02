import Foundation

internal enum CoreDataChange<T> {
    
    case update(Int, T)
    case insert(Int, T)
    case delete(Int, T)
    
    func object() -> T {
        switch self {
        case .update(_, let object): return object
        case .delete(_, let object): return object
        case .insert(_, let object): return object
        }
    }
    
    func index() -> Int {
        switch self {
        case .update(let index, _): return index
        case .delete(let index, _): return index
        case .insert(let index, _): return index
        }
    }
    
    func isDeletion() -> Bool {
        switch self {
        case .delete(_): return true
        default: return false
        }
    }
    
    func isUpdate() -> Bool {
        switch self {
        case .update(_): return true
        default: return false
        }
    }
    
    func isInsertion() -> Bool {
        switch self {
        case .insert(_): return true
        default: return false
        }
    }
    
}

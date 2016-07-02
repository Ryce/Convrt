import CoreData
import Foundation

public extension CoreData {
    
    public enum Store {
        
        case named(String)
        case url(Foundation.URL)
        
        public func path() -> Foundation.URL {
            switch self {
            case .url(let url): return url
            case .named(let name):
                return try! Foundation.URL(fileURLWithPath: documentsDirectory()).appendingPathComponent(name)
            }
        }
        
    }
}


// MARK: - Store extension (CustomStringConvertible)

extension CoreData.Store: CustomStringConvertible {
    
    public var description: String {
        get {
            return "CoreData Store: \(self.path())"
        }
    }
    
}


// MARK: - Store Extension (Equatable)

extension CoreData.Store: Equatable {}

public func == (lhs: CoreData.Store, rhs: CoreData.Store) -> Bool {
    return lhs.path() == rhs.path()
}

import Foundation
import CoreData

public extension CoreData {

    public enum Options {
        case `default`
        case migration
    
        func dict() -> [NSObject: AnyObject] {
            switch self {
            case .default:
                var sqliteOptions: [String: String] = [String: String] ()
                sqliteOptions["journal_mode"] = "DELETE"
                var options: [NSObject: AnyObject] = [NSObject: AnyObject] ()
                options[NSMigratePersistentStoresAutomaticallyOption] = NSNumber(value: true)
                options[NSInferMappingModelAutomaticallyOption] = NSNumber(value: false)
                options[NSSQLitePragmasOption] = sqliteOptions
                return options
            case .migration:
                var sqliteOptions: [String: String] = [String: String] ()
                sqliteOptions["journal_mode"] = "DELETE"
                var options: [NSObject: AnyObject] = [NSObject: AnyObject] ()
                options[NSMigratePersistentStoresAutomaticallyOption] = NSNumber(value: true)
                options[NSInferMappingModelAutomaticallyOption] = NSNumber(value: true)
                options[NSSQLitePragmasOption] = sqliteOptions
                return options
            }
        }
        
    }
}

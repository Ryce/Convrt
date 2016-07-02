import Foundation
import CoreData

extension CoreData {

    enum ContextParent {
        case coordinator(NSPersistentStoreCoordinator)
        case context(NSManagedObjectContext)
    }
    
}

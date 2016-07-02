import CoreData
import Foundation

public extension CoreData {
    
    public enum Error: ErrorProtocol {
        case invalidModel(CoreData.ObjectModel)
        case persistenceStoreInitialization
    }
    
}

import Foundation
import CoreData

public extension CoreData {

    public enum ObjectModel {
        case named(String, Bundle)
        case merged([Bundle]?)
        case url(Foundation.URL)
        
        func model() -> NSManagedObjectModel? {
            switch self {
            case .merged(let bundles):
                return NSManagedObjectModel.mergedModel(from: bundles)
            case .named(let name, let bundle):
                return NSManagedObjectModel(contentsOf: bundle.urlForResource(name, withExtension: "momd")!)
            case .url(let url):
                return NSManagedObjectModel(contentsOf: url)
            }
            
        }
        
    }
}


// MARK: - ObjectModel Extension (CustomStringConvertible)

extension CoreData.ObjectModel: CustomStringConvertible {
    public var description: String {
        get {
            switch self {
            case .named(let name): return "NSManagedObject model named: \(name) in the main NSBundle"
            case .merged(_): return "Merged NSManagedObjec models in the provided bundles"
            case .url(let url): return "NSManagedObject model in the URL: \(url)"
            }
        }
    }
}


// MARK: - ObjectModel Extension (Equatable)

extension CoreData.ObjectModel: Equatable {}

public func == (lhs: CoreData.ObjectModel, rhs: CoreData.ObjectModel) -> Bool {
    return lhs.model() == rhs.model()
}

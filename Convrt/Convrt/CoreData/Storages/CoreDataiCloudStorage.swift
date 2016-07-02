import Foundation
import CoreData

public class CoreDataiCloudStorage: Storage {
    
    // MARK: - Attributes
    
    internal let store: CoreData.Store
    internal var objectModel: NSManagedObjectModel! = nil
    internal var persistentStore: NSPersistentStore! = nil
    internal var persistentStoreCoordinator: NSPersistentStoreCoordinator! = nil
    internal var rootSavingContext: NSManagedObjectContext! = nil

    
    // MARK: - Storage
    
    public var description: String {
        get {
            return "CoreDataiCloudStorage"
        }
    }
    public var type: StorageType = .coreData
    
    public var mainContext: Context!
    
    public var saveContext: Context! {
        get {
            let context = cdContext(withParent: .context(self.rootSavingContext), concurrencyType: .privateQueueConcurrencyType, inMemory: false)
            context.observe(inMainThread: true) { [weak self] (notification) -> Void in
                (self?.mainContext as? NSManagedObjectContext)?.mergeChanges(fromContextDidSave: notification)
            }
            return context
        }
    }
    
    public var memoryContext: Context! {
        get {
            let context =  cdContext(withParent: .context(self.rootSavingContext), concurrencyType: .privateQueueConcurrencyType, inMemory: true)
            return context
        }
    }
    
    public func operation<T>(_ operation: (context: Context, save: () -> Void) throws -> T) throws -> T {
        let context: NSManagedObjectContext = (self.saveContext as? NSManagedObjectContext)!
        var _error: ErrorProtocol!
        
        var returnedObject: T!
        
        context.performAndWait {
            do {
                returnedObject = try operation(context: context, save: { () -> Void  in
                    do {
                        try context.save()
                    }
                    catch {
                        _error = error
                    }
                    if self.rootSavingContext.hasChanges {
                        self.rootSavingContext.performAndWait {
                            do {
                                try self.rootSavingContext.save()
                            }
                            catch {
                                _error = error
                            }
                        }
                    }
                })
            }
            catch {
                _error = error
            }
        }
        if let error = _error {
            throw error
        }
        
        return returnedObject
    }
    
    public func removeStore() throws {
        try FileManager.default().removeItem(at: store.path() as URL)
    }
    
    
    // MARK: - Init
    
    public convenience init(model: CoreData.ObjectModel, iCloud: ICloudConfig) throws {
        try self.init(model: model, iCloud: iCloud, versionController: VersionController())
    }
    
    internal init(model: CoreData.ObjectModel, iCloud: ICloudConfig, versionController: VersionController) throws {
        self.objectModel = model.model()!
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        let res = try! cdiCloudInitializeStore(storeCoordinator: persistentStoreCoordinator, iCloud: iCloud)
        self.store = res.0
        self.persistentStore = res.1
        self.rootSavingContext = cdContext(withParent: .coordinator(self.persistentStoreCoordinator), concurrencyType: .privateQueueConcurrencyType, inMemory: false)
        self.mainContext = cdContext(withParent: .context(self.rootSavingContext), concurrencyType: .mainQueueConcurrencyType, inMemory: false)
        self.observeiCloudChangesInCoordinator()
        versionController.check()
    }
    
    
    // MARK: - Public

#if os(iOS) || os(tvOS) || os(watchOS)
    
    public func observable<T: NSManagedObject where T:Equatable>(_ request: Request<T>) -> RequestObservable<T> {
        return CoreDataObservable(request: request, context: self.mainContext as! NSManagedObjectContext)
    }
    
#endif
    
    // MARK: - Private
    
    private func observeiCloudChangesInCoordinator() {
        NotificationCenter
            .default()
            .addObserver(forName: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object: self.persistentStoreCoordinator, queue: nil) { [weak self] (notification) -> Void in
                self?.rootSavingContext.perform {
                    self?.rootSavingContext.mergeChanges(fromContextDidSave: notification)
                }
            }
    }
    
}

internal func cdiCloudInitializeStore(storeCoordinator: NSPersistentStoreCoordinator, iCloud: ICloudConfig) throws -> (CoreData.Store, NSPersistentStore?) {
    let storeURL = try! FileManager.default()
        .urlForUbiquityContainerIdentifier(iCloud.ubiquitousContainerIdentifier)!
        .appendingPathComponent(iCloud.ubiquitousContentURL)
    var options = CoreData.Options.migration.dict()
    options[NSPersistentStoreUbiquitousContentURLKey] = storeURL
    options[NSPersistentStoreUbiquitousContentNameKey] = iCloud.ubiquitousContentName
    let store = CoreData.Store.url(storeURL)
    return try (store, cdAddPersistentStore(store, storeCoordinator: storeCoordinator, options: options))
}

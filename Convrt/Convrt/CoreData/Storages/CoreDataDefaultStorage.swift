import Foundation
import CoreData

public class CoreDataDefaultStorage: Storage {
    
    // MARK: - Attributes
    
    internal let store: CoreData.Store
    internal var objectModel: NSManagedObjectModel! = nil
    internal var persistentStore: NSPersistentStore! = nil
    internal var persistentStoreCoordinator: NSPersistentStoreCoordinator! = nil
    internal var rootSavingContext: NSManagedObjectContext! = nil

    
    // MARK: - Storage conformance
    
    public var description: String {
        get {
            return "CoreDataDefaultStorage"
        }
    }
    
    public var type: StorageType = .coreData
    public var mainContext: Context!
    private var _saveContext: Context!
    public var saveContext: Context! {
        if let context = self._saveContext {
            return context
        }
        let _context = cdContext(withParent: .context(self.rootSavingContext), concurrencyType: .privateQueueConcurrencyType, inMemory: false)
        _context.observe(inMainThread: true) { [weak self] (notification) -> Void in
            (self?.mainContext as? NSManagedObjectContext)?.mergeChanges(fromContextDidSave: notification)
        }
        self._saveContext = _context
        return _context
    }
    public var memoryContext: Context! {
        let _context =  cdContext(withParent: .context(self.rootSavingContext), concurrencyType: .privateQueueConcurrencyType, inMemory: true)
        return _context
    }
    
    public func operation<T>(_ operation: (context: Context, save: () -> Void) throws -> T) throws -> T {
        let context: NSManagedObjectContext = self.saveContext as! NSManagedObjectContext
        var _error: ErrorProtocol!
        
        var returnedObject: T!
        context.performAndWait {
            do {
                returnedObject = try operation(context: context, save: { () -> Void in
                    do {
                        try context.save()
                    }
                    catch {
                        _error = error
                    }
                    if self.rootSavingContext.hasChanges {
                        self.rootSavingContext.performAndWait({
                            do {
                                try self.rootSavingContext.save()
                            }
                            catch {
                                _error = error
                            }
                        })
                    }
                })
            } catch {
                _error = error
            }
        }
        if let error = _error {
            throw error
        }
        
        return returnedObject
    }

    public func removeStore() throws {
        try FileManager.default.removeItem(at: store.path() as URL)
        _ = try? FileManager.default.removeItem(atPath: "\(store.path().absoluteString)-shm")
        _ = try? FileManager.default.removeItem(atPath: "\(store.path().absoluteString)-wal")

    }
    
    
    // MARK: - Init
    
    public convenience init(store: CoreData.Store, model: CoreData.ObjectModel, migrate: Bool = true) throws {
        try self.init(store: store, model: model, migrate: migrate, versionController: VersionController())
    }
    
    internal init(store: CoreData.Store, model: CoreData.ObjectModel, migrate: Bool = true, versionController: VersionController) throws {
        self.store   = store
        self.objectModel = model.model()!
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        self.persistentStore = try cdInitializeStore(store, storeCoordinator: persistentStoreCoordinator, migrate: migrate)
        self.rootSavingContext = cdContext(withParent: .coordinator(self.persistentStoreCoordinator), concurrencyType: .privateQueueConcurrencyType, inMemory: false)
        self.mainContext = cdContext(withParent: .context(self.rootSavingContext), concurrencyType: .mainQueueConcurrencyType, inMemory: false)
        versionController.check()
    }
    
    
    // MARK: - Public
    
#if os(iOS) || os(tvOS) || os(watchOS)
    public func observable<T: NSManagedObject where T:Equatable>(_ request: Request<T>) -> RequestObservable<T> {
        return CoreDataObservable(request: request, context: self.mainContext as! NSManagedObjectContext)
    }
#endif
    
}


// MARK: - Internal

internal func cdContext(withParent parent: CoreData.ContextParent?, concurrencyType: NSManagedObjectContextConcurrencyType, inMemory: Bool) -> NSManagedObjectContext {
    var context: NSManagedObjectContext?
    if inMemory {
        context = NSManagedObjectMemoryContext(concurrencyType: concurrencyType)
    }
    else {
        context = NSManagedObjectContext(concurrencyType: concurrencyType)
    }
    if let parent = parent {
        switch parent {
        case .context(let parentContext):
            context!.parent = parentContext
        case .coordinator(let storeCoordinator):
            context!.persistentStoreCoordinator = storeCoordinator
        }
    }
    context!.observeToGetPermanentIDsBeforeSaving()
    return context!
}

internal func cdInitializeStore(_ store: CoreData.Store, storeCoordinator: NSPersistentStoreCoordinator, migrate: Bool) throws -> NSPersistentStore {
    try cdCreateStoreParentPathIfNeeded(store)
    let options = migrate ? CoreData.Options.migration : CoreData.Options.default
    return try cdAddPersistentStore(store, storeCoordinator: storeCoordinator, options: options.dict())
}

internal func cdCreateStoreParentPathIfNeeded(_ store: CoreData.Store) throws {
    if let databaseParentPath = try? store.path().deletingLastPathComponent() {
        try FileManager.default.createDirectory(at: databaseParentPath, withIntermediateDirectories: true, attributes: nil)
    }
}

internal func cdAddPersistentStore(_ store: CoreData.Store, storeCoordinator: NSPersistentStoreCoordinator, options: [NSObject: AnyObject]) throws -> NSPersistentStore {
    
    var addStore: ((store: CoreData.Store,  storeCoordinator: NSPersistentStoreCoordinator, options: [NSObject: AnyObject], cleanAndRetryIfMigrationFails: Bool) throws -> NSPersistentStore)?
    addStore = { (store: CoreData.Store, coordinator: NSPersistentStoreCoordinator, options: [NSObject: AnyObject], retry: Bool) throws -> NSPersistentStore in
        var persistentStore: NSPersistentStore?
        var error: NSError?
        coordinator.performAndWait({ () -> Void in
            do {
                persistentStore = try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: store.path() as URL, options: options)
            }
            catch let _error as NSError {
                error = _error
            }
        })
        if let error = error {
            let isMigrationError = error.code == NSPersistentStoreIncompatibleVersionHashError || error.code == NSMigrationMissingSourceModelError
            if isMigrationError && retry {
                _ = try? cdCleanStoreFilesAfterFailedMigration(store: store)
                _ = try addStore!(store: store, storeCoordinator: coordinator, options: options, cleanAndRetryIfMigrationFails: false)
            }
            else {
                throw error
            }
        }
        else if let persistentStore = persistentStore {
            return persistentStore
        }
        throw CoreData.Error.persistenceStoreInitialization
    }
    return try addStore!(store: store, storeCoordinator: storeCoordinator, options: options, cleanAndRetryIfMigrationFails: true)
}

internal func cdCleanStoreFilesAfterFailedMigration(store: CoreData.Store) throws {
    let rawUrl: String = store.path().absoluteString!
    let shmSidecar: URL = URL(string: rawUrl + "-shm")!
    let walSidecar: URL = URL(string: rawUrl + "-wal")!
    try FileManager.default.removeItem(at: store.path() as URL)
    try FileManager.default.removeItem(at: shmSidecar)
    try FileManager.default.removeItem(at: walSidecar)
}

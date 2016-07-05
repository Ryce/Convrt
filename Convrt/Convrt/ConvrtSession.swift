//
//  ConvrtSession.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit
import Alamofire
import CoreData
import SugarRecord

var genericCurrencyArray: [Currency]? = {
    return nil
//    [Currency("United States Dollar", "USD", "United States of America"),
//     Currency("European Euro", "EUR", "Europe"),
//     Currency("British Pound", "GBP", "Great Britain"),
//     Currency("Japanese Yen", "JPY", "Japan"),
//     Currency("Swiss Franc", "CHF", "Switzerland"),
//     Currency("Canadian Dollar", "CAD", "Canada"),
//     Currency("Australian Dollar", "AUD", "Australia"),
//     Currency("Renminbi", "CNY", "China")]
}()

typealias CurrencyAmount = Double

enum ConvrtError : ErrorType {
    case NoError, ConnectionError, ParseError
}

let klastUpdatedDateKey = "com.ryce.convrt.lastupdateddate"
let kSavedCurrenciesKey = "com.ryce.convrt.savedcurrencies"

class ConvrtSession: NSObject {
    
    lazy var db: CoreDataDefaultStorage = {
        let store = CoreData.Store.Named("cd_basic")
        let bundle = NSBundle(forClass: ConvrtSession.classForCoder())
        let model = CoreData.ObjectModel.Merged([bundle])
        let defaultStorage = try! CoreDataDefaultStorage(store: store, model: model)
        return defaultStorage
    }()
    
    private var _savedCurrencyConfig: [Currency]?
    var savedCurrencyConfiguration: [Currency] {
        get {
            if let savedCurrencyConfig = _savedCurrencyConfig {
                return savedCurrencyConfig
            }
            _savedCurrencyConfig = genericCurrencyArray
            return _savedCurrencyConfig!
        }
        set {
            _savedCurrencyConfig = newValue
        }
    }
    
    private var _savedCurrencyPairs: [CurrencyPair]?
    var savedCurrencyPairs: [CurrencyPair] {
        get {
            if let savedCurrencyPairs = _savedCurrencyPairs {
                return savedCurrencyPairs
            }
            if let persistedCurrencyData = NSUserDefaults.standardUserDefaults().objectForKey(kSavedCurrenciesKey) as? NSData {
                if let persistedCurrencyPairs = NSKeyedUnarchiver.unarchiveObjectWithData(persistedCurrencyData) as? [CurrencyPair] {
                    _savedCurrencyPairs = persistedCurrencyPairs
                    return _savedCurrencyPairs!
                }
            }
            _savedCurrencyPairs = self.generateCurrencyPairs(self.savedCurrencyConfiguration)
            return _savedCurrencyPairs!
        }
        set {
            _savedCurrencyPairs = newValue
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(newValue), forKey: kSavedCurrenciesKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        return formatter
    }()
    
    var selectedCurrencies = [Currency]()
    
    private var innerFullCurrencyList: [Currency]? = nil
    
    func fullCurrenyList() -> [Currency] {
        if let _fullCurrencyList = innerFullCurrencyList {
            return _fullCurrencyList
        }
        let plistPath = NSBundle.mainBundle().pathForResource("currencies", ofType: "plist")!
        let plistArray = NSArray(contentsOfFile: plistPath) as! [AnyObject]
        
        return plistArray.map {
            if let title = $0["title"] as? String, let code = $0["code"] as? String, let country = $0["country"] as? String {
                return try! db.operation({ (context, save) -> Currency in
                    let newCurr: Currency = try! context.new()
                    newCurr.title = title
                    newCurr.code = code
                    newCurr.country = country
                    try! context.insert(newCurr)
                    save()
                    return newCurr
                })
            } else {
                assertionFailure("Parse Error")
                return Currency() // silence error
            }
        }
    }
    
    private var _lastUpdated: NSDate?
    internal(set) var lastUpdated: NSDate {
        get {
            if let lup = self._lastUpdated {
                return lup
            }
            if let date = NSUserDefaults.standardUserDefaults().valueForKey(klastUpdatedDateKey) as? NSDate {
                self._lastUpdated = date
                return self._lastUpdated!
            }
            return NSDate(timeIntervalSinceNow: 0)
        }
        set {
            self._lastUpdated = newValue
            NSUserDefaults.standardUserDefaults().setValue(_lastUpdated, forKey: klastUpdatedDateKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func findCurrencies(from: Currency) -> [CurrencyPair] {
        return self.savedCurrencyPairs.filter { $0.fromCurrency == from }
    }
    
    func addCurrencies(currencies: [CurrencyPair]) {
        for currencyPair in currencies {
            if let index = self.savedCurrencyPairs.indexOf(currencyPair) {
                let object = self.savedCurrencyPairs[index]
                object.merge(currencyPair)
            } else {
                self.savedCurrencyPairs.append(currencyPair)
            }
        }
    }
    
    func generateCurrencyPairs(currencies: [Currency]) -> [CurrencyPair] {
        var currPairs = [CurrencyPair]()
        for fromCurrency in currencies {
            for toCurrency in currencies {
                if fromCurrency != toCurrency {
                    currPairs.append(try! db.operation({ (context, save) -> CurrencyPair in
                        let currencyPair: CurrencyPair = try! context.new()
                        currencyPair.fromCurrency = fromCurrency
                        currencyPair.toCurrency = toCurrency
                        try! context.insert(currencyPair)
                        save()
                        return currencyPair
                    }))
                }
            }
        }
        return currPairs
    }
    
    func updateSavedCurrencyPairs() {
        self.savedCurrencyPairs = self.generateCurrencyPairs(self.savedCurrencyConfiguration)
    }
    
    
    let manager: Manager = Alamofire.Manager.sharedInstance
    let baseURL = "http://query.yahooapis.com/v1/public/yql?q="
    
    func fetchRatesForCurrencies(currencies: [CurrencyPair], completion: (didSucceed: Bool, error: ConvrtError) -> ()) {
        
        let urlString = baseURL + self.constructYQL(currencies)
        manager.request(Method.GET, urlString, parameters: nil, encoding: .URL).responseJSON(completionHandler: { (response) -> Void in
            if response.result.isFailure {
                completion(didSucceed: false, error: ConvrtError.ConnectionError)
                return // BAIL
            }
            let JSON = response.result.value as! [String:AnyObject]
            let objects = JSON["query"] as? NSDictionary
            if let _objects = objects?.valueForKeyPath("results.rate") as? [[String : String]] {
                var newCurrencies = [CurrencyPair]()
                // TODO: update existing objects instead of creating new ones
                for dict in _objects {
                    let nameArray = dict["Name"]?.componentsSeparatedByString("/")
                    let fromCurrency = try! self.db.operation({ (context, save) -> Currency in
                        let newCurr: Currency = try! context.new()
                        newCurr.title = nameArray![0]
                        newCurr.code = nameArray![0]
                        try! context.insert(newCurr)
                        save()
                        return newCurr
                    })

                    let toCurrency = try! self.db.operation({ (context, save) -> Currency in
                        let newCurr: Currency = try! context.new()
                        newCurr.title = nameArray![1]
                        newCurr.code = nameArray![1]
                        try! context.insert(newCurr)
                        save()
                        return newCurr
                    })
                    
                    let rate = dict["Rate"]! as NSString
                    newCurrencies.append(try! self.db.operation({ (context, save) -> CurrencyPair in
                        let currencyPair: CurrencyPair = try! context.new()
                        currencyPair.fromCurrency = fromCurrency
                        currencyPair.toCurrency = toCurrency
                        currencyPair.rate = rate.doubleValue
                        try! context.insert(currencyPair)
                        save()
                        return currencyPair
                    }))
                }
                
                // merge new info into existing array
                self.savedCurrencyPairs = newCurrencies
                
                completion(didSucceed: true, error: ConvrtError.NoError)
            } else {
                completion(didSucceed: false, error: ConvrtError.ParseError)
            }
        })
    }
    
    func constructYQL(currencies: [CurrencyPair]) -> String {
        var constructionString = ""
        let prefix = "select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20%28"
        let suffix = "%29&format=json&env=store://datatables.org/alltableswithkeys"
        
        for (index, pair) in currencies.enumerate() {
            constructionString += "%22" + pair.fromCurrency.code + pair.toCurrency.code + "%22"
            if currencies.count != index + 1 {
                constructionString += ",%20"
            }
        }
        
        return prefix + constructionString + suffix
    }
    
}

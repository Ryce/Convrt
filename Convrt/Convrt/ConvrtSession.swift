//
//  ConvrtSession.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit
import Alamofire

let genericCurrencyArray = [Currency("United States Dollar", "USD", "United States of America"),
    Currency("European Euro", "EUR", "Europe"),
    Currency("British Pound", "GBP", "Great Britain"),
    Currency("Japanese Yen", "JPY", "Japan"),
    Currency("Swiss Franc", "CHF", "Switzerland"),
    Currency("Canadian Dollar", "CAD", "Canada"),
    Currency("Australian Dollar", "AUD", "Australia"),
    Currency("Renminbi", "CNY", "China")]

func genericCurrencyPairs() -> [CurrencyPair] {
    var currPairs = [CurrencyPair]()
    for fromCurrency in genericCurrencyArray {
        for toCurrency in genericCurrencyArray {
            if fromCurrency != toCurrency {
                currPairs.append(CurrencyPair(fromCurrency: fromCurrency, toCurrency: toCurrency))
            }
        }
    }
    return currPairs
}

typealias CurrencyAmount = Double

enum ConvrtError : ErrorType {
    case NoError, ConnectionError, ParseError
}

let klastUpdatedDateKey = "com.ryce.convrt.lastupdateddate"
let kSavedCurrenciesKey = "com.ryce.convrt.savedcurrencies"

class ConvrtSession: NSObject {
    
    class var sharedInstance: ConvrtSession {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: ConvrtSession? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = ConvrtSession()
        }
        return Static.instance!
    }
    
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
            _savedCurrencyPairs = genericCurrencyPairs()
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
    
    var selectedCurrencies = Array<Currency>()
    
    private let fullCurrenyList: Array<Currency> = {
        let plistPath = NSBundle.mainBundle().pathForResource("currencies", ofType: "plist")!
        let plistArray = NSArray(contentsOfFile: plistPath) as! Array<AnyObject>
        
        return plistArray.map {
            if let title = $0["title"] as? String, let code = $0["code"] as? String, let country = $0["country"] as? String {
                return Currency(title, code, country)
            } else {
                assertionFailure("Parse Error")
                return Currency("","","") // silence error
            }
        }
    }()

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

    
    let manager: Manager = Alamofire.Manager.sharedInstance
    let baseURL = "http://query.yahooapis.com/v1/public/yql?q="
    
    func fetchRatesForCurrencies(currencies: Array<CurrencyPair>, completion: (didSucceed: Bool, error: ConvrtError) -> ()) {
        
        let urlString = baseURL + self.constructYQL(currencies)
        manager.request(Method.GET, urlString, parameters: nil, encoding: .URL)
            .responseJSON { (_, _, JSON, error) -> Void in
                
                let objects = JSON?["query"] as? NSDictionary
                if let _objects = objects?.valueForKeyPath("results.rate") as? Array<Dictionary<String, String>> {
                    var newCurrencies = Array<CurrencyPair>()
                    // TODO: update existing objects instead of creating new ones
                    for dict in _objects {
                        let nameArray = dict["Name"]?.componentsSeparatedByString("/")
                        let fromCurrency = Currency(nameArray![0], nameArray![0], "")
                        let toCurrency = Currency(nameArray![1], nameArray![1], "")
                        let rate = dict["Rate"]! as NSString
                        newCurrencies.append(CurrencyPair(fromCurrency: fromCurrency, toCurrency: toCurrency, rate: rate.doubleValue))
                    }
                    
                    // merge new info into existing array
                    self.savedCurrencyPairs = newCurrencies
                    
                    completion(didSucceed: true, error: ConvrtError.NoError)
                } else {
                    completion(didSucceed: false, error: ConvrtError.ParseError)
                }
                
            }
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

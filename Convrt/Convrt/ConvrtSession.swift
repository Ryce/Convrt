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

typealias CurrencyAmount = Double

enum ConvrtError : ErrorProtocol {
    case noError, connectionError, parseError
}

let klastUpdatedDateKey = "com.ryce.convrt.lastupdateddate"
let kSavedCurrenciesKey = "com.ryce.convrt.savedcurrencies"

class ConvrtSession: NSObject {
    
    private static var __once: () = {
            Static.instance = ConvrtSession()
        }()
    
    class var sharedInstance: ConvrtSession {
        struct Static {
            static var onceToken: Int = 0
            static var instance: ConvrtSession? = nil
        }
        _ = ConvrtSession.__once
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
            if let persistedCurrencyData = UserDefaults.standard().object(forKey: kSavedCurrenciesKey) as? Data {
                if let persistedCurrencyPairs = NSKeyedUnarchiver.unarchiveObject(with: persistedCurrencyData) as? [CurrencyPair] {
                    _savedCurrencyPairs = persistedCurrencyPairs
                    return _savedCurrencyPairs!
                }
            }
            _savedCurrencyPairs = self.generateCurrencyPairs(self.savedCurrencyConfiguration)
            return _savedCurrencyPairs!
        }
        set {
            _savedCurrencyPairs = newValue
            UserDefaults.standard().set(NSKeyedArchiver.archivedData(withRootObject: newValue), forKey: kSavedCurrenciesKey)
            UserDefaults.standard().synchronize()
        }
    }

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        return formatter
    }()
    
    var selectedCurrencies = Array<Currency>()
    
    let fullCurrenyList: Array<Currency> = {
        let plistPath = Bundle.main().pathForResource("currencies", ofType: "plist")!
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

    private var _lastUpdated: Date?
    internal(set) var lastUpdated: Date {
        get {
            if let lup = self._lastUpdated {
                return lup
            }
            if let date = UserDefaults.standard().value(forKey: klastUpdatedDateKey) as? Date {
                self._lastUpdated = date
                return self._lastUpdated!
            }
            return Date(timeIntervalSinceNow: 0)
        }
        set {
            self._lastUpdated = newValue
            UserDefaults.standard().setValue(_lastUpdated, forKey: klastUpdatedDateKey)
            UserDefaults.standard().synchronize()
        }
    }
    
    func findCurrencies(_ from: Currency) -> [CurrencyPair] {
        return self.savedCurrencyPairs.filter { $0.fromCurrency == from }
    }
    
    func addCurrencies(_ currencies: [CurrencyPair]) {
        for currencyPair in currencies {
            if let index = self.savedCurrencyPairs.index(of: currencyPair) {
                let object = self.savedCurrencyPairs[index]
                object.merge(currencyPair)
            } else {
                self.savedCurrencyPairs.append(currencyPair)
            }
        }
    }
    
    func generateCurrencyPairs(_ currencies: [Currency]) -> [CurrencyPair] {
        var currPairs = [CurrencyPair]()
        for fromCurrency in currencies {
            for toCurrency in currencies {
                if fromCurrency != toCurrency {
                    currPairs.append(CurrencyPair(fromCurrency, toCurrency))
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
    
    func fetchRatesForCurrencies(_ currencies: Array<CurrencyPair>, completion: (didSucceed: Bool, error: ConvrtError) -> ()) {
        
        let urlString = baseURL + self.constructYQL(currencies)
        manager.request(Method.GET, urlString, parameters: nil, encoding: .URL).responseJSON(completionHandler: { (response) -> Void in
            if response.result.isFailure {
                completion(didSucceed: false, error: ConvrtError.ConnectionError)
                return // BAIL
            }
            let JSON = response.result.value as! [String:AnyObject]
            let objects = JSON["query"] as? NSDictionary
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
        })
    }
    
    func constructYQL(_ currencies: [CurrencyPair]) -> String {
        var constructionString = ""
        let prefix = "select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20%28"
        let suffix = "%29&format=json&env=store://datatables.org/alltableswithkeys"
        
        for (index, pair) in currencies.enumerated() {
            constructionString += "%22" + pair.fromCurrency.code + pair.toCurrency.code + "%22"
            if currencies.count != index + 1 {
                constructionString += ",%20"
            }
        }
        
        return prefix + constructionString + suffix
    }
    
}

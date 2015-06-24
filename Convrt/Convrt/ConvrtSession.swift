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

enum ConvrtError : ErrorType {
    case NoError, ConnectionError, ParseError
}

class Currency: NSObject {
    
    init(_ someTitle: String, _ someCode: String, _ someCountry: String) {
        self.title = someTitle
        self.code = someCode
        self.country = someCountry
        super.init()
    }
    
    let title: String
    let code: String
    let country: String
    
    var currentAmount: CurrencyAmount = 0.0
    
    let numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        formatter.currencySymbol = ""
        return formatter
    }()
    
    func displayAmount() -> String {
        return numberFormatter.stringFromNumber(NSNumber(double: self.currentAmount))!
    }
}

func ==(lhs: Currency, rhs: Currency) -> Bool {
    return lhs.code == rhs.code
}

struct CurrencyPair: Equatable {
    
    init(fromCurrency: Currency, toCurrency: Currency) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
    }
    
    init(fromCurrency: Currency, toCurrency: Currency, rate: Double) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.rate = rate;
    }

    let fromCurrency: Currency
    let toCurrency: Currency
    var rate: Double?
}

func ==(lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
    return lhs.fromCurrency == rhs.fromCurrency && lhs.toCurrency == rhs.toCurrency
}

let klastUpdatedDateKey = "com.ryce.convrt.lastupdateddate"

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
    
    // somehow need to persist this array of _savedCurrencyConfig when set
    private var _savedCurrencyConfig: [Currency]?
    var savedCurrencyConfiguration: [Currency] {
        get {
            if let savedCurrencyConfig = _savedCurrencyConfig {
                return savedCurrencyConfig
            }
            _savedCurrencyConfig = genericCurrencyArray
            return _savedCurrencyConfig!
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
    
    var currencyPairs = [CurrencyPair]()
    
    func findCurrencies(from: Currency) -> [CurrencyPair] {
        return self.currencyPairs.filter { $0.fromCurrency == from }
    }
    
    func addCurrencies(currencies: [CurrencyPair]) {
        for currencyPair in currencies {
            if self.currencyPairs.contains(currencyPair) {
                // TODO: implement this!
            }
        }
    }

    
    let manager: Manager = Alamofire.Manager.sharedInstance
    let baseURL = "http://query.yahooapis.com/v1/public/yql?q="
    
    func fetchRatesForCurrencies(currencies: Array<CurrencyPair>, completion: (items: Array<CurrencyPair>?, error: ConvrtError) -> ()) {
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
                    
                    completion(items: newCurrencies, error: ConvrtError.NoError)
                } else {
                    completion(items: nil, error: ConvrtError.ParseError)
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

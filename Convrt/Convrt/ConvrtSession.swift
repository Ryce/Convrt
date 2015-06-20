//
//  ConvrtSession.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit
import Alamofire

enum ConvrtError : ErrorType {
    case NoError, ConnectionError, ParseError
}

struct Currency: Equatable, NilLiteralConvertible {
    
    init(nilLiteral: ()) {
        title = ""
        code = ""
        country = ""
    }
    
    init(someTitle: String, someCode: String, someCountry: String) {
        title = someTitle
        code = someCode
        country = someCountry
    }
    
    init(name: String, identifier: String) {
        title = name
        code = identifier
        country = ""
    }
    
    let title: String
    let code: String
    let country: String
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

let klastUpdatedDateKey = ""

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
    
    
    let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        return formatter
    }()
    
    var selectedCurrencies = Array<Currency>()
    
    let fullCurrenyList: Array<Currency> = {
        let plistPath = NSBundle.mainBundle().pathForResource("currency", ofType: "plist")!
        let plistArray = NSArray(contentsOfFile: plistPath) as! Array<AnyObject>
        
        return plistArray.map {
            guard let title = $0["title"] as? String else { return nil }
            guard let code = $0["code"] as? String else { return nil }
            guard let country = $0["country"] as? String else { return nil }
            return Currency(someTitle: title, someCode: code, someCountry: country)
            }.filter {$0 != nil}
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
    
    let manager: Manager = Alamofire.Manager.sharedInstance
    let baseURL = "http://query.yahooapis.com/v1/public/yql?q="
    
    func fetchRatesForCurrencies(currencies: Array<CurrencyPair>, completion: (items: Array<CurrencyPair>?, error: ConvrtError) -> ()) {
        let urlString = baseURL + self.constructYQL(currencies)
        manager.request(Method.GET, urlString, parameters: nil, encoding: .URL)
            .responseJSON { (_, _, JSON, error) -> Void in
                
                let objects = JSON?["query"] as? NSDictionary
                if let _objects = objects?.valueForKeyPath("results.rate") as? Array<Dictionary<String, String>> {
                    var newCurrencies = Array<CurrencyPair>()

                    for dict in _objects {
                        let nameArray = dict["Name"]?.componentsSeparatedByString("/")
                        let fromCurrency = Currency(name: nameArray![0], identifier: nameArray![0])
                        let toCurrency = Currency(name: nameArray![1], identifier: nameArray![1])
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

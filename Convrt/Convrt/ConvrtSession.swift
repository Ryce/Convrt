//
//  ConvrtSession.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit
import Alamofire

struct Currency: Equatable {
    let name: String
    let identifier: String
    
}

func ==(lhs: Currency, rhs: Currency) -> Bool {
    return lhs.name == rhs.name
}

struct CurrencyPair: Equatable {
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
    
    func fetchRatesForCurrencies(currencies: Array<CurrencyPair>, completion: (items: Array<CurrencyPair>?, error: NSError?) -> ()) {
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
                    
                    completion(items: newCurrencies, error: nil)
                } else {
                    completion(items: nil, error: NSError())
                }
                
            }
    }
    
    func constructYQL(currencies: Array<CurrencyPair>) -> String {
        var constructionString = ""
        let prefix = "select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20%28"
        let suffix = "%29&format=json&env=store://datatables.org/alltableswithkeys"
        
        for (index, pair) in currencies.enumerate() {
            constructionString += "%22" + pair.fromCurrency.identifier + pair.toCurrency.identifier + "%22"
            if currencies.count != index + 1 {
                constructionString += ",%20"
            }
        }
        
        return prefix + constructionString + suffix
    }
    
}

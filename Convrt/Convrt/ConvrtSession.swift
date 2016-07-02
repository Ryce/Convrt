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

class ConvrtSession {
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        return formatter
    }()
    
    var selectedCurrencies = [Currency]()
    
    let fullCurrenyList: [Currency] = {
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
    
    func amount(from fromCurrency: Currency, to toCurrency: Currency) -> String {
        let fromCurrencyPairs = self.findCurrencies(fromCurrency)
        if fromCurrencyPairs.count > 0 {
            let amountPair = fromCurrencyPairs.filter { $0.toCurrency == toCurrency }[0]
            if amountPair.rate != 0.0 {
                return String(fromCurrency.currentAmount * amountPair.rate)
            }
        }
        return numberFormatter.string(from: 0)!
    }

    
    let manager: Manager = Alamofire.Manager.sharedInstance
    let baseURL = "http://query.yahooapis.com/v1/public/yql?q="
    
    func fetchRatesForCurrencies(_ currencies: Array<CurrencyPair>, completion: (didSucceed: Bool, error: ConvrtError) -> ()) {
        
        let urlString = baseURL + self.constructYQL(currencies)
        manager.request(Method.GET, urlString, parameters: nil, encoding: .url).responseJSON(completionHandler: { (response) -> Void in
            if response.result.isFailure {
                completion(didSucceed: false, error: ConvrtError.connectionError)
                return // BAIL
            }
            let JSON = response.result.value as! [String:AnyObject]
            let objects = JSON["query"] as? NSDictionary
            if let _objects = objects?.value(forKeyPath: "results.rate") as? [[String:String]] {
                var newCurrencies = Array<CurrencyPair>()
                // TODO: update existing objects instead of creating new ones
                for dict in _objects {
                    let nameArray = dict["Name"]?.components(separatedBy: "/")
                    let fromCurrency = Currency(nameArray![0], nameArray![0], "")
                    let toCurrency = Currency(nameArray![1], nameArray![1], "")
                    let rate = dict["Rate"]! as NSString
                    newCurrencies.append(CurrencyPair(fromCurrency: fromCurrency, toCurrency: toCurrency, rate: rate.doubleValue))
                }
                
                // merge new info into existing array
                self.savedCurrencyPairs = newCurrencies
                
                completion(didSucceed: true, error: ConvrtError.noError)
            } else {
                completion(didSucceed: false, error: ConvrtError.parseError)
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

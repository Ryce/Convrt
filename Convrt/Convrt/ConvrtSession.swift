//
//  ConvrtSession.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift

let genericCurrencyArray: [Currency] = {
    let currencies = [("United States Dollar", "USD", "United States of America"),
                                ("European Euro", "EUR", "Europe"),
                                ("British Pound", "GBP", "Great Britain"),
                                ("Japanese Yen", "JPY", "Japan"),
                                ("Swiss Franc", "CHF", "Switzerland"),
                                ("Canadian Dollar", "CAD", "Canada"),
                                ("Australian Dollar", "AUD", "Australia"),
                                ("Renminbi", "CNY", "China")]
    
    return [Currency]()
    
}()


typealias CurrencyAmount = Double

enum ConvrtError: Error {
    case noError, connectionError, parseError
}

class ConvrtSession {
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        return formatter
    }()
    
    var selectedCurrencies = [Currency]()
    
    let fullCurrenyList: [Currency] = {
        let plistPath = Bundle.main.path(forResource: "currencies", ofType: "plist")!
        
        let plistArray = NSArray(contentsOfFile: plistPath)! as [AnyObject]
        
        return plistArray.map {
            if let title = $0["title"] as? String, let code = $0["code"] as? String, let country = $0["country"] as? String {
                let currency = Currency()
                currency.title = title
                currency.code = code
                currency.country = country
                return currency
            } else {
                assertionFailure("Parse Error")
                return Currency() // silence error
            }
        }
    }()
    
    func savedCurrencyPairs() -> Results<CurrencyPair>? {
        return try? Realm().objects(CurrencyPair.self)
    }
    
    func findCurrencies(_ from: Currency) -> [CurrencyPair]? {
        return self.savedCurrencyPairs()?.filter { $0.fromCurrency == from }
    }
    
    func addCurrencies(_ currencies: [CurrencyPair]) {
        guard let savedCurrencyPairs = self.savedCurrencyPairs() else { return } // BAIL
        for currencyPair in currencies {
            if let index = savedCurrencyPairs.index(of: currencyPair) {
                let object = savedCurrencyPairs[index]
                object.merge(currencyPair)
            } else {
                let realm = try! Realm()
                try? realm.write {
                    realm.add(currencyPair, update: true)
                }
            }
        }
        let realm = try! Realm()
        try? realm.write {
            realm.add(currencies, update: true)
        }
    }
    
    func generateCurrencyPairs(_ currencies: [Currency]) -> [CurrencyPair] {
        var currPairs = [CurrencyPair]()
        for fromCurrency in currencies {
            for toCurrency in currencies {
                if fromCurrency != toCurrency {
                    let currPair = CurrencyPair()
                    currPair.fromCurrency = fromCurrency
                    currPair.toCurrency = toCurrency
                    currPairs.append(currPair)
                }
            }
        }
        return currPairs
    }
    
    func updateSavedCurrencyPairs() {
        // TODO: update savedCurrencyPairs
    }
    
    func amount(from fromCurrency: Currency, to toCurrency: Currency) -> String {
        guard let fromCurrencyPairs = self.findCurrencies(fromCurrency) else { return "" }
        if fromCurrencyPairs.count > 0 {
            let amountPair = fromCurrencyPairs.filter { $0.toCurrency == toCurrency }[0]
            if let fromAmount = fromCurrency.currentAmount.value, let amountPairRate = amountPair.rate.value, amountPairRate != 0.0 {
                return String(fromAmount * amountPairRate)
            }
        }
        return Currency.numberFormatter.string(from: 0)!
    }
    
    let baseURL = "http://query.yahooapis.com/v1/public/yql?q="
    
    func fetchRatesForCurrencies(_ currencies: [CurrencyPair], completion: @escaping (Bool, ConvrtError) -> ()) {
        
        let urlString = baseURL + self.constructYQL(currencies)
        Alamofire.request(urlString).responseJSON(completionHandler: { (response) -> Void in
            if response.result.isFailure {
                completion(false, .connectionError)
                return // BAIL
            }
            let JSON = response.result.value as! [String: AnyObject]
            let objects = JSON["query"] as? [String: AnyObject]
            if let _objects = objects?["results"]?["rate"] as? [[String: String]] {
                var newCurrencies = [CurrencyPair]()
                // TODO: update existing objects instead of creating new ones
                for dict in _objects {
                    let nameArray = dict["Name"]?.components(separatedBy: "/")
                    let fromCurrency = Currency()
                    fromCurrency.title = nameArray![0]
                    fromCurrency.code = nameArray![0]
                    let toCurrency = Currency()
                    toCurrency.title = nameArray![1]
                    toCurrency.code = nameArray![1]
                    let rate = dict["Rate"]! as NSString
                    let currencyPair = CurrencyPair()
                    currencyPair.fromCurrency = fromCurrency
                    currencyPair.toCurrency = toCurrency
                    currencyPair.rate.value = rate.doubleValue
                    newCurrencies.append(currencyPair)
                }
                
                
                
                // merge new info into existing array
                // update main view when save is complete
                
                completion(true, ConvrtError.noError)
            } else {
                completion(false, ConvrtError.parseError)
            }
        })
    }
    
    func constructYQL(_ currencies: [CurrencyPair]) -> String {
        var constructionString = ""
        let prefix = "select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20%28"
        let suffix = "%29&format=json&env=store://datatables.org/alltableswithkeys"
        
        for (index, pair) in currencies.enumerated() {
            let fromCurrency = pair.fromCurrency 
            let toCurrency = pair.toCurrency
            constructionString += "%22" + fromCurrency!.code + toCurrency!.code + "%22"
            if currencies.count != index + 1 {
                constructionString += ",%20"
            }
        }
        
        return prefix + constructionString + suffix
    }
    
}

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
        let plistPath = Bundle.main.pathForResource("currencies", ofType: "plist")!
        let plistArray = NSArray(contentsOfFile: plistPath) as! Array<AnyObject>
        
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
    
    func savedCurrencyPairs() -> [CurrencyPair]? {
        guard let appDelegate = UIApplication.shared().delegate as? AppDelegate else { return nil }
        
        do {
            if #available(iOS 10.0, *) {
                if let result = try appDelegate.cdh.managedObjectContext.fetch(CurrencyPair.fetchRequest()) as? [CurrencyPair] {
                    return result
                }
                return nil
            } else {
                return nil
                // Fallback on earlier versions
            }
            
        } catch {
            return nil
        }
        
    }
    
    func findCurrencies(_ from: Currency) -> [CurrencyPair]? {
        return self.savedCurrencyPairs()?.filter { $0.fromCurrency == from }
    }
    
    func addCurrencies(_ currencies: [CurrencyPair]) {
        guard var savedCurrencyPairs = self.savedCurrencyPairs() else { return } // BAIL
        for currencyPair in currencies {
            if let index = savedCurrencyPairs.index(of: currencyPair) {
                let object = savedCurrencyPairs[index]
                object.merge(currencyPair)
            } else {
                savedCurrencyPairs.append(currencyPair)
            }
        }
        // TODO: need to update savedCurrencyPairs into persistentStore
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
//        self.savedCurrencyPairs = self.generateCurrencyPairs(self.savedCurrencyConfiguration)
    }
    
    func amount(from fromCurrency: Currency, to toCurrency: Currency) -> String {
        let fromCurrencyPairs = self.findCurrencies(fromCurrency)
        if fromCurrencyPairs?.count > 0 {
            let amountPair = fromCurrencyPairs?.filter { $0.toCurrency == toCurrency }[0]
            if let amountPair = amountPair, amountPair.rate != 0.0 {
                return String(fromCurrency.currentAmount * amountPair.rate)
            }
        }
        return fromCurrency.numberFormatter().string(from: 0)!
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
                    let appDelegate = UIApplication.shared().delegate as! AppDelegate
                    let fromCurrency = NSEntityDescription.insertNewObject(forEntityName: "Currency", into: appDelegate.cdh.managedObjectContext) as! Currency
                    fromCurrency.title = nameArray![0]
                    fromCurrency.code = nameArray![0]
                    let toCurrency = NSEntityDescription.insertNewObject(forEntityName: "Currency", into: appDelegate.cdh.managedObjectContext) as! Currency
                    toCurrency.title = nameArray![1]
                    toCurrency.code = nameArray![1]
                    let rate = dict["Rate"]! as NSString
                    let currencyPair = NSEntityDescription.insertNewObject(forEntityName: "CurrencyPair", into: appDelegate.cdh.managedObjectContext) as! CurrencyPair
                    currencyPair.fromCurrency = fromCurrency
                    currencyPair.toCurrency = toCurrency
                    currencyPair.rate = rate.doubleValue
                    newCurrencies.append(currencyPair)
                }
                
                
                
                // merge new info into existing array
                // update main view when save is complete
                
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
            let fromCurrency = pair.fromCurrency as! Currency
            let toCurrency = pair.toCurrency as! Currency
            constructionString += "%22" + fromCurrency.code! + toCurrency.code! + "%22"
            if currencies.count != index + 1 {
                constructionString += ",%20"
            }
        }
        
        return prefix + constructionString + suffix
    }
    
}

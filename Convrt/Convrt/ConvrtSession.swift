//
//  ConvrtSession.swift
//  Convrt
//
//  Created by Hamon Riazy on 16/05/15.
//  Copyright (c) 2015 ryce. All rights reserved.
//

import UIKit
import Alamofire

struct Currency {
    let name: String
    let identifier: String
}

struct CurrencyPair {
    let fromCurrency: Currency
    let toCurrency: Currency
    var rate: Double?
}

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
    
    let manager: Manager = Alamofire.Manager.sharedInstance
    let baseURL = "http://query.yahooapis.com/v1/public/yql?q="
    
    func fetchRatesForCurrencies(currencies: Array<CurrencyPair>, completion: (items: Array<CurrencyPair>?, error: NSError?) -> ()) {
        let urlString = baseURL + (self.constructYQL(currencies) as NSString).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        manager.request(Method.GET, urlString, parameters: nil, encoding: .URL)
            .responseJSON(options: NSJSONReadingOptions.AllowFragments) { (_, _, data, error) -> Void in
                let newCurrencies = Array<CurrencyPair>()
                completion(items: newCurrencies, error: nil)
        }
    }
    
    func constructYQL(currencies: Array<CurrencyPair>) -> String {
        return ""
    }
    
}

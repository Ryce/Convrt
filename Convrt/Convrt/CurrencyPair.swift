//
//  CurrencyPair.swift
//  Convrt
//
//  Created by Hamon Riazy on 25/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import Foundation

let kFromCurrencyKey = "fromCurrency"
let kToCurrencyKey = "toCurrency"
let kRateKey = "rate"

class CurrencyPair: NSObject, NSCoding {
    
    required init?(coder aDecoder: NSCoder) {
        self.fromCurrency = aDecoder.decodeObject(forKey: kFromCurrencyKey) as! Currency
        self.toCurrency = aDecoder.decodeObject(forKey: kToCurrencyKey) as! Currency
        self.rate = aDecoder.decodeDouble(forKey: kRateKey)
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.fromCurrency, forKey: kFromCurrencyKey)
        aCoder.encode(self.toCurrency, forKey: kToCurrencyKey)
        aCoder.encode(self.rate, forKey: kRateKey)
    }
    
    init(_ fromCurrency: Currency, _ toCurrency: Currency) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        super.init()
    }
    
    init(fromCurrency: Currency, toCurrency: Currency, rate: Double) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.rate = rate;
        super.init()
    }
    
    func merge(_ otherCurrencyPair: CurrencyPair) {
        self.rate = otherCurrencyPair.rate
    }
    
    override func isEqual(_ object: AnyObject?) -> Bool {
        guard let currencyPair = object as? CurrencyPair else { return false }
        return self.fromCurrency == currencyPair.fromCurrency && self.toCurrency == currencyPair.toCurrency
    }
    
    let fromCurrency: Currency
    let toCurrency: Currency
    var rate: Double = 0.0
}

func ==(lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
    return lhs.fromCurrency == rhs.fromCurrency && lhs.toCurrency == rhs.toCurrency
}

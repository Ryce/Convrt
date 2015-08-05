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
        self.fromCurrency = aDecoder.decodeObjectForKey(kFromCurrencyKey) as! Currency
        self.toCurrency = aDecoder.decodeObjectForKey(kToCurrencyKey) as! Currency
        self.rate = aDecoder.decodeDoubleForKey(kRateKey)
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.fromCurrency, forKey: kFromCurrencyKey)
        aCoder.encodeObject(self.toCurrency, forKey: kToCurrencyKey)
        aCoder.encodeDouble(self.rate, forKey: kRateKey)
    }
    
    init(fromCurrency: Currency, toCurrency: Currency) {
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
    
    func merge(otherCurrencyPair: CurrencyPair) {
        self.rate = otherCurrencyPair.rate
    }
    
    let fromCurrency: Currency
    let toCurrency: Currency
    var rate: Double = 0.0
}

func ==(lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
    return lhs.fromCurrency == rhs.fromCurrency && lhs.toCurrency == rhs.toCurrency
}
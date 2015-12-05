//
//  Currency.swift
//  Convrt
//
//  Created by Hamon Riazy on 25/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import Foundation

let kTitleKey = "title"
let kCodeKey = "code"
let kCountryKey = "country"

class Currency: NSObject, NSCoding {
    
    required init?(coder aDecoder: NSCoder) {
        self.title = aDecoder.decodeObjectForKey(kTitleKey) as! String
        self.code = aDecoder.decodeObjectForKey(kCodeKey) as! String
        self.country = aDecoder.decodeObjectForKey(kCountryKey) as! String
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.title, forKey: kTitleKey)
        aCoder.encodeObject(self.code, forKey: kCodeKey)
        aCoder.encodeObject(self.country, forKey: kCountryKey)
    }
    
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
    
    func calculateAmount(fromCurrency: Currency) -> String {
        let fromCurrencyPairs = ConvrtSession.sharedInstance.findCurrencies(fromCurrency)
        if fromCurrencyPairs.count > 0 {
            let amountPair = fromCurrencyPairs.filter { $0.toCurrency == self }[0]
            if amountPair.rate != 0.0 {
                self.currentAmount = fromCurrency.currentAmount * amountPair.rate
                return numberFormatter.stringFromNumber(self.currentAmount)!
            }
        }
        return numberFormatter.stringFromNumber(0)!
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        guard let currency = object as? Currency else { return false }
        return self.code == currency.code
    }
    
}

func ==(lhs: Currency, rhs: Currency) -> Bool {
    return lhs.code == rhs.code
}

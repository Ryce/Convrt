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
        self.title = aDecoder.decodeObject(forKey: kTitleKey) as! String
        self.code = aDecoder.decodeObject(forKey: kCodeKey) as! String
        self.country = aDecoder.decodeObject(forKey: kCountryKey) as! String
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: kTitleKey)
        aCoder.encode(self.code, forKey: kCodeKey)
        aCoder.encode(self.country, forKey: kCountryKey)
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
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        formatter.currencySymbol = ""
        return formatter
        }()
    
    func displayAmount() -> String {
        return numberFormatter.string(from: NSNumber(value: self.currentAmount))!
    }
    
    func calculateAmount(_ fromCurrency: Currency) -> String {
        let fromCurrencyPairs = ConvrtSession.sharedInstance.findCurrencies(fromCurrency)
        if fromCurrencyPairs.count > 0 {
            let amountPair = fromCurrencyPairs.filter { $0.toCurrency == self }[0]
            if amountPair.rate != 0.0 {
                self.currentAmount = fromCurrency.currentAmount * amountPair.rate
                return numberFormatter.string(from: self.currentAmount)!
            }
        }
        return numberFormatter.string(from: 0)!
    }
    
    override func isEqual(_ object: AnyObject?) -> Bool {
        guard let currency = object as? Currency else { return false }
        return self.code == currency.code
    }
    
}

func ==(lhs: Currency, rhs: Currency) -> Bool {
    return lhs.code == rhs.code
}

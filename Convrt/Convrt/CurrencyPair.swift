//
//  CurrencyPair.swift
//  Convrt
//
//  Created by Hamon Riazy on 25/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import Foundation
import CoreData

extension CurrencyPair {
    
    func merge(_ otherCurrencyPair: CurrencyPair) {
        self.rate = otherCurrencyPair.rate
    }
    
    override func isEqual(_ object: AnyObject?) -> Bool {
        guard let currencyPair = object as? CurrencyPair else { return false }
        return self.fromCurrency == currencyPair.fromCurrency && self.toCurrency == currencyPair.toCurrency
    }
    
}

func ==(lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
    return lhs.fromCurrency == rhs.fromCurrency && lhs.toCurrency == rhs.toCurrency
}

//
//  CurrencyPair.swift
//  Convrt
//
//  Created by Hamon Riazy on 25/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import Foundation
import RealmSwift

class CurrencyPair: Object {
    
    dynamic var fromCurrency: Currency?
    dynamic var toCurrency: Currency?
    let rate = RealmOptional<Double>()
    
}

extension CurrencyPair {
    
    func merge(_ otherCurrencyPair: CurrencyPair) {
        self.rate.value = otherCurrencyPair.rate.value
    }
    
}

func ==(lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
    return lhs.fromCurrency == rhs.fromCurrency && lhs.toCurrency == rhs.toCurrency
}

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
    
    dynamic var fromCurrency: Currency? {
        didSet {
            setIdentifierIfNeeded()
        }
    }
    
    dynamic var toCurrency: Currency? {
        didSet {
            setIdentifierIfNeeded()
        }
    }
    
    dynamic var identifier: String?
    
    let rate = RealmOptional<Double>()
    
    static override func primaryKey() -> String {
        return "identifier"
    }
    
    func setIdentifierIfNeeded() {
        guard let fromCurrency = fromCurrency, let toCurrency = toCurrency else { return }
        identifier = fromCurrency.code + toCurrency.code
    }
    
}

extension CurrencyPair {
    
    func merge(_ otherCurrencyPair: CurrencyPair) {
        self.rate.value = otherCurrencyPair.rate.value
    }
    
}

func ==(lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
    return lhs.fromCurrency == rhs.fromCurrency && lhs.toCurrency == rhs.toCurrency
}

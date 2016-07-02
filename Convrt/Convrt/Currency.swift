//
//  Currency.swift
//  Convrt
//
//  Created by Hamon Riazy on 25/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import Foundation
import CoreData

class Currency: NSManagedObject, Equatable {
    
    init(_ someTitle: String, _ someCode: String, _ someCountry: String) {
        self.title = someTitle
        self.code = someCode
        self.country = someCountry
        super.init()
    }
    
    dynamic var title: String
    dynamic var code: String
    dynamic var country: String
    
    dynamic var currentAmount: CurrencyAmount = 0.0
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        formatter.currencySymbol = ""
        return formatter
        }()
    
    func displayAmount() -> String {
        return numberFormatter.string(from: NSNumber(value: self.currentAmount))!
    }
    
}

func ==(lhs: Currency, rhs: Currency) -> Bool {
    return lhs.code == rhs.code
}

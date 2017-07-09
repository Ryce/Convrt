//
//  Currency.swift
//  Convrt
//
//  Created by Hamon Riazy on 25/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import Foundation
import RealmSwift

class Currency: Object {
    
    dynamic var title: String = ""
    dynamic var code: String = ""
    dynamic var country: String = ""
    let currentAmount = RealmOptional<Double>()
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        formatter.currencySymbol = ""
        return formatter
    }()
    
    override static func primaryKey() -> String {
        return "code"
    }
    
}

extension Currency {
    
    var displayAmount: String? {
        guard let doubleValue = self.currentAmount.value else { return nil }
        return Currency.numberFormatter.string(for: doubleValue)
    }
    
}

func ==(lhs: Currency, rhs: Currency) -> Bool {
    return lhs.code == rhs.code
}

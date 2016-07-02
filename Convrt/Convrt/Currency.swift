//
//  Currency.swift
//  Convrt
//
//  Created by Hamon Riazy on 25/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import Foundation
import CoreData

let currencyNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.currencySymbol = ""
    return formatter
}()

extension Currency {
    
    func numberFormatter() -> NumberFormatter { return currencyNumberFormatter }
    
    func displayAmount() -> String {
        return self.numberFormatter().string(from: NSNumber(value: self.currentAmount))!
    }
    
}

func ==(lhs: Currency, rhs: Currency) -> Bool {
    return lhs.code == rhs.code
}

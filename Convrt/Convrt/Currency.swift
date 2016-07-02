//
//  Currency.swift
//  Convrt
//
//  Created by Hamon Riazy on 25/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import Foundation
import CoreData
import SugarRecord

let currencyNumberFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencySymbol = ""
    return formatter
}()

class Currency: NSManagedObject {
    
    @NSManaged var title: String
    @NSManaged var code: String
    @NSManaged var country: String
    
    static func create(withDatabase db: CoreDataDefaultStorage, callBack: (result: Currency?) -> ()) {
        do {
            try db.operation({ (context, save) -> Void in
                let newTask: Currency = try! context.new()
                save()
                callBack(result: newTask)
            })
        }
        catch {
            callBack(result: nil)
            // There was an error in the operation
        }
    }
    
    var currentAmount: Double = 0.0
    
    func numberFormatter() -> NSNumberFormatter { return currencyNumberFormatter }
    
    func displayAmount() -> String {
        return self.numberFormatter().stringFromNumber(NSNumber(double: self.currentAmount))!
    }
    
}

func ==(lhs: Currency, rhs: Currency) -> Bool {
    return lhs.code == rhs.code
}

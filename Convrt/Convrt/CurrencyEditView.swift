//
//  CurrencyEditView.swift
//  Convrt
//
//  Created by Hamon Riazy on 21/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit

class CurrencyEditView: UIView, UITextFieldDelegate {
    
    @IBOutlet var codeLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var amountTextField: UITextField?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("dismissView")))
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("dismissView")))
    }
    
    func dismissView() {
        self.amountTextField?.resignFirstResponder()
        UIView.animateWithDuration(0.5) { () -> Void in
            self.alpha = 0.0
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let oldString = textField.text!
        let newString = (oldString as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        if newString.characters.count == 0 {
            return true
        } else if newString.characters.count == 1 {
            let decimalSeparator = NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
            
            if newString == decimalSeparator {
                textField.text = "0."
                return false
            }
        }
        
        
        var regex: NSRegularExpression?
        
        do {
            regex = try NSRegularExpression(pattern: "^[0-9]+(\\.[0-9]{0,2})?$", options: NSRegularExpressionOptions.CaseInsensitive)
        } catch {
            return false
        }
        
        let numberOfMatches = regex!.numberOfMatchesInString(newString, options: NSMatchingOptions.WithoutAnchoringBounds, range: NSMakeRange(0, newString.characters.count))
        
        return numberOfMatches > 0
        
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}

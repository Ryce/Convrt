//
//  CurrencyEditView.swift
//  Convrt
//
//  Created by Hamon Riazy on 21/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit

protocol CurrencyEditDelegate : class {
    func didDismiss(view: CurrencyEditView, _ currency: Currency, _ inputAmount: Double)
}

class CurrencyEditView: UIView, UITextFieldDelegate {
    
    @IBOutlet var codeLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var amountTextField: UITextField?
    
    var currency: Currency?
    
    weak var delegate: CurrencyEditDelegate?
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("dismissView")))
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("dismissView")))
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    func keyboardWillShow(note: NSNotification) {
        if let info = note.userInfo {
            if let animationCurve = info[UIKeyboardAnimationCurveUserInfoKey] as? UInt,
                let animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
                    UIView.animateWithDuration(animationDuration.doubleValue, delay: 0.0, options:UIViewAnimationOptions(rawValue: animationCurve), animations: { () -> Void in
                        self.alpha = 1.0
                        }, completion: nil)
            } else {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.alpha = 1.0
                })
            }
        }
    }
    
    func keyboardWillHide(note: NSNotification) {
        if let info = note.userInfo {
            if let animationCurve = info[UIKeyboardAnimationCurveUserInfoKey] as? UInt,
                let animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
                    UIView.animateWithDuration(animationDuration.doubleValue, delay: 0.0, options:UIViewAnimationOptions(rawValue: animationCurve), animations: { () -> Void in
                        self.alpha = 0.0
                        }, completion: nil)
            } else {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.alpha = 0.0
                })
            }
        }
    }
    
    func dismissView() {
        if let amountText = self.amountTextField?.text {
            let numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            if let number = numberFormatter.numberFromString(amountText) {
                self.delegate?.didDismiss(self, self.currency!, number.doubleValue)
            }
        }
        
        self.amountTextField?.resignFirstResponder()
    }
    
    // MARK: UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let oldString = textField.text!
        let newString = (oldString as NSString).stringByReplacingCharactersInRange(range, withString: string)
        let decimalSeparator = NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
        let thousandSeparator = NSLocale.currentLocale().objectForKey(NSLocaleGroupingSeparator) as! String
        
        switch count(newString) {
        case 0:
            return true
        case 1:
            
            if newString == decimalSeparator {
                textField.text = "0" + decimalSeparator
                return false
            }
            break
        case _ where count(newString) > 10:
            return false
        case _ where last(newString)! == last(thousandSeparator)!:
            textField.text = newString.stringByReplacingOccurrencesOfString(thousandSeparator, withString: "")
            return false
        default:
            break
        }
        
        var regex: NSRegularExpression?
        
        let pattern = NSString(format: "^[0-9]+([\\%@][0-9]+)?(\\%@[0-9]{0,2})?$", thousandSeparator, decimalSeparator) as String
        
        regex = NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.CaseInsensitive, error:nil)
        
//        if upPointer = pointer {
//            return false
//        }
        
        let numberOfMatches = regex!.numberOfMatchesInString(newString, options: NSMatchingOptions.WithoutAnchoringBounds, range: NSMakeRange(0, count(newString)))
        
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

//
//  CurrencyEditView.swift
//  Convrt
//
//  Created by Hamon Riazy on 21/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit

protocol CurrencyEditDelegate : class {
    func didDismiss(_ view: CurrencyEditView, _ currency: Currency, _ inputAmount: Double)
}

class CurrencyEditView: UIView, UITextFieldDelegate {
    
    @IBOutlet var codeLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var amountTextField: UITextField?
    
    @IBOutlet var keyboardHeightConstraint: NSLayoutConstraint!
    
    var didChangeAmount = false
    
    var currency: Currency?
    
    weak var delegate: CurrencyEditDelegate?
    
    deinit {
        NotificationCenter.default().removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default().removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("dismissView")))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("dismissView")))
        
        NotificationCenter.default().addObserver(self, selector: Selector("keyboardWillShow:"), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default().addObserver(self, selector: Selector("keyboardWillHide:"), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    func keyboardWillShow(_ note: Notification) {
        guard let info = (note as NSNotification).userInfo else { return } // BAIL
        
        guard let animationCurve = info[UIKeyboardAnimationCurveUserInfoKey],
            let animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] else {
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    self.alpha = 1.0
                })
                return // BAIL
        }
        
        if let keyboardRect = info[UIKeyboardFrameEndUserInfoKey]?.cgRectValue {
            self.keyboardHeightConstraint.constant = keyboardRect.height + 8.0
        }
        
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0.0, options:UIViewAnimationOptions(rawValue: (animationCurve as! UInt)), animations: { () -> Void in
            self.alpha = 1.0
            }, completion: nil)
    }
    
    func keyboardWillHide(_ note: Notification) {
        guard let info = (note as NSNotification).userInfo else { return } // BAIL
        
        guard let animationCurve = info[UIKeyboardAnimationCurveUserInfoKey],
            let animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] else {
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    self.alpha = 0.0
                })
                return // BAIL
        }
        
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0.0, options:UIViewAnimationOptions(rawValue: (animationCurve as! UInt)), animations: { () -> Void in
            self.alpha = 0.0
            }, completion: nil)
    }
    
    @IBAction func dismissView() {
        if self.didChangeAmount {
            self.didChangeAmount = false
            if let amountText = self.amountTextField?.text {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                let number = numberFormatter.number(from: amountText) ?? 0.0
                self.delegate?.didDismiss(self, self.currency!, number.doubleValue)
            }
        }
        
        self.amountTextField?.resignFirstResponder()
    }
    
    // MARK: UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.didChangeAmount = true
        let oldString = textField.text!
        let newString = (oldString as NSString).replacingCharacters(in: range, with: string)
        let decimalSeparator = Locale.current().object(forKey: Locale.Key.decimalSeparator) as! String
        let thousandSeparator = Locale.current().object(forKey: Locale.Key.groupingSeparator) as! String
        
        switch newString.characters.count {
        case 0:
            return true
        case 1:
            
            if newString == decimalSeparator {
                textField.text = "0" + decimalSeparator
                return false
            }
            break
        case _ where newString.characters.count > 10:
            return false
        case _ where newString.characters.last! == thousandSeparator.characters.last!:
            textField.text = newString.replacingOccurrences(of: thousandSeparator, with: "")
            return false
        default:
            break
        }
        
        var regex: RegularExpression?
        
        let pattern = NSString(format: "^[0-9]+([\\%@][0-9]+)?(\\%@[0-9]{0,2})?$", thousandSeparator, decimalSeparator) as String
        
        do {
            regex = try RegularExpression(pattern: pattern, options: RegularExpression.Options.caseInsensitive)
        } catch {
            return false
        }
        
        let numberOfMatches = regex!.numberOfMatches(in: newString, options: RegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSMakeRange(0, newString.characters.count))
        
        return numberOfMatches > 0
        
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.didChangeAmount = true
        return true
    }
    
    // MARK: Touches
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches[touches.startIndex]
        let location = touch.location(in: self.superview)
        let previousLocation = touch.previousLocation(in: self.superview)
        let xOffset = previousLocation.y - location.y
        
        guard let amountText = self.amountTextField?.text else { return }
        
        guard let currentAmount = self.currency?.numberFormatter.number(from: amountText) else {
            self.amountTextField?.text = "100"
            return // BAIL
        }
        
        let percentage = 1 + (xOffset/self.bounds.size.height)
        let filteredAmount = Double(currentAmount.doubleValue) * Double(percentage)
        
        self.amountTextField?.text = self.currency?.numberFormatter.string(from: NSNumber(value: filteredAmount))
        self.didChangeAmount = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let amountText = self.amountTextField?.text else { return }

        guard let currentAmount = self.currency?.numberFormatter.number(from: amountText) else { return }
        
        let roundedAmountLength = ceil(log10(currentAmount.doubleValue))
        
        var newAmount = floor(currentAmount.doubleValue)
        
        if roundedAmountLength > 3 {
            newAmount -= newAmount.truncatingRemainder(dividingBy: (pow(10, (roundedAmountLength - 3))))
        }
        
        self.amountTextField?.text = self.currency?.numberFormatter.string(from: NSNumber(value: newAmount))
        self.didChangeAmount = true
    }

}

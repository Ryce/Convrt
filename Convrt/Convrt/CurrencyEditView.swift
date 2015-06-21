//
//  CurrencyEditView.swift
//  Convrt
//
//  Created by Hamon Riazy on 21/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit

class CurrencyEditView: UIView {
    
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
        UIView.animateWithDuration(0.5) { () -> Void in
            self.alpha = 0.0
        }
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}

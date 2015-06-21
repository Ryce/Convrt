//
//  CurrencyEditView.swift
//  Convrt
//
//  Created by Hamon Riazy on 21/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit

class CurrencyEditView: UIView {
    
    var codeLabel: UILabel = {
        let label = UILabel()
        label.text = "USD"
        return label
    }()
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "United States Dollar"
        return label
    }()
    
    var amountTextField: UITextField = {
        let textField = UITextField()
        
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        self.addSubview(self.codeLabel)
        self.addSubview(self.titleLabel)
        self.addSubview(self.amountTextField)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("dismissView")))
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func dismissView() {
        self.removeFromSuperview()
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}

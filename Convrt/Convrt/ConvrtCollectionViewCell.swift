//
//  ConvrtCollectionViewCell.swift
//  Convrt
//
//  Created by Hamon Riazy on 20/06/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit

class ConvrtCollectionViewCell: UICollectionViewCell {
    static let kCellIdentifier = "com.ryce.convrt.collectionviewcellidentifier"
    
    @IBOutlet var codeLabel: UILabel?
    @IBOutlet var amountLabel: UILabel?
    @IBOutlet var countryLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.layer.cornerRadius = 5.0
        self.contentView.backgroundColor = UIColor.white
        self.contentView.layer.shadowOffset = CGSize(width: 0.0, height: 10.0)
        self.contentView.layer.shadowColor = UIColor.black.cgColor
    }
    
}

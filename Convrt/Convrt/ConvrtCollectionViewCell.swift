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
    @IBOutlet var amountTextField: UITextField?
    @IBOutlet var countryLabel: UILabel?
    
}

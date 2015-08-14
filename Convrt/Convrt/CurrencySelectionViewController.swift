//
//  CurrencySelectionViewController.swift
//  Convrt
//
//  Created by Hamon Riazy on 02/08/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit

let currencySelectionCellIdentifier = "com.identifier"

class CurrencySelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var tableViewItems: Array<String>?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITableViewDelegate & DataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = tableViewItems?.count {
            return count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCellWithIdentifier(currencySelectionCellIdentifier, forIndexPath: indexPath)
        return tableViewCell
    }
    

}

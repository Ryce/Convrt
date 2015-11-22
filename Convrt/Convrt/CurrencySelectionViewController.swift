//
//  CurrencySelectionViewController.swift
//  Convrt
//
//  Created by Hamon Riazy on 02/08/15.
//  Copyright © 2015 ryce. All rights reserved.
//

import UIKit

let currencySelectionCellIdentifier = "com.ryce.convrt.currencySelectionCell"

class CurrencySelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var tableViewItems = ConvrtSession.sharedInstance.fullCurrenyList
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: currencySelectionCellIdentifier)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: Selector("dismiss"))
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: UITableViewDelegate & DataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCellWithIdentifier(currencySelectionCellIdentifier, forIndexPath: indexPath)
        tableViewCell.textLabel?.text = tableViewItems[indexPath.row].title
        return tableViewCell
    }
    

}

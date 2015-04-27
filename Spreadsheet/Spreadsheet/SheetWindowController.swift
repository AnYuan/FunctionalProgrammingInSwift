//
//  SheetWindowController.swift
//  Spreadsheet
//
//  Created by Chris Eidhof on 01.07.14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Cocoa

class SheetWindowController : NSWindowController {
    
    @IBOutlet var tableView: NSTableView! = nil
    @IBOutlet var dataSource: SpreadsheetDatasource?
    @IBOutlet var delegate: SpreadsheetDelegate?

    override func windowDidLoad()  {
        delegate?.editedRowDelegate = dataSource
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: NSSelectorFromString("endEditing:"), name: NSControlTextDidEndEditingNotification, object: nil)
    }
    
    func endEditing(note: NSNotification) {
        if note.object as! NSObject === tableView {
            dataSource?.editedRow = nil
        }
    }
    
}


protocol EditedRow {
    var editedRow: Int? { get set }
}


class SpreadsheetDelegate : NSObject, NSTableViewDelegate {
    
    var editedRowDelegate: EditedRow?
    
    func tableView(aTableView: NSTableView!, shouldEditTableColumn aTableColumn: NSTableColumn!, row rowIndex: Int) -> Bool {
        editedRowDelegate?.editedRow = rowIndex
        return true
    }

}


class SpreadsheetDatasource : NSObject, NSTableViewDataSource, EditedRow {
    
    var editedRow: Int? = nil
    var arr: [String]
    var results: [Result]
    
    override init() {
        let initialValues = Array(1..<10)
        arr = initialValues.map { "\($0)" }
        results = initialValues.map { Result.IntResult($0) }
    }
    
    func calculateExpressions() {
        results = evaluateExpressions(arr.map(parseExpression))
    }
    
    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        return arr.count
    }
    
    func tableView(aTableView: NSTableView!, objectValueForTableColumn: NSTableColumn!, row: Int) -> AnyObject! {
        return editedRow == row ? arr[row] : results[row].description
    }
    
    func tableView(aTableView: NSTableView!, setObjectValue: AnyObject!, forTableColumn: NSTableColumn!, row: Int) {
        let string = setObjectValue as! String
        arr[row] = string
        calculateExpressions()
        aTableView.reloadData()
    }
    
}

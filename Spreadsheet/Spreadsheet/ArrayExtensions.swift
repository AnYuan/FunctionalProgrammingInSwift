//
//  ArrayExtensions.swift
//  Spreadsheet
//
//  Created by Florian on 20/08/14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Foundation

extension Array {

    var decompose: (head: T, tail: [T])? {
        return (count > 0) ? (self[0], Array(self[1..<count])) : nil
    }

}


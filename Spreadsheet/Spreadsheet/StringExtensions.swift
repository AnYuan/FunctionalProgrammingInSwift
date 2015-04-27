//
//  StringExtensions.swift
//  Spreadsheet
//
//  Created by Florian on 20/08/14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Foundation

extension String {

    var characters: [Character] {
        var result : [Character] = []
        for c in self {
            result += [c]
        }
        return result
    }

    var slice: ArraySlice<Character> {
        let res = self.characters
        return res[0..<res.count]
    }

}
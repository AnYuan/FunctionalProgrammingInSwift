//
//  SliceExtensions.swift
//  Parsing
//
//  Created by Chris Eidhof on 01.07.14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Foundation

extension ArraySlice {

    var head: T? {
        return self.isEmpty ? nil : self[0]
    }
    
    var tail: ArraySlice<T> {
        return self.isEmpty ? self : self[(self.startIndex+1)..<self.endIndex]
    }
    
    var decompose: (head: T, ArraySlice<T>)? {
        return self.isEmpty ? nil : (self[self.startIndex], self.tail)
    }
    
}


//
//  Functions.swift
//  Parsing
//
//  Created by Chris Eidhof on 01.07.14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Foundation

func const<A, B>(x: A) -> B -> A {
    return { _ in x }
}

func curry<A, B, C>(f: (A, B) -> C) -> A -> B -> C {
    return { x in { y in f(x,y) } }
}

func curry<A, B, C, D>(f: (A, B, C) -> D) -> A -> B -> C -> D {
    return { x in { y in { z in f(x, y, z) } } }
}

func flip<A, B, C>(f: (B, A) -> C) -> (A, B) -> C {
    return { (x, y) in f(y, x) }
}

func prepend<A>(l: A) -> [A] -> [A] {
    return { (x: [A]) in [l] + x }
}

func mapFirst<A, B, C>(f: A -> C)(a: A, b: B) -> (C, B) {
    return (f(a), b)
}

func flatMap<A, B>(x: A?, f: A -> B?) -> B? {
    if let value = x {
        return f(value)
    }
    return nil
}

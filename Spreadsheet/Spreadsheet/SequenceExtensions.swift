//
//  SequenceExtensions.swift
//  Parsing
//
//  Created by Chris Eidhof on 01.07.14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Foundation

struct JoinedGenerator<A>: GeneratorType {
    typealias Element = A
    
    var generator: GeneratorOf<GeneratorOf<A>>
    var current: GeneratorOf<A>?
    
    init(_ g: GeneratorOf<GeneratorOf<A>>) {
        generator = g
        current = generator.next()
    }
    
    mutating func next() -> A? {
        if var c = current {
            if let x = c.next() {
                return x
            } else {
                current = generator.next()
                return next()
            }
        }
        return nil
    }
}

func map<A, B>(var g: GeneratorOf<A>, f: A -> B) -> GeneratorOf<B> {
    return GeneratorOf {
        return map(g.next(), f)
    }
}

func map<A, B>(var s: SequenceOf<A>, f: A -> B) -> SequenceOf<B> {
    return SequenceOf {  map(s.generate(), f) }
}


func join<A>(s: SequenceOf<SequenceOf<A>>) -> SequenceOf<A> {
    return SequenceOf { JoinedGenerator(map(s.generate()) { $0.generate() }) }
}

func apply<A, B>(ls: SequenceOf<A>, f: A -> SequenceOf<B>) -> SequenceOf<B> {
    return join(map(ls, f))
}

func +<A>(l: SequenceOf<A>, r: SequenceOf<A>) -> SequenceOf<A> {
    return join(SequenceOf([l, r]))
}

func one<A>(x: A) -> SequenceOf<A> {
    return SequenceOf(GeneratorOfOne(x))
}

func none<A>() -> SequenceOf<A> {
    return SequenceOf(GeneratorOf { return nil })
}
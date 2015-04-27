//
//  Parsers.swift
//  Parsing
//
//  Created by Chris Eidhof on 01.07.14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Foundation

struct Parser<Token, Result> {
    let p: ArraySlice<Token> -> SequenceOf<(Result, ArraySlice<Token>)>
}

func token<T: Equatable>(token: T) -> Parser<T, T> {
    return satisfy { $0 == token }
}

func satisfy<T>(condition: T -> Bool) -> Parser<T, T> {
    return Parser { x in
        if let (head, tail) = x.decompose {
            if condition(head) { return one((head, tail)) }
        }
        return none()
    }
}

func pure<Token, Result>(value: Result) -> Parser<Token, Result> {
    return Parser { x in one((value, x)) }
}

func fail<Token, Result>() -> Parser<Token, Result> {
    return Parser { _ in none() }
}

func eof<A>() -> Parser<A, ()> {
    return Parser { stream in
        if (stream.isEmpty) {
            return one(((), stream))
        }
        return none()
    }
}



infix operator  <*> { associativity left precedence 150 }
infix operator  <*  { associativity left precedence 150 }
infix operator   *> { associativity left precedence 150 }
infix operator  <**> { associativity left precedence 150 }

infix operator  <|> { associativity right precedence 130 }

infix operator  </> { precedence 170 }
infix operator  </ { precedence 170 }

func <*><Token, A, B>(p1: Parser<Token, B -> A>, p2: Parser<Token, B>) -> Parser<Token, A> {
    return Parser {
        apply(p1.p($0)) { (f, rest) in
            map(p2.p(rest), mapFirst(f))
        }
    }
}

func <|> <Token, A>(l: Parser<Token, A>, r: Parser<Token, A>) -> Parser<Token, A> {
    return Parser { inp in
        l.p(inp) + r.p(inp)
    }
}

func <* <Token, A, B>(p: Parser<Token, A>, q: Parser<Token, B>) -> Parser<Token, A> {
    return const </> p <*> q
}

func *> <Token, A, B>(p: Parser<Token, A>, q: Parser<Token, B>) -> Parser<Token, B> {
    return { _ in {$0} } </> p <*> q
}

func <**> <Token, A, B>(p: Parser<Token, A>, q: Parser<Token, A -> B>) -> Parser<Token, B> {
    return { x in { $0(x) } } </> p <*> q
}

func </> <Token, A, B>(l: A -> B, r: Parser<Token, A>) -> Parser<Token, B> {
    return pure(l) <*> r
}

func </ <Token, A, B>(l: A, r: Parser<Token, B>) -> Parser<Token, A> {
    return pure(l) <* r
}

func optionallyApply<Token, A>(required p: Parser<Token, A>, optional q: Parser<Token, A -> A>) -> Parser<Token, A> {
    return p <**> optional(q, defaultResult: { $0 })
}

func oneOf<Token, A>(parsers: [Parser<Token, A>]) -> Parser<Token, A> {
    return parsers.reduce(fail(), combine: <|>)
}

func optional<Token, A>(p: Parser<Token, A>, #defaultResult: A) -> Parser<Token, A> {
    return p <|> pure(defaultResult)
}

func lazy<Token, A>(@autoclosure(escaping) p: () -> Parser<Token, A>) -> Parser<Token, A> {
    return Parser { x in
        return p().p(x)
    }
}

func zeroOrMore<Token, A>(p: Parser<Token, A>) -> Parser<Token, [A]> {
    return optional(prepend </> p <*> lazy(zeroOrMore(p)), defaultResult: [])
}

func oneOrMore<Token, A>(p: Parser<Token, A>) -> Parser<Token, [A]> {
    return prepend </> p <*> zeroOrMore(p)
}

func tokens<Token: Equatable>(t: [Token]) -> Parser<Token, [Token]> {
    if let (head, tail) = t.decompose {
        return prepend </> token(head) <*> tokens(tail)
    } else {
        return pure([])
    }
}

func optionalTransform<Token, A>(f: Token -> A?) -> Parser<Token, A> {
    return { f($0)! } </> satisfy { f($0) == nil ? false : true }
}


// STRING BASED PARSERS

func string(s: String) -> Parser<Character, String> {
    return const(s) </> tokens(s.characters)
}

func member(set: NSCharacterSet, character: Character) -> Bool {
    let unichar = (String(character) as NSString).characterAtIndex(0)
    return set.characterIsMember(unichar)
}

let whitespace = characters(NSCharacterSet.whitespaceAndNewlineCharacterSet())

let capital = characters(NSCharacterSet.uppercaseLetterCharacterSet())

func characters(c: NSCharacterSet) -> Parser<Character, Character> {
    return satisfy { member(c, $0) }
}

func ignoreLeadingWhitespace<A>(p: Parser<Character, A>) -> Parser<Character, A> {
    return zeroOrMore(whitespace) *> p
}

let digitParser = oneOf(Array(0...9).map { const($0) </> string("\($0)") })

func toNaturalNumber(digits: [Int]) -> Int {
    return digits.reduce(0) { $0 * 10 + $1 }
}

let naturalNumber = toNaturalNumber </> oneOrMore(digitParser)


// DEBUGGING

func debugParser<A>(parser: Parser<Character, A>, input: String) {
    for (characters, rest) in  (parser <* eof()).p(input.slice) {
        println("found \(characters), rest: \(rest)")
    }
}

func parse<A>(parser: Parser<Character, A>, input: String) -> A? {
    for (result, _) in (parser <* eof()).p(input.slice) {
        return result
    }
    return nil
}

func parse<A, B>(parser: Parser<A, B>, input: [A]) -> B? {
    for (result, _) in (parser <* eof()).p(input[0..<input.count]) {
        return result
    }
    return nil    
}






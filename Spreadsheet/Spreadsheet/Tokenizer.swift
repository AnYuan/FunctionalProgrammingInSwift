//
//  Tokenizer.swift
//  Spreadsheet
//
//  Created by Chris Eidhof on 02.07.14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Foundation



let tNumber = { Token.Number($0) } </> naturalNumber
let tOperator = { Token.Operator($0) } </> oneOf(["*", "/", "+", "-", ":"].map { string($0) })
let tReference = curry({ Token.Reference(String($0), $1) }) </> capital <*> naturalNumber
let tPunctuation = { Token.Punctuation($0) } </> oneOf(["(", ")"].map { string($0) })
let tName = { Token.FunctionName(String($0))} </> oneOrMore(capital)

func tokenize() -> Parser<Character,[Token]> {
    return zeroOrMore(ignoreLeadingWhitespace(tNumber <|> tOperator <|> tReference <|> tPunctuation <|> tName))
}

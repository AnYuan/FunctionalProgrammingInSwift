//
//  ExpressionParser.swift
//  Spreadsheet
//
//  Created by Chris Eidhof on 02.07.14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Foundation

func parseExpression(input: String) -> Expression? {
    return flatMap(parse(tokenize(), input), { parse(expression(), $0) })
}

typealias ExpressionParser = Parser<Token, Expression>


func parenthesized<A>(p: Parser<Token, A>) -> Parser<Token, A> {
    return token(Token.Punctuation("(")) *> p <* token(Token.Punctuation(")"))
}

func op(opString: String) -> Parser<Token, String> {
    return const(opString) </> token(Token.Operator(opString))
}

func combineOperands(first: Expression, rest: [(String, Expression)]) -> Expression {
    return rest.reduce(first, combine: { result, pair in
        let (op, exp) = pair
        return Expression.BinaryExpression(op, result, exp)
    })
}


let pNumber: ExpressionParser = optionalTransform {
    switch $0 {
        case .Number(let number):
            return Expression.Number(number)
        default:
            return nil
    }
}

let pReference: ExpressionParser = optionalTransform {
    switch $0 {
        case .Reference(let column, let row):
            return Expression.Reference(column, row)
        default:
            return nil
    }
}

let pNumberOrReference = pNumber <|> pReference

let pFunctionName: Parser<Token, String> = optionalTransform {
    switch $0 {
        case .FunctionName(let name):
            return name
        default:
            return nil
    }
}

func makeListExpression(l: Expression, r: Expression) -> Expression {
    return Expression.BinaryExpression(":", l, r)
}

func makeFunctionCall(l: String, r: Expression) -> Expression {
    return Expression.FunctionCall(l, r)
}

let pList: ExpressionParser = curry(makeListExpression) </> pReference <* op(":") <*> pReference
let pFunctionCall = curry(makeFunctionCall) </> pFunctionName <*> parenthesized(pList)
let pParenthesizedExpression = parenthesized(lazy(expression()))
let pPrimitive = pNumberOrReference <|> pFunctionCall <|> pParenthesizedExpression
let pSummand = curry { ($0, $1) } </> (op("-") <|> op("+")) <*> pProduct
let pMultiplier = curry { ($0, $1) } </> (op("*") <|> op("/")) <*> pPrimitive
let pSum = curry(combineOperands) </> pProduct <*> zeroOrMore(pSummand)
let pProduct = curry(combineOperands) </> pPrimitive <*> zeroOrMore(pMultiplier)

func expression() -> ExpressionParser {
    return pSum
}













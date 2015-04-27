//
//  Parser.swift
//  Spreadsheet
//
//  Created by Chris Eidhof on 01.07.14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Foundation


func lift(f: (Int,Int) -> Int) -> ((Result,Result) -> Result) {
    return { l, r in
        switch (l,r) {
        case (.IntResult(let x), .IntResult(let y)):
            return .IntResult(f(x,y))
        default:
            return .EvaluationError("Couldn't evaluate \(l) + \(r)")
        }
    }
}

// TODO: this is very strange, we need this for performance reasons. Writing the closures like {$0+$1} is really slow.
func o(f: (Int, Int) -> Int) -> (Int, Int) -> Int {
    return f
}

let integerOperators : Dictionary<String, (Int, Int) -> Int> = ["+": o(+), "/": o(/), "*": o(*),"-":o(-)]

func evaluateIntegerOperator(op: String, l: Expression, r: Expression, evaluate: Expression? -> Result) -> Result? {
    return integerOperators[op].map { lift($0)(evaluate(l), evaluate(r)) }
}

func evaluateListOperator(op: String, l: Expression, r: Expression, evaluate: Expression? -> Result) -> Result? {
    switch (op, l,r) {
        case (":", .Reference("A", let row1), .Reference("A", let row2)) where row1 <= row2:
            return Result.ListResult(Array(row1...row2).map {
                evaluate(Expression.Reference("A", $0))
            })
        default:
            return nil
    }
}

func evaluateBinary(op: String, l: Expression, r: Expression, evaluate: Expression? -> Result) -> Result {
    return evaluateIntegerOperator(op, l, r, evaluate)
        ??  evaluateListOperator(op, l, r, evaluate)
        ?? .EvaluationError("Couldn't find operator \(op)")
}

func evaluateFunction(functionName: String, parameter: Result) -> Result {
    switch (functionName, parameter) {
    case ("SUM", .ListResult(let list)):
        return list.reduce(Result.IntResult(0), combine: lift(+))
    case ("MIN", .ListResult(let list)):
        return list.reduce(Result.IntResult(Int.max), combine: lift { min($0,$1) })
    default:
        return .EvaluationError("Couldn't evaluate function")
    }
}

func evaluateExpressions(expressions: [Expression?]) -> [Result] {
    let recurse = evaluateExpression(expressions)
    return expressions.map(recurse)
}

func evaluateExpression(context: [Expression?]) -> Expression? -> Result {
    return {e in e.map { expression in
        let compute = evaluateExpression(context)
        switch (expression) {
        case .Number(let x): return Result.IntResult(x)
        case .Reference("A", let idx): return compute(context[idx])
        case .BinaryExpression(let s, let l, let r):
            return evaluateBinary(s, l.toExpression(), r.toExpression(), compute)
        case .FunctionCall(let f, let p):
            return evaluateFunction(f, compute(p.toExpression()))
        default:
            return .EvaluationError("Couldn't evaluate expression")
        }
        } ?? .EvaluationError("Couldn't parse expression")
    }
}
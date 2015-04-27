//
//  Types.swift
//  Spreadsheet
//
//  Created by Chris Eidhof on 18/08/14.
//  Copyright (c) 2014 Unsigned Integer. All rights reserved.
//

import Foundation

enum Result {
    case IntResult(Int)
    case StringResult(String)
    case ListResult([Result])
    case EvaluationError(String)
}

extension Result : Printable {
    var description: String {
        switch (self) {
            case .IntResult(let x):
                return "\(x)"
            case .StringResult(let s):
                return "\(s)"
            case .ListResult(let s):
                return s.description
            case .EvaluationError(let e):
                return "Error: \(e)"
        }
    }
}

protocol ExpressionLike : Printable {
    func toExpression() -> Expression
}

enum Expression {
    case Number(Int)
    case Reference(String, Int)
    case BinaryExpression(String, ExpressionLike, ExpressionLike)
    case FunctionCall(String, ExpressionLike)
}

extension Expression : ExpressionLike {
    func toExpression() -> Expression {
        return self
    }
}

enum Token : Equatable {
    case Number(Int)
    case Operator(String)
    case Reference(String, Int)
    case Punctuation(String)
    case FunctionName(String)
}


func ==(lhs: Token, rhs: Token) -> Bool {
    switch (lhs,rhs) {
        case (.Number(let x), .Number(let y)):
            return x == y
        case (.Operator(let x), .Operator(let y)):
            return x == y
        case (.Reference(let row, let column), .Reference(let row1, let column1)):
            return row == row1 && column == column1
        case (.Punctuation(let x), .Punctuation(let y)):
            return x == y
        case (.FunctionName (let x), .FunctionName(let y)):
            return x == y
        default:
            return false
    }
}


extension Token : Printable {
    var description: String {
        switch (self) {
            case Number(let x):
                return "\(x)"
            case .Operator(let o):
                return o
            case .Reference(let row, let column):
                return "\(row)\(column)"
            case .Punctuation(let x):
                return x
            case .FunctionName(let x):
                return x
        }
    }
}


extension Expression : Printable {
    var description: String {
        switch (self) {
            case .Number(let x):
                return "\(x)"
            case .Reference(let row, let column):
                return "\(row)\(column)"
            case .BinaryExpression(let op, let lhs, let rhs):
                return "(\(lhs.toExpression())) \(op) (\(rhs.toExpression()))"
            case .FunctionCall(let f, let param):
                return "\(f)(\(param.toExpression()))"
        }
    }
}
//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Raquel Taboada on 3/28/15.
//  Copyright (c) 2015 Raquel Taboada. All rights reserved.
//

import Foundation

class CalculatorBrain: Printable {
    
    private enum Op: Printable {
        case Operand(Double)
        case ConstantOperation(String, Void -> Double)
        case UnaryOperation(String, Double -> Double)
        case BinaryOperation(String, (Double, Double) -> Double)
        case VarOperation(String)
        
        var description: String {
            get {
                switch self {
                case Operand(let operand):
                    return "\(operand)"
                case ConstantOperation(let symbol, _):
                    return symbol
                case UnaryOperation(let symbol, _):
                    return symbol
                case BinaryOperation(let symbol, _):
                    return symbol
                case VarOperation(let symbol):
                    return symbol
                }
            }
        }
        
        var precedence: Int {
            get {
                switch self {
                case BinaryOperation(let symbol, _):
                    switch symbol {
                    case "+":
                        return 1
                    case "−":
                        return 1
                    case "×":
                        return 2
                    case "÷":
                        return 2
                    default:
                        return Int.max
                    }
                default:
                    return Int.max
                }
            }
        }
    }
    
    private var opStack = [Op]()
    
    private var knowOps = [String: Op]()

    var variablesValues = [String: Double]()
    
    init() {
        func learnOp(op:Op) {
            knowOps[op.description] = op
        }
        learnOp(Op.BinaryOperation("×", *))
        learnOp(Op.BinaryOperation("÷") { $1 / $0 })
        learnOp(Op.BinaryOperation("+", +))
        learnOp(Op.BinaryOperation("−") { $1 - $0 })
        learnOp(Op.UnaryOperation("√", sqrt))
        learnOp(Op.UnaryOperation("sin", sin))
        learnOp(Op.UnaryOperation("cos", cos))
        learnOp(Op.UnaryOperation("±") { -$0 })
        learnOp(Op.ConstantOperation("π") { M_PI })
    }
    
    var program: AnyObject { // guaranteed to be a PropertyList
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                
                for opSymbol in opSymbols {
                    if let op = knowOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    }
                }
            }
        }
    }
    
    var description: String {
        get {
            var ops = opStack
            var desc = ""
            
            while !ops.isEmpty {
                let (result, remaining) = printOps(ops, precedence: 0)
                
                if desc.isEmpty {
                    desc = result
                } else {
                    desc = "\(result), \(desc)"
                }
                ops = remaining
            }
            
            return desc
        }
    }
    
    private func printOps(ops: [Op], precedence: Int) -> (result: String, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            
            switch op {
            case .Operand(let operand):
                if precedence < op.precedence {
                    return ("\(operand)", remainingOps)
                } else {
                    return ("(\(operand))", remainingOps)
                }
            case .ConstantOperation(_):
                if precedence < op.precedence {
                    return ("\(op)", remainingOps)
                } else {
                    return ("(\(op))", remainingOps)
                }
                
            case .UnaryOperation(_):
                let (operand, remaining) = printOps(remainingOps, precedence: op.precedence)
                if precedence > op.precedence {
                    return ("(\(op)\(operand))", remaining)
                } else {
                    return ("\(op)\(operand)", remaining)
                }
                
            case .BinaryOperation(_):
                let (operand1, remaining1) = printOps(remainingOps, precedence: op.precedence)
                let (operand2, remaining2) = printOps(remaining1, precedence: op.precedence)
                
                if precedence > op.precedence {
                    return ("(\(operand2) \(op) \(operand1))", remaining2)
                } else {
                    return ("\(operand2) \(op) \(operand1)", remaining2)
                }
                
            case .VarOperation(_):
                if precedence < op.precedence {
                    return ("\(op)", remainingOps)
                } else {
                    return ("(\(op))", remainingOps)
                }
            }
        }
        
        return ("?", ops)
    }
    
    func evaluate() -> Double? {
        let (result, remainder) = evaluate(opStack)
        return result
    }
    
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .ConstantOperation(_, let operation):
                return (operation(), remainingOps)
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, let operation):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                    
                }
            case .VarOperation(let symbol):
                return (variablesValues[symbol], remainingOps)
            }
        }
        
        return (nil, ops)
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.VarOperation(symbol))
        return evaluate()
    }
    
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func popOperand() -> Double? {
        if !opStack.isEmpty {
            opStack.removeLast()
        }
        return evaluate()
    }
    
    func performOperation(symbol: String) -> Double? {
        if let operation = knowOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
}

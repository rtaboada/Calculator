//
//  ViewController.swift
//  Calculator
//
//  Created by Raquel Taboada on 3/24/15.
//  Copyright (c) 2015 Raquel Taboada. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    
    var userIsTypingANumber = false
    
    var brain = CalculatorBrain()
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        
        if digit == "." && (display.text!.rangeOfString(".") != nil) {
            return
        }
        
        if userIsTypingANumber {
            display.text = display.text! + digit
        } else {
            display.text = digit
            userIsTypingANumber = true
        }
    }
    
    @IBAction func operate(sender: UIButton) {
        if userIsTypingANumber {
            enter()
        }
        
        if let operation = sender.currentTitle {
            displayValue = brain.performOperation(operation)
        }
    }
    
    @IBAction func plusMinus() {
        if userIsTypingANumber {
            if let digits = display.text {
                if first(digits) == "-" {
                    display.text = dropFirst(digits)
                } else {
                    display.text = "-" + digits
                }
            }
        } else {
            displayValue = brain.performOperation("±")
        }
        
    }
    
    @IBAction func clear() {
        brain = CalculatorBrain()
        
        displayValue = nil
    }
    
    @IBAction func undo() {
        if userIsTypingANumber {
            // Undo appendDigit
            if let digits = display.text {
                if countElements(digits) > 1 {
                    display.text = dropLast(digits)
                } else {
                    display.text = " "
                }
            }
        } else {
            // Pop last Op
            displayValue = brain.popOperand()
        }
    }
    
    @IBAction func enter() {
        if let value = displayValue {
            displayValue = brain.pushOperand(value)
        }
    }
    
    @IBAction func pushVariable() {
        if userIsTypingANumber {
            enter()
        }
        displayValue = brain.pushOperand("M")
    }
    
    @IBAction func setVariable() {
        if let value = displayValue {
            brain.variablesValues["M"] = value
            displayValue = brain.evaluate()
        }
    }
    
    var displayValue: Double? {
        get {
            return NSNumberFormatter().numberFromString(display.text!)?.doubleValue
        }
        set {
            if let value = newValue {
                display.text = "\(value)"
                userIsTypingANumber = false
            } else {
                display.text = " "
            }
            history.text = "\(brain) ="
        }
    }
}


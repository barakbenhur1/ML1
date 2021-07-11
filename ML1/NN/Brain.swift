//
//  NeuralNetworkML.swift
//  ML1
//
//  Created by ברק בן חור on 08/07/2021.
//

import Foundation
import UIKit

fileprivate let singalSem: DispatchSemaphore = DispatchSemaphore(value: 1)
private let iterations = 1000
private let randomCaycles = 1000

class Brain<T: FloatingPoint> {
    
//    private var neuralNetwork: [Perceptron]!
    
    private let number_of_input: Int!
    private let number_of_hidden: Int!
    private let number_of_outputs: Int!
    
    private let input_to_hidden: Matrix<T>!
    private let hidden_to_output: Matrix<T>!
    
    private let bias_hidden: Matrix<T>!
    private let bias_output: Matrix<T>!
    
    private let learning_rate: T!
    
    private var activeFunction: ((T) -> (T))!
    
    private var sem = DispatchSemaphore(value: 1)
    
    init(number_of_input: Int, number_of_hidden: Int, number_of_outputs: Int, learning_rate: T = learningRate(), valueInitFunction: @escaping () -> (T)) {
        self.number_of_input = number_of_input
        self.number_of_hidden = number_of_hidden
        self.number_of_outputs = number_of_outputs
        self.learning_rate = learning_rate
        self.input_to_hidden = Matrix(rows: number_of_hidden, cols: number_of_input, valueInitFunction: valueInitFunction)
        self.hidden_to_output = Matrix(rows: number_of_outputs, cols: number_of_hidden, valueInitFunction: valueInitFunction)
        self.bias_hidden = Matrix(rows: number_of_hidden, cols: 1, valueInitFunction: valueInitFunction)
        self.bias_output = Matrix(rows: number_of_outputs, cols: 1, valueInitFunction: valueInitFunction)
//        self.neuralNetwork = [Perceptron]()
    }
    
    func predict(inputs: [T]) -> [T] {
        sem.wait()
        let inputsMatrix = Matrix<T>.fromArray(other: [inputs])
        
        let hidden = try? Matrix<T>.multiply(m1: input_to_hidden, m2: inputsMatrix)
        
        hidden!.add(other: bias_hidden)
        
        hidden?.map(function: activeFunction)
        
        let output = try? Matrix<T>.multiply(m1: hidden_to_output , m2: hidden!)
        
        output?.add(other: bias_output)
        
        output?.map(function: activeFunction)
        
        defer {
            sem.signal()
        }
        
        return output!.values
    }
    
    private func train(inputs: [T], targets: [T], activeFunction: @escaping (T) -> (T), deActiveFunction: @escaping (T) -> (T)) {
        
        sem.wait()
        
        let inputsMatrix = Matrix<T>.fromArray(other: [inputs])
        
        let hiddenMatrix = try? Matrix<T>.multiply(m1: input_to_hidden, m2: inputsMatrix)
        
        hiddenMatrix!.add(other: bias_hidden)
        
        hiddenMatrix?.map(function: activeFunction)
        
        
        let outputsMatrix = try? Matrix<T>.multiply(m1: hidden_to_output , m2: hiddenMatrix!)
        
        outputsMatrix?.add(other: bias_output)
        
        outputsMatrix?.map(function: activeFunction)
        
        
        let targetMatrix = Matrix<T>.fromArray(other: [targets])
        
       
        let outputsError = try? Matrix<T>.subtract(m1: targetMatrix, m2: outputsMatrix!)
    
        
        let gradients = try? Matrix<T>.map(m: outputsMatrix!, function: deActiveFunction)
       
        gradients!.multiplyByCell(other: outputsError!)
        
        gradients!.multiply(n: learning_rate)
        
        
        let hiddenT = try? Matrix<T>.transpose(m: hiddenMatrix!)
        
        let hiddenToOutputDaltas = try? Matrix<T>.multiply(m1: gradients!, m2: hiddenT!)
        
       
        hidden_to_output.add(other: hiddenToOutputDaltas!)
        
        bias_output.add(other: gradients!)
        
        
        let hiddenToOutputT = try? Matrix<T>.transpose(m: hidden_to_output)
        
        let hiddenErrors = try? Matrix<T>.multiply(m1: hiddenToOutputT!, m2: outputsError!)
        
        
        let hiddenGradients = try? Matrix<T>.map(m: hiddenMatrix!, function: deActiveFunction)
        
        hiddenGradients?.multiplyByCell(other: hiddenErrors!)
        
        hiddenGradients?.multiply(n: learning_rate)
        
        
        let inputT = try? Matrix<T>.transpose(m: inputsMatrix)
        let inputToHiddenDaltas = try? Matrix<T>.multiply(m1: hiddenGradients! , m2: inputT!)
        
        input_to_hidden.add(other: inputToHiddenDaltas!)
        
        bias_hidden.add(other: hiddenGradients!)
        
        sem.signal()
    }
    
    private static func create<T: FloatingPoint>(file: String, number_of_input: Int, number_of_hidden: Int, number_of_outputs: Int, valueInitFunction: @escaping  (() -> (T)), learning_rate: @escaping () -> (T)) -> Brain<T> {
        
        let name = String(describing: file)
        
        singalSem.wait()
        if  Brain<T>.getInstances()![name] == nil {
            let o = Brain<T>(number_of_input: number_of_input, number_of_hidden: number_of_hidden, number_of_outputs: number_of_outputs, learning_rate: learning_rate(), valueInitFunction: valueInitFunction)
            Brain<T>.addInstances(key: name, value: o)
        }
        
        defer {
            singalSem.signal()
        }
        
        
        return Brain<T>.getInstances()![name]!
    }
    
    enum ActivationMethod {
        case sigmoid, custom(activtionmethod: (_ x: T) -> (T), deDctivtionmethod: (_ x: T) -> (T)), none
        
        func getActivtionMethod() -> (T) -> (T) {
            switch self {
            case .sigmoid:
                return Brain<T>.sigmoid(x:) as! (T) -> (T)
            case .custom(let active, _):
                return active
            default:
                return { x in
                    return x * -1
                }
            }
        }
        
        func getDeActivtionMethod() -> (T) -> (T) {
            switch self {
            case .sigmoid:
                return Brain<T>.dsigmoid(x:) as! (T) -> (T)
            case .custom( _, let deActive):
                return deActive
            default:
                return { x in
                    return x
                }
            }
        }
    }

    func start(inputs: [[T]], targets: [[T]], file: String = #file, line: Int = #line, function: String = #function, ativtionMethod: ActivationMethod = .sigmoid, learning_rate: T? = nil, valueInitFunction: (() -> (T))? = nil) {
        
        let activeFunction = ativtionMethod.getActivtionMethod()
        let deActiveFunction = ativtionMethod.getDeActivtionMethod()
        self.activeFunction = activeFunction
        
        for _ in 0..<iterations {
            for _ in 0..<randomCaycles {
                let index = Int.random(in: 0..<inputs.count)
                train(inputs: inputs[index], targets: targets[index] ,activeFunction: activeFunction, deActiveFunction: deActiveFunction)
            }
        }
    }
    
    static func start(inputs: [[T]], targets: [[T]], file: String = #file, line: Int = #line, function: String = #function, ativtionMethod: ActivationMethod = .sigmoid, learning_rate: T? = nil, valueInitFunction: (() -> (T))? = nil, brainObj: @escaping (Brain<T>) -> (), completed: @escaping  () -> ()) {
        let number_of_hidden = inputs[0].count
        let brain = Brain<T>.create(file: file, number_of_input: inputs[0].count, number_of_hidden: number_of_hidden, number_of_outputs: targets[0].count, valueInitFunction: {
            return valueInitFunction != nil ? valueInitFunction!() : random()
        }, learning_rate: {
            return learning_rate ?? learningRate()
        })

        let activeFunction = ativtionMethod.getActivtionMethod()
        let deActiveFunction = ativtionMethod.getDeActivtionMethod()
        brain.activeFunction = activeFunction
        
        brainObj(brain)
        
        for _ in 0..<iterations {
            for _ in 0..<randomCaycles {
                let index = Int.random(in: 0..<inputs.count)
                brain.train(inputs: inputs[index], targets: targets[index] ,activeFunction: activeFunction, deActiveFunction: deActiveFunction)
            }
        }
        
        completed()
    }
    
    private static func random() -> T {
        switch T.self {
        case is CGFloat.Type:
            return Brain<CGFloat>.random() as! T
        case is Double.Type:
            return Brain<Double>.random() as! T
        case is Float.Type:
            return Brain<Float>.random() as! T
        case is Float16.Type:
            return Brain<Float16>.random() as! T
        default:
            fatalError("Unsupported Type")
        }
    }
    
    private static func learningRate() -> T {
        switch T.self {
        case is CGFloat.Type:
            return Brain<CGFloat>.learningRate() as! T
        case is Double.Type:
            return Brain<Double>.learningRate() as! T
        case is Float.Type:
            return Brain<Float>.learningRate() as! T
        case is Float16.Type:
            return Brain<Float16>.learningRate() as! T
        default:
            fatalError("Unsupported Type")
        }
    }
    
    private static func sigmoid(x: CGFloat) -> CGFloat {
        return 1 / (1 + Brain<CGFloat>.getOppositeExp(x: x))
    }
    
    private static func dsigmoid(x: CGFloat) -> CGFloat {
        return x * (1 - x)
    }
    
    private static func getInstances() -> [String: Brain<T>]? {
        switch T.self {
        case is CGFloat.Type:
            return Brain<CGFloat>.instances as? [String: Brain<T>]
        case is Double.Type:
            return Brain<Double>.instances as? [String: Brain<T>]
        case is Float.Type:
            return Brain<Float>.instances as? [String: Brain<T>]
        case is Float16.Type:
            return Brain<Float16>.instances as? [String: Brain<T>]
        default:
            fatalError("Unsupported Type")
        }
    }
    
    private static func addInstances(key: String, value: Brain<T>) {
        switch T.self {
        case is CGFloat.Type:
            Brain<CGFloat>.addValue(key: key, value: value as! Brain<CGFloat>)
        case is Double.Type:
            Brain<Double>.addValue(key: key, value: value as! Brain<Double>)
        case is Float.Type:
            Brain<Float>.addValue(key: key, value: value as! Brain<Float>)
        case is Float16.Type:
            Brain<Float16>.addValue(key: key, value: value as! Brain<Float16>)
        default:
            fatalError("Unsupported Type")
        }
    }
}

extension Brain where T == CGFloat {
    static var instances: [String: Brain<T>] = [String: Brain<T>]()
    
    private static func getOppositeExp(x: T) -> T {
        return exp(-x)
    }
    
    private static func addValue(key: String, value: Brain<T>) {
        instances[key] = value
    }
    
    private static func random() -> T {
        return CGFloat.random(in: -1...1)
    }
    
    private static func learningRate() -> T {
        return 0.1
    }
}

extension Brain where T == Double {
    static var instances: [String: Brain<T>] = [String: Brain<T>]()
    
    private static func getOppositeExp(x: T) -> T {
        return exp(-x)
    }
    
    private static func addValue(key: String, value: Brain<T>) {
        instances[key] = value
    }
    
    private static func random() -> T {
        return Double.random(in: -1...1)
    }
    
    private static func learningRate() -> T {
        return 0.1
    }
}

extension Brain where T == Float {
    static var instances: [String: Brain<T>] = [String: Brain<T>]()
    
    private static func getOppositeExp(x: T) -> T {
        return exp(-x)
    }
    
    private static func addValue(key: String, value: Brain<T>) {
        instances[key] = value
    }
    
    private static func random() -> T {
        return Float.random(in: -1...1)
    }
    
    private static func learningRate() -> T {
        return 0.1
    }
}

extension Brain where T == Float16 {
    static var instances: [String: Brain<T>] = [String: Brain<T>]()
    
    private static func getOppositeExp(x: T) -> T {
        return 0
    }
    
    private static func addValue(key: String, value: Brain<T>) {
        instances[key] = value
    }
    
    private static func random() -> T {
        return Float16.random(in: -1...1)
    }
    
    private static func learningRate() -> T {
        return 0.1
    }
}

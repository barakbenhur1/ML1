//
//  NeuralNetworkML.swift
//  ML1
//
//  Created by ברק בן חור on 08/07/2021.
//

import Foundation
import UIKit

fileprivate var singalSem: DispatchSemaphore? = DispatchSemaphore(value: 1)

private var stopStatic = false

class Brain<T: FloatingPoint & Codable>: Codable {
    
//    private var neuralNetwork: [Perceptron]!
    
    enum CodingKeys: String, CodingKey {
        case number_of_input, number_of_hidden, number_of_outputs, input_to_hidden, hidden_to_output, bias_hidden, bias_output, learning_rate, iterations, randomCaycles
    }
    
    private lazy var description = {
        return String(UInt(bitPattern: ObjectIdentifier(self)))
    }()
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number_of_input = try container.decode(Int.self, forKey: .number_of_input)
        number_of_hidden = try container.decode(Int.self, forKey: .number_of_hidden)
        number_of_outputs = try container.decode(Int.self, forKey: .number_of_outputs)
        input_to_hidden = try container.decode(Matrix<T>.self, forKey: .input_to_hidden)
        hidden_to_output = try container.decode(Matrix<T>.self, forKey: .hidden_to_output)
        bias_hidden = try container.decode(Matrix<T>.self, forKey: .bias_hidden)
        bias_output = try container.decode(Matrix<T>.self, forKey: .bias_output)
        learning_rate = try container.decode(T.self, forKey: .learning_rate)
        iterations = try container.decode(Int.self, forKey: .iterations)
        randomCaycles = try container.decode(Int.self, forKey: .randomCaycles)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(number_of_input, forKey: .number_of_input)
        try container.encode(number_of_hidden, forKey: .number_of_hidden)
        try container.encode(number_of_outputs, forKey: .number_of_outputs)
        try container.encode(input_to_hidden, forKey: .input_to_hidden)
        try container.encode(hidden_to_output, forKey: .hidden_to_output)
        try container.encode(bias_hidden, forKey: .bias_hidden)
        try container.encode(bias_output, forKey: .bias_output)
        try container.encode(learning_rate, forKey: .learning_rate)
        try container.encode(iterations, forKey: .iterations)
        try container.encode(randomCaycles, forKey: .randomCaycles)
    }
    
    public func hash(into hasher: inout Hasher) {
        self.hash(into: &hasher)
        "\(self)".hash(into: &hasher)
    }
    
    
    private let number_of_input: Int!
    private let number_of_hidden: Int!
    private let number_of_outputs: Int!
    
    private let input_to_hidden: Matrix<T>!
    private let hidden_to_output: Matrix<T>!
    
    private let bias_hidden: Matrix<T>!
    private let bias_output: Matrix<T>!
    
    private var learning_rate: T!
    
    private var activeFunction: ((T) -> (T))!
    private var deActiveFunction: ((T) -> (T))!
    
    private var sem = DispatchSemaphore(value: 1)
    
    private var iterations = 3000
    
    private var randomCaycles = 2000
    
    deinit {
        
    }
    
    private init(number_of_input: Int, number_of_hidden: Int, number_of_outputs: Int, learning_rate: T = learningRate(), valueInitFunction: @escaping () -> (T)) {
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
        defer {
            sem.signal()
        }
        
        return feedForword(inputs: inputsMatrix).output.values
    }
    
    private func feedForword(inputs: Matrix<T>) -> (hidden: Matrix<T> , output: Matrix<T>) {
        
        let hidden = try? Matrix<T>.multiply(m1: input_to_hidden, m2: inputs)
        
        hidden!.add(other: bias_hidden)
        
        hidden?.map(function: activeFunction)
        
        let output = try? Matrix<T>.multiply(m1: hidden_to_output , m2: hidden!)
        
        output?.add(other: bias_output)
        
        output?.map(function: activeFunction)
        
        return (hidden!, output!)
    }
    
    private func train(inputs: [T], targets: [T], activeFunction: @escaping (T) -> (T), deActiveFunction: @escaping (T) -> (T)) {
        
        sem.wait()
        
        let inputsMatrix = Matrix<T>.fromArray(other: [inputs])
        
        let feedData = feedForword(inputs: inputsMatrix)
        
        let hiddenMatrix = feedData.hidden
        
        let outputsMatrix = feedData.output
        
        
        let targetMatrix = Matrix<T>.fromArray(other: [targets])
        
       
        let outputsError = try? Matrix<T>.subtract(m1: targetMatrix, m2: outputsMatrix)
    
        
        let gradients = try? Matrix<T>.map(m: outputsMatrix, function: deActiveFunction)
       
        gradients!.multiplyByCell(other: outputsError!)
        
        gradients!.multiply(n: learning_rate)
        
        
        let hiddenT = try? Matrix<T>.transpose(m: hiddenMatrix)
        
        let hiddenToOutputDaltas = try? Matrix<T>.multiply(m1: gradients!, m2: hiddenT!)
        
       
        hidden_to_output.add(other: hiddenToOutputDaltas!)
        
        bias_output.add(other: gradients!)
        
        
        let hiddenToOutputT = try? Matrix<T>.transpose(m: hidden_to_output)
        
        let hiddenErrors = try? Matrix<T>.multiply(m1: hiddenToOutputT!, m2: outputsError!)
        
        
        let hiddenGradients = try? Matrix<T>.map(m: hiddenMatrix, function: deActiveFunction)
        
        hiddenGradients?.multiplyByCell(other: hiddenErrors!)
        
        hiddenGradients?.multiply(n: learning_rate)
        
        
        let inputT = try? Matrix<T>.transpose(m: inputsMatrix)
        let inputToHiddenDaltas = try? Matrix<T>.multiply(m1: hiddenGradients! , m2: inputT!)
        
        input_to_hidden.add(other: inputToHiddenDaltas!)
        
        bias_hidden.add(other: hiddenGradients!)
        
        sem.signal()
    }
    
    private static func create<T: FloatingPoint>(file: String, number_of_input: Int, number_of_hidden: Int, number_of_outputs: Int, valueInitFunction: @escaping  (() -> (T)), learning_rate: @escaping () -> (T)) -> Brain<T> {
        
        guard (singalSem != nil) else { fatalError("Error Occurred") }
        
        let name = String(describing: file)
        
        singalSem?.wait()
        if  Brain<T>.getInstances()![name] == nil {
            let o = Brain<T>(number_of_input: number_of_input, number_of_hidden: number_of_hidden, number_of_outputs: number_of_outputs, learning_rate: learning_rate(), valueInitFunction: valueInitFunction)
            Brain<T>.addInstances(key: name, value: o)
        }
        
        defer {
            singalSem?.signal()
        }
        
        
        return Brain<T>.getInstances()![name]!
    }
    
    static func create<T: FloatingPoint>(file: String = #file, number_of_input: Int, number_of_hidden: Int, number_of_outputs: Int, learning_rate: T? = nil, valueInitFunction: (() -> (T))? = nil) -> Brain<T> {
        
        guard (singalSem != nil) else { fatalError("Error Occurred") }
        
        let name = String(describing: file)
        
        singalSem?.wait()
        if  Brain<T>.getInstances()![name] == nil {
            let o = Brain<T>(number_of_input: number_of_input, number_of_hidden: number_of_hidden, number_of_outputs: number_of_outputs, learning_rate: learning_rate ?? Brain<T>.learningRate(), valueInitFunction: valueInitFunction ?? Brain<T>.random)
            Brain<T>.addInstances(key: name, value: o)
        }
        
        defer {
            singalSem?.signal()
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
    
    private var brainObj: ((Brain<T>) -> ())?
    
    private var stopRun: Bool = false
    
    static func stop() {
        stopStatic = true
    }
    
    func stop() {
        stopRun = true
    }

    func start(inputs: [[T]], targets: [[T]], iterations: Int? = nil, numberOfTraningsForIteration: Int? = nil, file: String = #file, line: Int = #line, function: String = #function, ativtionMethod: ActivationMethod = .sigmoid, valueInitFunction: (() -> (T))? = nil, progressUpdate: ((_ iteration: Int) -> ())? = nil, completed: (() -> ())? = nil) {
        
        stopRun = false
        stopStatic = false
        
        set_ativtion_method(ativtionMethod)
        set_learning_iterations(iterations: iterations ?? self.iterations)
        set_learning_number_tranings_for_iteration(number: numberOfTraningsForIteration ?? self.randomCaycles)
        
        brainObj?(self)
        
        for i in 0..<self.iterations {
            guard !stopRun && !stopStatic else { return }
            for _ in 0..<randomCaycles {
                guard !stopRun && !stopStatic else { return }
                let index = Int.random(in: 0..<inputs.count)
                train(inputs: inputs[index], targets: targets[index] ,activeFunction: activeFunction, deActiveFunction: deActiveFunction)
            }
            
            progressUpdate?(i)
        }
        
        completed?()
    }
    
    static func start(inputs: [[T]], targets: [[T]], iterations: Int? = nil, numberOfTraningsForIteration: Int? = nil, file: String = #file, line: Int = #line, function: String = #function, ativtionMethod: ActivationMethod = .sigmoid, learning_rate: T? = nil, valueInitFunction: (() -> (T))? = nil, brainObj: @escaping (Brain<T>) -> (), progressUpdate: ((_ iteration: Int) -> ())? = nil, completed: (() -> ())? = nil) {
        let number_of_hidden = inputs[0].count
        let brain = Brain<T>.create(file: file, number_of_input: inputs[0].count, number_of_hidden: number_of_hidden, number_of_outputs: targets[0].count, valueInitFunction: {
            return valueInitFunction != nil ? valueInitFunction!() : random()
        }, learning_rate: {
            return learning_rate ?? learningRate()
        })
        
        brain.brainObj = brainObj

        brain.start(inputs: inputs, targets: targets, iterations: iterations, numberOfTraningsForIteration: numberOfTraningsForIteration, ativtionMethod: ativtionMethod, valueInitFunction: valueInitFunction, progressUpdate: progressUpdate, completed: completed)
    }
    
    func set_learning_iterations(iterations: Int) {
        self.iterations = iterations
    }
    
    func set_learning_number_tranings_for_iteration(number: Int) {
        self.randomCaycles = number
    }
    
    func set_learning_rate(learning_rate: T) {
        self.learning_rate = learning_rate
    }
    
    func set_ativtion_method(_ activationMethod: ActivationMethod) {
        self.activeFunction = activationMethod.getActivtionMethod()
        self.deActiveFunction = activationMethod.getDeActivtionMethod()
    }
    
    func printDescription(inputs:[[T]], targets: [[T]], title: String) {
        
        var strings = [String]()
       
        for i in 0..<inputs.count {
            let s = "Input: \(inputs[i]), Prediction: \(predict(inputs: inputs[i] )), Real Answer: \(targets[i])"
            strings.append(s)
        }
        
        var max = 0
        
        for s in strings {
            if max < s.count {
                max = s.count
            }
        }
        
        let s = String(repeating: "=", count:(max / 2) - (title.count / 2) + 8)
        print("\(s)\(title)\(s)")
        print("        \(strings[0])")
        print("        \(strings[1])")
        print("        \(strings[2])")
        print("        \(strings[3])")
        print("\(s)\(String(repeating: "=", count: title.count))\(s)")
        print()
    }
    
    @discardableResult private func saveGeneration(key: String) -> Bool {
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask).first {
            let pathWithFilename = documentDirectory.appendingPathComponent("ML+\(key).json")
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(self)
                let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
                try jsonString?.write(to: pathWithFilename,
                                     atomically: true,
                                     encoding: .utf8)
                return true
            } catch {
                print("save fail: \(error.localizedDescription)")
                return false
            }
        }
        
        return false
    }
    
    
    private static func readLocalJSONFile(forName name: String) -> Data? {
        do {
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                                                                in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("\(name).json")
                //                let fileUrl = URL(fileURLWithPath: filePath)
                let data = try Data(contentsOf: fileURL)
                return data
            }
        } catch {
            print("error: \(error)")
        }
        return nil
    }
    
    private static func parse(jsonData: Data) -> Brain<T>? {
        do {
            let decodedData = try JSONDecoder().decode(Brain<T>.self, from: jsonData)
            return decodedData
        } catch {
            print("error: \(error)")
        }
        return nil
    }
    
    @discardableResult static private func loadGeneration(key: String) -> Brain<T>? {
        if let data = readLocalJSONFile(forName: "ML+\(key)") {
            guard let ml = parse(jsonData: data) else {
                return nil
            }
            
            if singalSem == nil {
                singalSem =  DispatchSemaphore(value: 1)
            }
           
            ml.sem = DispatchSemaphore(value: 1)
            
            let method: ActivationMethod = .sigmoid
            ml.activeFunction = method.getActivtionMethod()
            ml.activeFunction = method.getDeActivtionMethod()
            
            return ml
        }
        
        return nil
    }
    
    func save(name: String = "ML") {
        sem.wait()
        let success = saveGeneration(key: name)
        sem.signal()
        print(success)
    }
    
    func load(name: String = "ML") -> Brain<T>? {
        sem.wait()
        defer {
            sem.signal()
        }
        return Brain<T>.load(name: name)
    }
    
    static func load(name: String = "ML") -> Brain<T>? {
        return loadGeneration(key: name)
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

//
//  NeuralNetworkML.swift
//  ML1
//
//  Created by ברק בן חור on 08/07/2021.
//

import Foundation
import UIKit

fileprivate var singalSem: DispatchSemaphore? = DispatchSemaphore(value: 1)
private var sem: DispatchSemaphore? = DispatchSemaphore(value: 1)

private var stopStatic = false

class Brain<T: Numeric & Codable>: Codable {
    
    enum CodingKeys: String, CodingKey {
        case number_of_input, number_of_hidden, number_of_outputs, input_to_hidden, hidden_to_output, bias_hidden, bias_output, learning_rate, iterations, randomCaycles, label
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
        label = try container.decode(String.self, forKey: .label)
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
        try container.encode(label, forKey: .label)
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
    
    private var valueInitFunction: (() -> (T))!
    
    private var label: String = ""
    
    private var iterations = 3000
    
    private var randomCaycles = 2000
    
    deinit {
        print("deinit...")
    }
    
    private init(number_of_input: Int, number_of_hidden: Int, number_of_outputs: Int, input_to_hidden: Matrix<T>, hidden_to_output: Matrix<T>, bias_hidden: Matrix<T>, bias_output: Matrix<T>, learning_rate: T = learningRate(), valueInitFunction: @escaping () -> (T)) {
        
        self.number_of_input = number_of_input
        self.number_of_hidden = number_of_hidden
        self.number_of_outputs = number_of_outputs
        self.learning_rate = learning_rate
        self.valueInitFunction = valueInitFunction
        
        self.input_to_hidden = input_to_hidden
        self.hidden_to_output = hidden_to_output
        self.bias_hidden = bias_hidden
        self.bias_output = bias_output
    }
    
    private convenience init(number_of_input: Int, number_of_hidden: Int, number_of_outputs: Int, learning_rate: T = learningRate(), valueInitFunction: @escaping () -> (T)) {
        
        self.init(number_of_input: number_of_input, number_of_hidden: number_of_hidden, number_of_outputs: number_of_outputs, input_to_hidden: Matrix(rows: number_of_hidden, cols: number_of_input, valueInitFunction: valueInitFunction), hidden_to_output: Matrix(rows: number_of_outputs, cols: number_of_hidden, valueInitFunction: valueInitFunction), bias_hidden: Matrix(rows: number_of_hidden, cols: 1, valueInitFunction: valueInitFunction), bias_output: Matrix(rows: number_of_outputs, cols: 1, valueInitFunction: valueInitFunction), learning_rate: learning_rate, valueInitFunction: valueInitFunction)
    }
    
    private convenience init(brain: Brain<T>) {
        
        self.init(number_of_input: brain.number_of_input, number_of_hidden: brain.number_of_hidden, number_of_outputs: brain.number_of_outputs, input_to_hidden:  Matrix(other: brain.input_to_hidden), hidden_to_output:  Matrix(other: brain.hidden_to_output), bias_hidden: Matrix(other: brain.bias_hidden), bias_output: Matrix(other: brain.bias_output), learning_rate: brain.learning_rate, valueInitFunction:  brain.valueInitFunction)
    }
    
    func predict(inputs: [T]) -> [T] {
        sem?.wait()
        let inputsMatrix = Matrix<T>.fromMatrixArray(other: [inputs])
        defer {
            sem?.signal()
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
        
        sem?.wait()
        
        let inputsMatrix = Matrix<T>.fromMatrixArray(other: [inputs])
        
        let feedData = feedForword(inputs: inputsMatrix)
        
        let hiddenMatrix = feedData.hidden
        
        let outputsMatrix = feedData.output
        
        
        let targetMatrix = Matrix<T>.fromMatrixArray(other: [targets])
        
        
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
        
        sem?.signal()
    }
    
    private static func create<T: Numeric>(file: String = #file, number_of_input: Int, number_of_hidden: Int, number_of_outputs: Int, learning_rate: T? = nil, initFunction: (() -> (T))? = nil) -> Brain<T> {
        
        guard (singalSem != nil) else { fatalError("Error Occurred") }
        
        let name = String(describing: file)
        
        singalSem?.wait()
        if Brain<T>.getInstances()![name] == nil {
            let o = Brain<T>(number_of_input: number_of_input, number_of_hidden: number_of_hidden, number_of_outputs: number_of_outputs, learning_rate: learning_rate ?? Brain<T>.learningRate(), valueInitFunction: initFunction ?? Brain<T>.random)
            Brain<T>.addInstances(key: name, value: o)
        }
        
        defer {
            singalSem?.signal()
        }
        
        let brain = Brain<T>.getInstances()![name]!
        
        brain.label = file
        
        return brain
    }
    
    static func create<T: Numeric>(label: String = #file, number_of_input: Int, number_of_hidden: Int, number_of_outputs: Int, learning_rate: T? = nil, valueInitFunction: (() -> (T))? = nil) -> Brain<T> {
        return Brain<T>.create(file: label ,number_of_input: number_of_input, number_of_hidden: number_of_hidden, number_of_outputs: number_of_outputs, learning_rate: learning_rate, initFunction: valueInitFunction)
    }
    
    static func new<T: Numeric>(label: String = #file, number_of_input: Int, number_of_hidden: Int, number_of_outputs: Int, learning_rate: T? = nil, valueInitFunction: (() -> (T))? = nil) -> Brain<T> {
        
        let randomLength = 8
        return Brain<T>.create(file: String.randomString(length: randomLength) ,number_of_input: number_of_input, number_of_hidden: number_of_hidden, number_of_outputs: number_of_outputs, learning_rate: learning_rate, initFunction: valueInitFunction)
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
    
    func start(inputs: [[T]], targets: [[T]], iterations: Int? = nil, numberOfTraningsForIteration: Int? = nil, file: String = #file, line: Int = #line, function: String = #function, ativtionMethod: ActivationMethod = .sigmoid, valueInitFunction: (() -> (T))? = nil, traindIndex: (([T], Int) -> ())? = nil, progressUpdate: ((_ iteration: Int) -> ())? = nil, completed: (() -> ())? = nil) {
        
        stopRun = false
        stopStatic = false
        
        setTraindIndex(traindIndex: traindIndex)
        set_ativtion_method(ativtionMethod)
        set_learning_iterations(iterations: iterations ?? self.iterations)
        set_learning_number_tranings_for_iteration(number: numberOfTraningsForIteration ?? self.randomCaycles)
        
        brainObj?(self)
        
        for i in 0..<self.iterations {
            guard !stopRun && !stopStatic else { return }
            var j = 0
            while j < randomCaycles {
                guard !stopRun && !stopStatic else { return }
                let index = Int.random(in: 0..<inputs.count)
                train(inputs: inputs[index], targets: targets[index] ,activeFunction: activeFunction, deActiveFunction: deActiveFunction)
                j += 1
                traindIndex?(targets[index], index)
            }
            
            progressUpdate?(i)
        }
        
        completed?()
    }
    
    private var traindIndex: (([T], Int) -> ())?
    
    static func start(inputs: [[T]], targets: [[T]], iterations: Int? = nil, numberOfTraningsForIteration: Int? = nil, file: String = #file, line: Int = #line, function: String = #function, ativtionMethod: ActivationMethod = .sigmoid, learning_rate: T? = nil, valueInitFunction: (() -> (T))? = nil, brainObj: @escaping (Brain<T>) -> (), traindIndex: (([T], Int) -> ())? = nil, progressUpdate: ((_ iteration: Int) -> ())? = nil, completed: (() -> ())? = nil) {
        let number_of_hidden = inputs[0].count
        let brain = Brain<T>.create(file: file, number_of_input: inputs[0].count, number_of_hidden: number_of_hidden, number_of_outputs: targets[0].count, learning_rate: learning_rate ?? Brain<T>.learningRate(), initFunction: {
            return valueInitFunction != nil ? valueInitFunction!() : Brain<T>.random()
        })
        
        brain.brainObj = brainObj
        
        brain.start(inputs: inputs, targets: targets, iterations: iterations, numberOfTraningsForIteration: numberOfTraningsForIteration, ativtionMethod: ativtionMethod, valueInitFunction: valueInitFunction, traindIndex: traindIndex, progressUpdate: progressUpdate, completed: completed)
    }
    
    func setTraindIndex(traindIndex: (([T], Int) -> ())?, complete: (() -> ())? = nil) {
        self.traindIndex = traindIndex
        complete?()
    }
    
    func set_learning_iterations(iterations: Int, complete: (() -> ())? = nil) {
        self.iterations = iterations
        complete?()
    }
    
    func set_learning_number_tranings_for_iteration(number: Int, complete: (() -> ())? = nil) {
        self.randomCaycles = number
        complete?()
    }
    
    func set_learning_rate(learning_rate: T, complete: (() -> ())? = nil) {
        self.learning_rate = learning_rate
        complete?()
    }
    
    func set_ativtion_method(_ activationMethod: ActivationMethod, complete: (() -> ())? = nil) {
        self.activeFunction = activationMethod.getActivtionMethod()
        self.deActiveFunction = activationMethod.getDeActivtionMethod()
        complete?()
    }
    
    func printDescription(inputs:[[T]], targets: [[T]], title: String, fullDesc: Bool = false) {
        
        var strings = [String]()
        
        var count: CGFloat = 0
        
        for i in 0..<targets.count {
            let predict = predict(inputs: inputs[i])
            let max = predict.max { a, b in
                return Brain<T>.compere(a: a,b: b)
            }
            let correct = Brain<T>.eqal(a: targets[i][predict.firstIndex(of: max!)!])
            if correct {
                count += 1
            }
            let s = "Input: \(fullDesc ? "\(inputs[i])" : "No Desc"), Prediction: \(predict), Real Answer: \(targets[i]), Correct: \(correct)"
            strings.append(s)
        }
        
        let correctPrecent = (100 * count) / CGFloat(targets.count)
        
        let stringClac = "\nCorrect In Precent: \(correctPrecent)%"
        
        strings.append(stringClac)
        
        var max = 0
        
        for s in strings {
            if max < s.count {
                max = s.count
            }
        }
        
        max = min(max, 86)
        
        let s = String(repeating: "=", count:(max / 2) - (title.count / 2) + 8)
        print("\(s)\(title)\(s)")
        for i in 0..<strings.count {
            print("        \(strings[i])")
        }
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
    
    func getLabel() -> String {
        return label
    }
    
    @discardableResult static private func loadGeneration(key: String) -> Brain<T>? {
        if let data = readLocalJSONFile(forName: "ML+\(key)") {
            guard let ml = parse(jsonData: data) else {
                return nil
            }
            
            if singalSem == nil {
                singalSem =  DispatchSemaphore(value: 1)
            }
            
            if singalSem == nil {
                sem = DispatchSemaphore(value: 1)
            }
            
            let method: ActivationMethod = .sigmoid
            ml.set_ativtion_method(method)
            
            return ml
        }
        
        return nil
    }
    
    @discardableResult func save(name: String = "ML") -> Bool {
        sem?.wait()
        let success = saveGeneration(key: name)
        
        defer {
            sem?.signal()
        }
        
        return success
    }
    
    @discardableResult func load(name: String = "ML") -> Brain<T>? {
        return Brain<T>.load(name: name)
    }
    
    @discardableResult static func load(name: String = "ML") -> Brain<T>? {
        
        sem?.wait()
        defer {
            singalSem?.signal()
            sem?.signal()
        }
        
        guard let brain = loadGeneration(key: name) else { return nil }
        
        singalSem?.wait()
        
        Brain<T>.addInstances(key: brain.label, value: brain)
        
        return brain
    }
    
    private static func compere(a: T, b: T) -> Bool {
        switch T.self {
        case is CGFloat.Type:
            return  Brain<CGFloat>.compere(a: a as! CGFloat, b: b as! CGFloat)
        case is Double.Type:
            return Brain<Double>.compere(a: a as! Double, b: b as! Double)
        case is Float.Type:
            return Brain<Float>.compere(a: a as! Float, b: b as! Float)
        case is Float16.Type:
            return Brain<Float16>.compere(a: a as! Float16, b: b as! Float16)
        default:
            fatalError("Unsupported Type")
        }
    }
    
    private static func eqal(a: T, b: T? = nil) -> Bool {
        switch T.self {
        case is CGFloat.Type:
            return Brain<CGFloat>.eqal(a: a as! CGFloat, b: (b as? CGFloat) ?? 1)
        case is Double.Type:
            return Brain<Double>.eqal(a: a as! Double, b: (b as? Double) ?? 1)
        case is Float.Type:
            return Brain<Float>.eqal(a: a as! Float, b: (b as? Float) ?? 1)
        case is Float16.Type:
            return Brain<Float16>.eqal(a: a as! Float16, b: (b as? Float16) ?? 1)
        default:
            fatalError("Unsupported Type")
        }
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
    
    private static func compereSelf(a: T, b: T) -> T {
        return a - b
    }
    
    private static func compere(a: T, b: T) -> Bool {
        return a < b
    }
    
    private static func eqal(a: T, b: T) -> Bool {
        return a == b
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
    
    private static func compereSelf(a: T, b: T) -> T {
        return a - b
    }
    
    private static func compere(a: T, b: T) -> Bool {
        return a < b
    }
    
    private static func eqal(a: T, b: T) -> Bool {
        return a == b
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
    
    private static func compereSelf(a: T, b: T) -> T {
        return a - b
    }
    
    private static func compere(a: T, b: T) -> Bool {
        return a < b
    }
    
    private static func eqal(a: T, b: T) -> Bool {
        return a == b
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
    
    private static func compereSelf(a: T, b: T) -> T {
        return a - b
    }
    
    private static func compere(a: T, b: T) -> Bool {
        return a < b
    }
    
    private static func eqal(a: T, b: T) -> Bool {
        return a == b
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

extension String {
    
    static func randomString(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyz'ABCDEFGHIJKLMNOPQRSTUVWXYZ;.,?:@#$%^&*()_+=-±!0123456789\n"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        //        var repeatFlag = true
        //        while repeatFlag {
        let max = {
            return length > 4 ? length : 4
        }()
        
        let count = Int.random(in: 4...max)
        
        for _ in 0..<count {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
            
            
        }
        
        return randomString
    }
}

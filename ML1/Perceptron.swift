//
//  Perceptron.swift
//  ML1
//
//  Created by ברק בן חור on 08/07/2021.
//

import Foundation
import UIKit

class Perceptron {
    private var weights: [Double]!
    private var lerningRate: Double!
    
    init(lerningRate: Double, numOfweights: Int) {
        self.weights = [Double]()
        
        self.lerningRate = lerningRate
        
        for _ in 0...numOfweights {
            self.weights.append(Double.random(in: -1...1))
        }
    }
    
    func train(inputs: [Double], desierd: Int) {
        let guess = feedForword(inputs: inputs)
        
        let error = desierd - guess
        
        for i in 0..<weights.count {
            weights[i] += lerningRate * Double(error) * inputs[i]
        }
    }
    
    func feedForword(inputs: [Double]) -> Int {
        var sum = 0.0
        
        for i in 0..<weights.count {
            sum += inputs[i] * weights[i]
        }
        
        return activate(sum: sum)
    }
    
    private func activate(sum: Double) -> Int {
        if sum > 0 { return 1 }
        else { return -1 }
    }
    
    func getWeights() -> [Double] {
        return weights
    }
}

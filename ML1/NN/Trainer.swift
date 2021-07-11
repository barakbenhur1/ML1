//
//  Trainer.swift
//  ML1
//
//  Created by ברק בן חור on 08/07/2021.
//

import UIKit

class Trainer {
    
    var inputs: [Double]!
    var answer: Int!

    init(point: NPoint, answer: Int) {
        self.inputs = point.dimArr.map { $0 }
        self.inputs?.append(1)
        self.answer = answer
    }
}

public class NPoint {
    var dimArr: [Double]!
    var dim: Int!

    init(values: [Double]) {
        self.dim = values.count
        self.dimArr = values.map { $0 }
    }
}

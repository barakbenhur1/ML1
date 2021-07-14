//
//  Matrix.swift
//  ML1
//
//  Created by ברק בן חור on 09/07/2021.
//

import UIKit

public class Matrix<T: Numeric & Codable>: Codable {
    private var rawValues: [[T]]!
    private var mcols: Int! // Number Of Vectors / Arrays
    private var mrows: Int! // Length Of Vector / Array
    
    enum CodingKeys: String, CodingKey {
        case rows, cols, rawValues, valueInitFunction
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mrows = try container.decode(Int.self, forKey: .rows)
        mcols = try container.decode(Int.self, forKey: .cols)
        rawValues = try container.decode([[T]].self, forKey: .rawValues)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mrows, forKey: .rows)
        try container.encode(mcols, forKey: .cols)
        try container.encode(rawValues, forKey: .rawValues)
    }

    var rows: Int {
        get {
            return mrows
        }
    }
    
    var cols: Int {
        get {
            return mcols
        }
    }
    
    var values: [T] {
        get {
            var arr = [T]()
            rawValues.forEach { row in
                arr.append(contentsOf: row)
            }
            return arr
        }
    }
    
    private lazy var description = {
        return String(UInt(bitPattern: ObjectIdentifier(self)))
    }()
    
    public func hash(into hasher: inout Hasher) {
        self.hash(into: &hasher)
        "\(self)".hash(into: &hasher)
    }
    
    private var valueInitFunction: (() -> (T))!
    
    init(rows: Int, cols: Int, valueInitFunction: @escaping (() -> (T)) = { return .zero } ) {
        self.mrows = rows
        self.mcols = cols
        self.valueInitFunction = valueInitFunction
        self.rawValues = [[T]]()
        
        self.initRawData()
    }
    
    init(other: Matrix) {
        self.mrows = other.mrows
        self.mcols = other.mcols
        self.rawValues = [[T]](other.rawValues)
    }
    
    func chanceSize(newRows: Int, newCols: Int, valueInitFunction: @escaping (() -> (T)) = { return .zero }) {
       
        self.valueInitFunction = valueInitFunction
       
        if newRows == mrows && newCols == mcols { return }
       
        var newMat = [[T]]()
        
        for i in 0..<newRows {
            var arr = [T]()
            for j in 0..<newCols {
                arr.append(i < mrows && j < mcols ? rawValues[i][j] : valueInitFunction())
            }
            newMat.append(arr)
        }
        
        mrows = newRows
        mcols = newCols
        rawValues = newMat
    }
    
    func initRawData() {
        for i in 0..<rows {
            rawValues.append([])
            for _ in 0..<cols {
                rawValues[i].append((valueInitFunction != nil ? valueInitFunction!() : .zero))
            }
        }
    }
    
    static func fromMatrixArray(other: [[T]]) -> Matrix<T> {
        guard other.count > 0 else { fatalError("Matrix Must Have At Laest 1 Row") }
        let m = Matrix<T>(rows: other[0].count, cols: other.count)
        
        for i in 0..<other.count {
            for j in 0..<other[i].count {
                m.rawValues[j][i] = other[i][j]
            }
        }
        
        return m
    }
    
    private static func mainLoop(rows: Int, cols: Int, calcFunc: (_ i: Int, _ j: Int, _ result: Matrix) throws -> ()) throws -> Matrix {
        let result: Matrix = Matrix(rows: rows, cols: cols)
        for i in 0..<result.rows {
            for j in 0..<result.cols {
                do {
                    try calcFunc(i, j, result)
                }
                catch { throw error }
            }
        }
        
        return result
    }
    
    @discardableResult func add(n: T) -> Matrix {
        let matrix = try! Matrix.mainLoop(rows: mrows, cols: mcols) { i, j, matrix in matrix[i][j] = self[i][j] + n }
        rawValues = matrix.rawValues
        mcols = matrix.mcols
        mrows = matrix.mrows
        return self
    }
    
    @discardableResult func add(other: Matrix) -> Matrix {
        guard mrows == other.mrows && mcols == other.mcols else { fatalError(MatrixError.wrongDimensionForInterative(rows: [mrows, other.mrows], cols: [mcols, other.mcols]).localizedDescription) }
        let matrix = try! Matrix.mainLoop(rows: mrows, cols: mcols) { i, j, matrix in matrix[i][j] = self[i][j] + other[i][j] }
        rawValues = matrix.rawValues
        mcols = matrix.mcols
        mrows = matrix.mrows
        return self
    }
    
    @discardableResult func multiply(n: T) -> Matrix {
        let matrix = try! Matrix.mainLoop(rows: mrows, cols: mcols) { i, j, matrix in matrix[i][j] = self[i][j] * n }
        rawValues = matrix.rawValues
        mcols = matrix.mcols
        mrows = matrix.mrows
        return self
    }
    
    @discardableResult func multiplyByCell(other: Matrix) -> Matrix {
        guard mrows == other.mrows && mcols == other.mcols else { fatalError(MatrixError.wrongDimensionForInterative(rows: [mrows, other.mrows], cols: [mcols, other.mcols]).localizedDescription) }
        let matrix = try!  Matrix.mainLoop(rows: mrows, cols: mcols) { i, j, matrix in matrix[i][j] = self[i][j] * other[i][j] }
        rawValues = matrix.rawValues
        mcols = matrix.mcols
        mrows = matrix.mrows
        return self
    }
    
    @discardableResult func transpose() -> Matrix {
        let matrix: Matrix = try! Matrix.transpose(m: self)
        rawValues = matrix.rawValues
        mcols = matrix.mcols
        mrows = matrix.mrows
        return self
    }
    
    static func transpose(m: Matrix<T>) throws -> Matrix<T> {
        do {
            return try Matrix.mainLoop(rows: m.mcols, cols: m.mrows) { i, j, matrix in matrix[i][j] = m[j][i] }
        }
        catch { throw error }
    }
    
    @discardableResult func map(function: (T) -> (T)) -> Matrix {
        let matrix = try! Matrix.map(m: self, function: function)
        rawValues = matrix.rawValues
        mcols = matrix.mcols
        mrows = matrix.mrows
        return self
    }
    
    static func map(m: Matrix<T>, function: (T) -> (T)) throws -> Matrix<T> {
        do {
            return try Matrix.mainLoop(rows: m.mrows, cols: m.mcols) { i, j, results in results[i][j] = function(m[i][j]) }
        }
        catch { throw error }
    }
    
    static func subtract(m1: Matrix<T>, m2: Matrix<T>) throws -> Matrix<T> {
        guard m1.mrows == m2.mrows && m1.mcols == m2.mcols else { fatalError(MatrixError.wrongDimensionForInterative(rows: [m1.mrows, m2.mrows], cols: [m1.mcols, m2.mcols]).localizedDescription) }
        do { return try mainLoop(rows: m1.mrows, cols: m1.mcols) { i, j, matrix in matrix[i][j] = m1[i][j] - m2[i][j] } }
        catch { throw error }
    }
    
    @discardableResult func multiply(other: Matrix) -> Matrix {
        guard mcols == other.mrows else { fatalError(MatrixError.wrongDimensionForMultiply(rows: mcols, cols: other.mrows).localizedDescription) }
        do {
            let matrix = try Matrix.multiply(m1: self, m2: other)
            rawValues = matrix.rawValues
            mcols = matrix.mcols
            mrows = matrix.mrows
            return self
        }
        catch { fatalError(error.localizedDescription) }
    }
    
    static func multiply(m1: Matrix, m2: Matrix) throws -> Matrix {
        guard m1.mcols == m2.mrows else { throw MatrixError.wrongDimensionForMultiply(rows: m2.mrows, cols: m1.mcols) }
        do { return try mainLoop(rows: m1.mrows, cols: m2.cols) { i, j, matrix in matrix[i][j] = m1.sum(other: m2, i: i, j: j) } }
        catch { throw error }
    }
    
    private func sum(other: Matrix, i: Int, j: Int) -> T {
//        guard mcols == other.mrows else { throw MatrixError.wrongDimensionForMultiply(rows: other.mrows , cols: mcols) }
        var sum: T = .zero
        
        for k in 0..<mcols { sum += self[i][k] * other[k][j] }
        
        return sum
    }
}

extension Matrix {
    subscript(offset: Int) -> [T] {
        get { return rawValues[offset] }
        set { self.rawValues[offset] = newValue }
    }
}

fileprivate enum MatrixError: Error & LocalizedError {
    case wrongDimensionForMultiply(rows: Int, cols: Int)
    case wrongDimensionForInterative(rows: [Int], cols: [Int])
    
    public var errorDescription: String? {
        switch self {
        case .wrongDimensionForMultiply(let rows, let cols):
            return NSLocalizedString("Matrix Multiply:\nMatrix A Number Of Rows ( \(rows) ) Dos Not Equal Matrix B Number Of Colmns ( \(cols) )", comment: "Matrix Muliply")
        case .wrongDimensionForInterative(let rows, let cols):
            var error = "Matrix Iterative:\n"
            var isFirstIn = false
            if rows[0] != rows[1] {
                isFirstIn = true
                error += "Matrix A Number Of Rows ( \(rows[0]) ) Dos Not Equal Matrix B Number Of Rows ( \(rows[1]) )"
            }
            if cols[0] != cols[1] {
                let colsText = "Matrix A Number Of Colmns ( \(cols[0]) ) Dos Not Equal Matrix B Number Of Colmns ( \(cols[1]) )"
                error += !isFirstIn ? colsText :
                    " And \(colsText)"
            }
            return NSLocalizedString(error, comment: "Matrix Intarative Operation")
        }
    }
}


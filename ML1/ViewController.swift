//
//  ViewController.swift
//  ML1
//
//  Created by ברק בן חור on 08/07/2021.
//

import UIKit

class ViewController: UIViewController {
    
    var a: CGFloat!
    var b: CGFloat!
    
    var epsilon = 0.006
    
    func drawLine(imageView: UIImageView, from fromPoint: CGPoint, to toPoint: CGPoint, lineW: CGFloat ,alpha: CGFloat, color: UIColor) {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        
        imageView.image?.draw(in: view.bounds)
        
        let context = UIGraphicsGetCurrentContext()
        
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        
        context?.setLineCap(CGLineCap.round)
        context?.setLineWidth(lineW)
        context?.setStrokeColor(color.withAlphaComponent(alpha).cgColor)
        context?.setBlendMode(CGBlendMode.normal)
        context?.strokePath()
        
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        imageView.alpha = 1
        UIGraphicsEndImageContext()
        
        //        imageView.setNeedsDisplay()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imgv = UIImageView(frame: self.view.frame)
        
        //        DispatchQueue.main.async {
        
        self.view.addSubview(imgv)
        
        imgv.center = self.view.center
        
        imgv.backgroundColor = .systemGray3
        
        a = 2.8
        b = -6.4
        //        }
        
        let x1: CGFloat = 20
        let y1: CGFloat = CGFloat(lineAnswer(a: a, x: x1, b: b))
        
        let x2: CGFloat = view.frame.width
        let y2: CGFloat = CGFloat(lineAnswer(a: a, x: x2, b: b))
        
        drawLine(imageView: imgv, from: CGPoint(x: x1, y: y1), to: CGPoint(x: x2, y: y2), lineW: 8, alpha: 1, color: .black)
        
        var loop = 0
        
        let num: Int = 2000
        //        let end: CGFloat = 1
        
        let p = Perceptron(lerningRate: 0.1, numOfweights: 2)
        
        var train = true
        
        var t: [Trainer] = [Trainer]()
        
        DispatchQueue.init(label: "Train").async { [self] in
            while train {
                
                let sy = CGFloat((-p.getWeights()[2] - p.getWeights()[0] * Double(x1)) / p.getWeights()[1])
                let ey: CGFloat = CGFloat((-p.getWeights()[2] - p.getWeights()[0] * Double(x2)) / p.getWeights()[1])
                DispatchQueue.main.async {
                    drawLine(imageView: imgv, from: CGPoint(x: x1, y: sy), to: CGPoint(x: x2, y: ey), lineW: 0.6, alpha: 0.6, color: .systemGreen)
                }
                
                t = [Trainer]()
                var trainnig: Trainer!
                for _ in 0...num {
                    let x =  CGFloat.random(in: x1...x2)
                    let y =  CGFloat.random(in: min(y1, y2)...max(y1, y2))
                    let values = [Double(x), Double(y)]
                    let answer = Double(y) < lineAnswer(a: a, x: x, b: b)  ? -1 : 1
                    
                    trainnig = Trainer(point: NPoint(values: values), answer: answer)
                    
                    p.train(inputs: trainnig.inputs, desierd: trainnig.answer)
                    
                    t.append(trainnig)
                }
                
                var stop = true
                
                let percision: Double = 1000
                
                //                for i in 0..<t.count {
                let x = x1
                let answerY = lineAnswer(a: a, x: CGFloat(x), b: b)
                let guessY = (-p.getWeights()[2] - p.getWeights()[0] * Double(x)) / p.getWeights()[1]
                print("y = \(answerY)")
                print("y guess = \(guessY)")
                
                let xe = x2
                let answerYe = lineAnswer(a: a, x: CGFloat(xe), b: b)
                let guessYe = (-p.getWeights()[2] - p.getWeights()[0] * Double(xe)) / p.getWeights()[1]
                print("ye = \(answerYe)")
                print("ye guess = \(guessYe)")
                
                if abs((round(percision * answerY)/percision) - (round(percision * guessY)/percision)) >= epsilon && abs((round(percision * answerYe)/percision) - (round(percision * guessYe)/percision)) >= epsilon {
                    stop = false
                    //                        break
                }
                //                }
                
                train = !stop
                
                guard train else {
                    break
                }
                
                loop += 1
            }
            
            print("Finish...")
            
            for i in 0..<t.count {
                let x = t[i].inputs[0]
                print("y = \(lineAnswer(a: a, x: CGFloat(x), b: b))")
                print("y guess = \((-p.getWeights()[2] - p.getWeights()[0] * Double(x)) / p.getWeights()[1])")
                print("\n")
            }
            
            print("================Step \(loop)=========================")
            
            DispatchQueue.main.async {
                let sy = CGFloat((-p.getWeights()[2] - p.getWeights()[0] * Double(x1)) / p.getWeights()[1])
                let ey: CGFloat = CGFloat((-p.getWeights()[2] - p.getWeights()[0] * Double(x2)) / p.getWeights()[1])
                drawLine(imageView: imgv, from: CGPoint(x: x1, y: sy), to: CGPoint(x: x2, y: ey), lineW: 8, alpha: 0.4, color: .blue)
            }
        }
    }
    
    func line(a: CGFloat, x: CGFloat, b: CGFloat) -> Int {
        let formula = a * x + b
        return formula >= 0  ? 1 : -1
    }
    
    func lineAnswer(a: CGFloat, x: CGFloat, b: CGFloat) -> Double {
        let formula = a * x + b
        return Double(formula)
    }
}


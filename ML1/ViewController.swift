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
    
    let p = Perceptron(lerningRate: 0.1, numOfweights: 2)
    
    var epsilon = 0.1
    
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
    
    @objc private func getValue(text: String) {
        guard let n = NumberFormatter().number(from: text) else { return }
        print("F( \(text) ) = y: \(lineAnswer(a: a, x: CGFloat(truncating: n), b: b)), y guess: \(p.getY(for: CGFloat(truncating: n)) + Double(b))")
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let imgv = UIImageView(frame: self.view.frame)
        
        //        DispatchQueue.main.async {
        
        self.view.addSubview(imgv)
        
        imgv.center = self.view.center
        
        imgv.backgroundColor = .systemGray3
        
        let textView = UITextField(frame: CGRect(origin: CGPoint(x: view.frame.width - 220, y: 60), size: CGSize(width: 200, height: 40)))
        
        view.addSubview(textView)
        
        textView.backgroundColor = .lightGray
        
        textView.placeholder = "Guess Y"
        
        textView.delegate = self
        
        a = 4.9
        b = -5.12
        //        }
        
        let x1: CGFloat = 20
        let y1: CGFloat = CGFloat(lineAnswer(a: a, x: x1, b: b))
        
        let x2: CGFloat = view.frame.width
        let y2: CGFloat = CGFloat(lineAnswer(a: a, x: x2, b: b))
        
        drawLine(imageView: imgv, from: CGPoint(x: x1, y: y1), to: CGPoint(x: x2, y: y2), lineW: 8, alpha: 1, color: .black)
        
        var loop = 0
        
        let num: Int = 4000
        //        let end: CGFloat = 1
        
        var train = true
        
        var t: [Trainer] = [Trainer]()
        
        DispatchQueue.init(label: "Train").async { [self] in
            while train {
                
                let sy = CGFloat(p.getY(for: x1)) + b
                let ey = CGFloat(p.getY(for: x2)) + b
                DispatchQueue.main.async {
                    drawLine(imageView: imgv, from: CGPoint(x: x1, y: sy), to: CGPoint(x: x2, y: ey), lineW: 0.6, alpha: 0.4, color: UIColor(red: 30, green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1))
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
                
//                let percision: Double = 1
                
                //                for i in 0..<t.count {
                let answerY = lineAnswer(a: a, x: CGFloat(x1), b: b)
                let guessY = p.getY(for: x1) + Double(b)
                print("y = \(answerY)")
                print("y guess = \(guessY)")
                
                let answerYe = lineAnswer(a: a, x: CGFloat(x2), b: b)
                let guessYe = p.getY(for: x2) + Double(b)
                print("ye = \(answerYe)")
                print("ye guess = \(guessYe)")
                
                if abs(((answerY)) - ((guessY))) > epsilon || abs(((answerYe)) - ((guessYe))) > epsilon {
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
                print("y guess = \(p.getY(for: CGFloat(x)) + Double(b))")
                print("\n")
            }
            
            print("================Step \(loop)=========================")
            
            DispatchQueue.main.async {
                let sy = CGFloat(p.getY(for: x1) + Double(b))
                let ey = CGFloat(p.getY(for: x2) + Double(b))
                drawLine(imageView: imgv, from: CGPoint(x: x1, y: sy), to: CGPoint(x: x2, y: ey), lineW: 8, alpha: 0.8, color: .blue)
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

extension ViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard string != "" else { return true }
        getValue(text: textField.text! + string)
        
        return true
    }
}


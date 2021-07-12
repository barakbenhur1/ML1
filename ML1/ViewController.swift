//
//  ViewController.swift
//  ML1
//
//  Created by ברק בן חור on 08/07/2021.
//

import UIKit

class ViewController: UIViewController {
    
    var startButton : UIButton!
    var saveButton: UIButton!
    var loadButton : UIButton!
    
    var a: CGFloat!
    var b: CGFloat!
    
    let p = Perceptron(lerningRate: 0.2, numOfweights: 2)
    
    let inputs: [[CGFloat]] = [[0, 0], [1, 0], [0, 1], [1, 1]]
    let targets: [[CGFloat]] = [[0], [1] ,[1], [0]]
    
    var brain: Brain<CGFloat>?
    
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
        
        startButton = UIButton(frame: CGRect(origin: CGPoint(x: view.center.x - 200, y: view.center.y - 320), size: CGSize(width: 400, height: 180)))
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(.gray, for: .disabled)
        startButton.setTitleColor(.black, for: .normal)
        startButton.backgroundColor = .green
        startButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        
        
        saveButton = UIButton(frame: CGRect(origin: CGPoint(x: view.center.x - 200, y: view.center.y - 120), size: CGSize(width: 400, height: 180)))
        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = .systemTeal
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        saveButton.setTitleColor(.gray, for: .disabled)
        saveButton.setTitleColor(.black, for: .normal)
        
        saveButton.isEnabled = false
        
        loadButton = UIButton(frame: CGRect(origin: CGPoint(x: view.center.x - 200, y: view.center.y + 80), size: CGSize(width: 400, height: 180)))
        loadButton.setTitle("Load", for: .normal)
        loadButton.setTitleColor(.gray, for: .disabled)
        loadButton.setTitleColor(.black, for: .normal)
        loadButton.backgroundColor = .systemOrange
        loadButton.addTarget(self, action: #selector(load), for: .touchUpInside)
        
        view.addSubview(startButton)
        view.addSubview(saveButton)
        view.addSubview(loadButton)
    }
    
    @objc func start() {
        brain?.stop()
        brain = Brain<CGFloat>.create(number_of_input: inputs[0].count, number_of_hidden: inputs[0].count, number_of_outputs: targets[0].count)
        ml(on: true)
        mlStart()
    }
    
    @objc func save() {
        ml(on: false)
        brain?.save(name: "b")
        ml(on: true)
    }
    
    @objc func load() {
        //        brain = nil
        ml(on: false)
        brain?.stop()
        brain = Brain<CGFloat>.load(name: "b")
        DispatchQueue(label: "work").async { [self] in
            mlStart()
        }
        ml(on: true)
    }
    
    func ml(on: Bool) {
        DispatchQueue.main.async {
            self.startButton.isEnabled = on
            self.saveButton.isEnabled = on
            self.loadButton.isEnabled = on
        }
    }
    
    func mlStart() {
        DispatchQueue(label: "work").async { [self] in
            brain?.start(inputs: inputs, targets: targets, iterations: 200, numberOfTraningsForIteration: 400,
                        progressUpdate:  { iteration in
                            let iter = " ( Iteration: \(iteration) ) "

                            brain?.printDescription(inputs: inputs, targets: targets, title: iter)
                            print()

                        }, completed: {
                            print()
                            print()
                            print("Done.................")
                            print()
                            let s = String(repeating: "=", count: "\(inputs[0]), \(brain!.predict(inputs: inputs[0])), \(targets[0])".count + 16)
                            brain?.printDescription(inputs: inputs, targets: targets, title: s)
                        })

//            var brain2: Brain<CGFloat>!
//            //
//            Brain<CGFloat>.start(inputs: inputs, targets: targets, iterations:  200, numberOfTraningsForIteration: 400) { brainObj in
//                brain = brainObj
//                DispatchQueue.main.async {
//                    self.saveButton.isEnabled = true
//                    self.loadButton.isEnabled = true
//                }
//            } progressUpdate: { iteration in
//
//                let iter = " ( Iteration: \(iteration) ) "
//
//                brain?.printDescription(inputs: inputs, targets: targets, title: iter)
//                print()
//
//            } completed: {
//                print()
//                print()
//                print("Done.................")
//                print()
//                let s = String(repeating: "=", count: "\(inputs[0]), \(brain!.predict(inputs: inputs[0])), \(targets[0])".count + 16)
//                brain?.printDescription(inputs: inputs, targets: targets, title: s)
//            }
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


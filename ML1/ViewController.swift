//
//  ViewController.swift
//  ML1
//
//  Created by ברק בן חור on 08/07/2021.
//

import UIKit

public struct PixelData {
    var a: UInt8
    var r: UInt8
    var g: UInt8
    var b: UInt8
}

class ViewController: UIViewController {
    
    var startButton : UIButton!
    var saveButton: UIButton!
    var loadButton : UIButton!
    
    var a: CGFloat!
    var b: CGFloat!
    
    var inputs: [[CGFloat]] = [[0, 0], [1, 0], [0, 1], [1, 1]]
    var targets: [[CGFloat]] = [[0], [1] ,[1], [0]]
    
    var inputsTest: [[CGFloat]] = [[0, 0], [1, 0], [0, 1], [1, 1]]
    var targetsTest: [[CGFloat]] = [[0], [1] ,[1], [0]]
    
    var label = #file
    
    var number_of_input = 0
    
    var number_of_hidden = 0
    
    var number_of_outputs = 0
    
    var numberOfTraningsForIteration = 0
    
    var iterations = 0
    
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
    }
    
    func getFile(forResource resource: String, withExtension fileExt: String?) -> [UInt8]? {
        // See if the file exists.
        guard let fileUrl: URL = Bundle.main.url(forResource: resource, withExtension: fileExt) else {
            return nil
        }

        do {
            // Get the raw data from the file.
            let rawData: Data = try Data(contentsOf: fileUrl)

            // Return the raw data as an array of bytes.
            return [UInt8](rawData)
        } catch {
            // Couldn't read the file.
            return nil
        }
    }
    
    func byteArrayToCGImage(raw: UnsafeMutablePointer<UInt8>, w: Int, h: Int) -> CGImage! {

        // 4 bytes(rgba channels) for each pixel
        let bytesPerPixel: Int = 4
        // (8 bits per each channel)
        let bitsPerComponent: Int = 8

        let bitsPerPixel = bytesPerPixel * bitsPerComponent;
        // channels in each row (width)
        let bytesPerRow: Int = w * bytesPerPixel;

        let cfData = CFDataCreate(nil, raw, w * h * bytesPerPixel)
        let cgDataProvider = CGDataProvider.init(data: cfData!)!

        let deviceColorSpace = CGColorSpaceCreateDeviceRGB()

        let image: CGImage! = CGImage.init(width: w,
                                           height: h,
                                           bitsPerComponent: bitsPerComponent,
                                           bitsPerPixel: bitsPerPixel,
                                           bytesPerRow: bytesPerRow,
                                           space: deviceColorSpace,
                                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                           provider: cgDataProvider,
                                           decode: nil,
                                           shouldInterpolate: true,
                                           intent: CGColorRenderingIntent.defaultIntent)
        
        
        
        return image;
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
        
        prepareData()
    }
    
    func prepareData() {
        
        /// 1  ================================================
        
        let catbyteArr = getFile(forResource: "cat", withExtension: "bin")
        
        let rainbowbyteArr = getFile(forResource: "cat", withExtension: "bin")
        
        let trainbyteArr = getFile(forResource: "cat", withExtension: "bin")
        
        /// 2 ================================================
        
        let dataArr = [catbyteArr, rainbowbyteArr, trainbyteArr]
        
        var traningObj = [[CGFloat]]()
        
        var targetTarningObj = [[CGFloat]]()
        
        var testingObj = [[CGFloat]]()
        
        var testingTarningObj = [[CGFloat]]()
        
        let total = 100
        
        /// 3 ================================================
        
        for i in 0..<3 {
            
            var targesArr = [CGFloat]([0, 0, 0])
            
            targesArr[i] = 1
            
            for n in 0..<total {
                
                let offset = n * 784
                
                let imageArr = [UInt8](dataArr[i]![offset..<offset+784]).map { (255 - $0) }
                
                let imageNormalArr: [CGFloat] = imageArr.map { CGFloat($0) / 255 }
                
                
                
                if CGFloat(n) < CGFloat(total) * 0.8 {
                    targetTarningObj.append(targesArr)
                    traningObj.append(imageNormalArr)
                }
                else {
                    testingTarningObj.append(targesArr)
                    testingObj.append(imageNormalArr)
                }
            }
        }
        
        
        /// 4  ================================================
        
        label = "ML1"
        
        inputs = traningObj
        
        targets = targetTarningObj
        
        number_of_input = inputs[0].count
        
        number_of_hidden = 200
        
        number_of_outputs = targets[0].count
        
        iterations = 20
        
        numberOfTraningsForIteration = inputs[0].count
        
        inputsTest = testingObj
        
        targetsTest = testingTarningObj
    }
    
    @objc func start() {
        brain?.stop()
        
        brain = Brain<CGFloat>.create(label: label ,number_of_input: number_of_input, number_of_hidden: number_of_hidden, number_of_outputs: number_of_outputs)
        
        print(true)
        
        ml(on: true)
        
        DispatchQueue(label: "work").async { [self] in
            mlStart()
        }
    }
    
    @objc func save() {
        ml(on: false)
        
        let success = brain?.save(name: label)
        
        print(success!)
        
        ml(on: true)
    }
    
    @objc func load() {
        ml(on: false)
        
        brain?.stop()
        
        DispatchQueue(label: "work").async { [self] in
            
            guard let brainObj = brain?.load(name: label) else {
                print(false)
                return
            }
            
            brain = brainObj
            print(true)
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
            
            brain?.start(inputs: inputs, targets: targets, iterations: iterations, numberOfTraningsForIteration: numberOfTraningsForIteration,
                         progressUpdate:  { iteration in
                            let iter = " ( Iteration: \(iteration) ) "
                            
                            brain?.printDescription(inputs: inputs, targets: targets, title: iter)
                            print()
                            
                         }, completed: {
                            print()
                            print()
                            let s = " .... Done .... "
                            brain?.printDescription(inputs: inputsTest, targets: targetsTest, title: s)
                            print(s)
                         })
        }
    }
}

extension UIImage {
    convenience init?(pixels: [PixelData], width: Int, height: Int) {
        guard width > 0 && height > 0, pixels.count == width * height else { return nil }
        var data = pixels
        guard let providerRef = CGDataProvider(data: Data(bytes: &data, count: data.count * MemoryLayout<PixelData>.size) as CFData)
            else { return nil }
        guard let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * MemoryLayout<PixelData>.size,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent)
        else { return nil }
        self.init(cgImage: cgim)
    }
}

extension CGFloat {
    func print() {
        switch self {
        case 0:
            Swift.print("Cat")
        case 1:
            Swift.print("Rainbow")
        case 2:
            Swift.print("Train")
        default:
            Swift.print("Dont Know")
        }
    }
}

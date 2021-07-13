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
    
    var queue: [() -> ()]!
    
    var timer: Timer!
    
    var dataArr: [Any]?
    
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
        
        let buttonH = 120
        let buttonW = 400
        
        startButton = UIButton(frame: CGRect(origin: CGPoint(x: view.center.x - 200, y: view.center.y - 280), size: CGSize(width: buttonW, height: buttonH)))
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(.gray, for: .disabled)
        startButton.setTitleColor(.black, for: .normal)
        startButton.backgroundColor = .green
        startButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        
        
        saveButton = UIButton(frame: CGRect(origin: CGPoint(x: view.center.x - 200, y: view.center.y - 80), size: CGSize(width: buttonW, height: buttonH)))
        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = .systemTeal
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        saveButton.setTitleColor(.gray, for: .disabled)
        saveButton.setTitleColor(.black, for: .normal)
        
        saveButton.isEnabled = false
        
        loadButton = UIButton(frame: CGRect(origin: CGPoint(x: view.center.x - 200, y: view.center.y + 120), size: CGSize(width: buttonW, height: buttonH)))
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
        
        let rainbowbyteArr = getFile(forResource: "rainbow", withExtension: "bin")
        
        let trainbyteArr = getFile(forResource: "train", withExtension: "bin")
        
        /// 2 ================================================
        
        dataArr = [catbyteArr!, rainbowbyteArr!, trainbyteArr!]
        
        var traningObj = [[CGFloat]]()
        
        var targetTarningObj = [[CGFloat]]()
        
        var testingObj = [[CGFloat]]()
        
        var testingTarningObj = [[CGFloat]]()
        
        /// 3 ================================================
        
        let imageSize: Int = 784
        
        let pixelNormal: UInt8 = 255
        
        let traningDataRatio: CGFloat = 0.8
        
        let initValue: CGFloat = 0
        
        let assingedValue: CGFloat = 1
        
        let start: Int = 0
        
        let total: Int = 400
        
        guard let dataArr = dataArr as? [[UInt8]] else { return }
        
        for i in start..<dataArr.count {
            
            var targesArr = [CGFloat](repeating: initValue, count: dataArr.count)
            
            targesArr[i] = assingedValue
            
            for n in start..<total {
                
                let offset = n * imageSize
                
                let imageArr = [UInt8](dataArr[i][offset..<offset+imageSize]).map { (pixelNormal - $0) }
                
                let imageNormalArr: [CGFloat] = imageArr.map { CGFloat($0) / CGFloat(pixelNormal) }
                
                if CGFloat(n) < CGFloat(total) * traningDataRatio {
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
        
        let indexForLength = 0
        
        label = "ML1"
        
        inputs = traningObj
        
        targets = targetTarningObj
        
        number_of_input = inputs[indexForLength].count
        
        number_of_hidden = 64
        
        number_of_outputs = targets[indexForLength].count
        
        iterations = 20
        
        numberOfTraningsForIteration = inputs[indexForLength].count
        
        inputsTest = testingObj
        
        targetsTest = testingTarningObj
    }
    
    var updateImage: ((_ label: Int, _ index: Int) -> ())!
    
    var ui = false
    
    func uiFunc() {
        
        guard !ui else { return }
        
        ui = true
        
        let title = UILabel(frame: CGRect(origin: CGPoint(x: view.center.x - 200, y: 34), size: CGSize(width: 400, height: 50)))
        title.numberOfLines = 0
        title.textAlignment = .center
        title.font = UIFont(name: "TimesNewRomanPSMT", size: 22)
        
        let imageWrraperView = UIView(frame: CGRect(origin: CGPoint(x: view.center.x - 200, y: 84), size: CGSize(width: 400, height: 400)))
        
        imageWrraperView.layer.cornerRadius = 10
        imageWrraperView.layer.borderWidth = 0.8
        imageWrraperView.layer.borderColor = UIColor.black.cgColor
        
        let imageView = UIImageView(frame: imageWrraperView.bounds)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        
        imageWrraperView.addSubview(imageView)
    
        
        startButton.alpha = 0.5
        saveButton.alpha = 0.5
        loadButton.alpha = 0.5
        
        UIView.animate(withDuration: 0.4) { [self] in
            startButton.frame = CGRect(origin: CGPoint(x: saveButton.frame.origin.x, y: view.center.y + 35), size: saveButton.frame.size)
            saveButton.frame = CGRect(origin: CGPoint(x: saveButton.frame.origin.x, y: view.center.y + 157), size: saveButton.frame.size)
            loadButton.frame = CGRect(origin: CGPoint(x: loadButton.frame.origin.x, y: view.center.y + 280), size: loadButton.frame.size)
            
            startButton.alpha = 1
            saveButton.alpha = 1
            loadButton.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.view.addSubview(title)
            self.view.addSubview(imageWrraperView)
        }
        
        var start = true
        
        updateImage = { [self] label, index in
            DispatchQueue.main.async {
                
                let nextImage = {
                    imageView.alpha = 0.2
                    imageView.transform = .init(scaleX: 0.01, y: 0.001)
                    UIView.animate(withDuration: 0.3) {
                        var arr = inputs[index].map { UInt8($0 * 255) }
                        let image = byteArrayToCGImage(raw: &arr, w: 28, h: 28)
                        let predict = brain?.predict(inputs: inputs[index])
                        let max = predict!.max()
                        let mlIndex = predict?.firstIndex(of: max!)
                        title.text = "Image Is: " + label.stringValue() + "\n" + "NN Predict: \(mlIndex!.stringValue())"
                        imageView.image = UIImage(cgImage: image!)
                        imageView.alpha = 1
                        imageView.transform = .identity
                    }
                }
                
                if start {
                    start = false
                    nextImage()
                }
                else {
                    queue.append {
                        nextImage()
                    }
                }
            }
        }
    }
    
    @objc func start() {
        
        DispatchQueue.main.async {
            self.startButton.isUserInteractionEnabled = false
            self.startButton.setTitleColor(.gray, for: .normal)
        }
        
        brain?.stop()
        
        queue = [() -> ()]()
    
        uiFunc()
        
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
        
        queue = [() -> ()]()
        
        DispatchQueue(label: "work").async { [self] in
            
            guard let brainObj = Brain<CGFloat>.load(name: label) else {
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
        
        timerControl(on: on)
    }
    
    func timerControl(on: Bool) {
        if on {
            timer = Timer(timeInterval: 2.4, repeats: true) { [self] timer in
                guard queue.count > 0 else { return }
                queue.remove(at: 0)()
            }
            RunLoop.current.add(timer, forMode: .common)
        }
        else {
            if timer != nil {
                timer.invalidate()
                timer = nil
            }
            
            if queue != nil && queue.count > 0 {
                self.queue.popLast()!()
                self.queue = [() -> ()]()
            }
        }
    }
    
    func mlStart() {
        
        DispatchQueue(label: "work").async { [self] in
            
            brain?.start(inputs: inputs, targets: targets, iterations: iterations, numberOfTraningsForIteration: numberOfTraningsForIteration,
                         traindIndex: { target, index in
                            updateImage(target.firstIndex(where: { num in
                                return num == 1
                            })!, index)
                         },
                         progressUpdate:  { iteration in
                            let iter = " ( Iteration: \(iteration) ) "
                            
                            brain?.printDescription(inputs: inputs, targets: targets, title: iter)
                            print()
                            
                         }, completed: {
                            print()
                            print()
                            let s = " .... Done .... "
                            brain?.printDescription(inputs: inputsTest, targets: targetsTest, title: s)
                            
                            if timer != nil {
                                timer.invalidate()
                                timer = nil
                            }
                            
                            if queue != nil && queue.count > 0 {
                                self.queue.popLast()!()
                                self.queue = [() -> ()]()
                            }
                            
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

extension Int {
    func stringValue() -> String {
        switch self {
        case 0:
            return "Cat"
        case 1:
            return "Rainbow"
            case 2:
                return "Train"
        default:
            return "Dont Know"
        }
    }
}

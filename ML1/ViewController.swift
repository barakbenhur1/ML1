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
    
    var titleLabel : UILabel!
    var sperLabel : UILabel!
    var startButton : UIButton!
    var saveButton: UIButton!
    var loadButton : UIButton!
    
    var a: CGFloat!
    var b: CGFloat!
    
    var inputs: [[CGFloat]] = [[0, 0], [1, 0], [0, 1], [1, 1]]
    var targets: [[CGFloat]] = [[0], [1] ,[1], [0]]
    
    var inputsTest: [[CGFloat]] = [[0, 0], [1, 0], [0, 1], [1, 1]]
    var targetsTest: [[CGFloat]] = [[0], [1] ,[1], [0]]
    
    var categorys: [String] = [String]()
    
    var label = #file
    
    var number_of_input = 0
    
    var number_of_hidden = 0
    
    var number_of_outputs = 0
    
    var numberOfTraningsForIteration = 0
    
    var iterations = 0
    
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
        let bytesPerPixel: Int = 1
        // (8 bits per each channel)
        let bitsPerComponent: Int = 8
        
        let bitsPerPixel = bytesPerPixel * bitsPerComponent;
        // channels in each row (width)
        let bytesPerRow: Int = w * bytesPerPixel;
        
        let cfData = CFDataCreate(nil, raw, w * h * bytesPerPixel)
        let cgDataProvider = CGDataProvider.init(data: cfData!)!
        
        let deviceColorSpace = CGColorSpaceCreateDeviceGray()
        
        let image: CGImage! = CGImage.init(width: w,
                                           height: h,
                                           bitsPerComponent: bitsPerComponent,
                                           bitsPerPixel: bitsPerPixel,
                                           bytesPerRow: bytesPerRow,
                                           space: deviceColorSpace,
                                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                                           provider: cgDataProvider,
                                           decode: nil,
                                           shouldInterpolate: true,
                                           intent: CGColorRenderingIntent.defaultIntent)
        
        
        
        return image;
    }
    
    func parseCSV (contentsOfURL: NSURL, encoding: String.Encoding, error: NSErrorPointer) -> (values: [[UInt8]], tag: String)? {
        // Load the CSV file and parse it
        let delimiter = ","
        var stations:[[UInt8]]?
        
        if let data = NSData(contentsOf: contentsOfURL as URL) {
            if let content = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
                //existing code
                stations = [[UInt8]]()
                var lines:[String] = (content.components(separatedBy: NSCharacterSet.newlines)) as [String]
                
                lines.remove(at: 0)
                
                for line in lines {
                    var values:[String] = []
                    if line != "" {
                        // For a line with double quotes
                        // we use NSScanner to perform the parsing
                        if line.range(of: "\"") != nil {
                            var textToScan:String = line
                            var value:NSString?
                            var textScanner:Scanner = Scanner(string: textToScan)
                            while textScanner.string != "" {
                                
                                if (textScanner.string as NSString).substring(to: 1) == "\"" {
                                    textScanner.scanLocation += 1
                                    textScanner.scanUpTo("\"", into: &value)
                                    textScanner.scanLocation += 1
                                } else {
                                    textScanner.scanUpTo(delimiter, into: &value)
                                }
                                
                                // Store the value into the values array
                                values.append(value! as String)
                                
                                // Retrieve the unscanned remainder of the string
                                if textScanner.scanLocation < textScanner.string.count {
                                    textToScan = (textScanner.string as NSString).substring(from: textScanner.scanLocation + 1)
                                } else {
                                    textToScan = ""
                                }
                                textScanner = Scanner(string: textToScan)
                            }
                            
                            // For a line without double quotes, we can simply separate the string
                            // by using the delimiter (e.g. comma)
                        } else  {
                            values = line.components(separatedBy: delimiter)
                        }
                        
                        //                        for value in values {
                        // Put the values into the tuple and add it to the items array
                        for _ in 0..<12 {
                            values.remove(at: 0)
                        }
                        stations?.append(values.map{ UInt8($0)! })
                        //                        }
                    }
                }
            }
        }
        
        return (stations!, contentsOfURL.absoluteURL!.lastPathComponent.replacingOccurrences(of: ".csv", with: ""))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let buttonH = 120
        let buttonW = 396
        
        
        titleLabel = UILabel(frame: CGRect(origin: CGPoint(x: view.center.x - 200, y: 80), size: CGSize(width: buttonW, height: buttonH)))
        sperLabel = UILabel(frame: CGRect(origin: CGPoint(x: view.center.x - 200, y: 88), size: CGSize(width: buttonW, height: buttonH)))
        
        titleLabel.text = "Neural Network Training"
        titleLabel.font = UIFont(descriptor: titleLabel.font.fontDescriptor, size: 24)
        sperLabel.text = String(repeating: "_", count: titleLabel.text!.count + 8)
        titleLabel.textAlignment = .center
        sperLabel.textAlignment = .center
        
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
        
        view.addSubview(titleLabel)
        view.addSubview(sperLabel)
        
        prepareData { [self] in
            DispatchQueue.main.sync {
                view.addSubview(startButton)
                view.addSubview(saveButton)
                view.addSubview(loadButton)
            }
        }
    }
    
    func prepareData(complete: @escaping () -> () = {}) {
        
        /// 1  ================================================
        
        dataArr = [[[UInt8]]]()
        categorys = [String]()
        
        let csvs = [
            "/Users/barak ben hur/Desktop/Projects/Data/fonts/CENTAUR.csv",
            "/Users/barak ben hur/Desktop/Projects/Data/fonts/COMIC.csv",
            "/Users/barak ben hur/Desktop/Projects/Data/fonts/PRISTINA.csv",
            "/Users/barak ben hur/Desktop/Projects/Data/fonts/CHILLER.csv",
            "/Users/barak ben hur/Desktop/Projects/Data/fonts/BAITI.csv",
            "/Users/barak ben hur/Desktop/Projects/Data/fonts/VIVALDI.csv",
            "/Users/barak ben hur/Desktop/Projects/Data/fonts/TREBUCHET.csv",
            "/Users/barak ben hur/Desktop/Projects/Data/fonts/GUNPLAY.csv"
        ]
        
        
        /// 2  ================================================
        
        let loadingLabel = UILabel(frame: CGRect(origin: CGPoint(x: view.center.x - 120, y: view.center.y - 100), size: CGSize(width: 300, height: 100)))
        loadingLabel.font = .systemFont(ofSize: 40)
        
        view.addSubview(loadingLabel)
        
        let colors: [UIColor] = [.systemIndigo, .magenta, .systemPink, .systemOrange, .systemYellow, .systemPurple, .systemBlue, .systemGreen, .brown, .black, .systemGray]
        var index = 0
        
        let loading = Timer(timeInterval: 0.2, repeats: true) { _ in
            let text = "Loading Data"
            let attr = NSMutableAttributedString(string: text)
            var space = 0
            for i in 0..<text.count {
                if (text as NSString).substring(with: NSRange(location: i, length: 1)) ==  " " {
                    space += 1
                }
                if (text as NSString).substring(with: NSRange(location: i, length: 1)) !=  " " {
                    attr.addAttributes([.foregroundColor : colors[(colors.count - (i - space - index)) % (colors.count)]], range: NSRange(location: i, length: 1))
                }
            }
            
            loadingLabel.attributedText = attr
            
            index += 1
        }
        
        loading.fire()
        
        RunLoop.main.add(loading, forMode: .common)
        
        var min = Int.max
        
        DispatchQueue(label: "CSV").async { [self] in
            for csv in csvs {
                guard let tupleCsv = parseCSV(contentsOfURL: NSURL(fileURLWithPath: csv), encoding: .utf8, error: nil) else { continue }
                dataArr?.append(tupleCsv.values)
                categorys.append(tupleCsv.tag)
                
                if tupleCsv.values.count < min {
                    min = tupleCsv.values.count
                }
            }

            var traningObj = [[CGFloat]]()

            var targetTarningObj = [[CGFloat]]()

            var testingObj = [[CGFloat]]()

            var testingTarningObj = [[CGFloat]]()

            /// 3 ================================================

            let pixelNormal: UInt8 = 255

            let traningDataRatio: CGFloat = 0.8

            let initValue: CGFloat = 0

            let assingedValue: CGFloat = 1

            let start: Int = 0

            let total: Int = min

            guard let dataArr = dataArr as? [[[UInt8]]] else { return }

            for i in start..<dataArr.count {

                var targesArr = [CGFloat](repeating: initValue, count: dataArr.count)

                targesArr[i] = assingedValue

//                total = dataArr[i].count

                for n in start..<total {

                    let imageArr = [UInt8](dataArr[i][n]).map { 255 - $0 }

                    let imageNormalArr: [CGFloat] = imageArr.map { CGFloat($0) / CGFloat(pixelNormal) }

                    if CGFloat(n) < CGFloat(total) * traningDataRatio {
                        traningObj.append(imageNormalArr)
                        targetTarningObj.append(targesArr)
                    }
                    else {
                        testingObj.append(imageNormalArr)
                        testingTarningObj.append(targesArr)
                    }
                }
            }

            DispatchQueue.main.async {
                loading.invalidate()
                loadingLabel.removeFromSuperview()
            }

            /// 4  ================================================

            let indexForLength = 0

            label = "ML1"

            inputs = traningObj

            targets = targetTarningObj

            number_of_input = inputs[indexForLength].count

            number_of_hidden = 64

            number_of_outputs = targets[indexForLength].count

            iterations = 10

            numberOfTraningsForIteration = inputs.count

            inputsTest = testingObj

            targetsTest = testingTarningObj

            complete()
        }
    }
    
    var updateImage: ((_ label: Int, _ index: Int) -> ())!
    
    var ui = false
    
    var startImage = true
    
    var frameRate = 2
    
    func uiFunc() {
        
        var frameCount = 0
        
        guard !ui else { return }
        
        ui = true
        
        let title = UILabel(frame: CGRect(origin: CGPoint(x: view.center.x - 210, y: 60), size: CGSize(width: 400, height: 50)))
        title.numberOfLines = 0
        title.textAlignment = .center
        title.font = UIFont(name: "AvenirNext", size: 18)
        
        let imageWrraperView = UIView(frame: CGRect(origin: CGPoint(x: view.center.x - 201, y: 84), size: CGSize(width: 400, height: 400)))
        
        imageWrraperView.layer.cornerRadius = 10
        imageWrraperView.layer.borderWidth = 4
        imageWrraperView.layer.borderColor = UIColor.darkGray.cgColor
        
        let imageWrraperSubview = UIView(frame: CGRect(origin: imageWrraperView.bounds.origin, size: CGSize(width: 118, height: 118)))
        imageWrraperSubview.contentMode = .scaleAspectFill
        imageWrraperSubview.contentScaleFactor = 10
        imageWrraperSubview.clipsToBounds = true
        imageWrraperSubview.layer.cornerRadius = 10
        imageWrraperSubview.backgroundColor = .white
        
        let imageView = UIImageView(frame:  CGRect(origin: CGPoint(x: imageWrraperSubview.bounds.origin.x + 9, y: imageWrraperSubview.bounds.origin.y + 9), size: CGSize(width: 100, height: 100)))
        
        imageWrraperSubview.addSubview(imageView)
        imageWrraperView.addSubview(imageWrraperSubview)
        
        imageWrraperView.backgroundColor = .systemGray
        
        imageWrraperSubview.center = CGPoint(x: imageWrraperView.center.x - 10 , y:  imageWrraperView.center.y - 90)
        
        titleLabel.alpha = 0.5
        sperLabel.alpha = 0.5
        startButton.alpha = 0.5
        saveButton.alpha = 0.5
        loadButton.alpha = 0.5
        
        UIView.animate(withDuration: 0.4) { [self] in
            startButton.frame = CGRect(origin: CGPoint(x: saveButton.frame.origin.x, y: view.center.y + 28), size: saveButton.frame.size)
            saveButton.frame = CGRect(origin: CGPoint(x: saveButton.frame.origin.x, y: view.center.y + 154), size: saveButton.frame.size)
            loadButton.frame = CGRect(origin: CGPoint(x: loadButton.frame.origin.x, y: view.center.y + 280), size: loadButton.frame.size)
            titleLabel.frame = CGRect(origin: CGPoint(x: titleLabel.frame.origin.x, y: 4), size: titleLabel.frame.size)
            sperLabel.frame = CGRect(origin: CGPoint(x: sperLabel.frame.origin.x, y: 12), size: sperLabel.frame.size)
            
            startButton.alpha = 1
            saveButton.alpha = 1
            loadButton.alpha = 1
            titleLabel.alpha = 1
            sperLabel.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            imageWrraperView.addSubview(title)
            self.view.addSubview(imageWrraperView)
        }
        
        updateImage = { [self] label, index in
            
            frameCount += 1
            
            guard startImage || frameCount % frameRate == 0 else  { return }
                
            startImage = false
            
            let nextImage = {
                DispatchQueue.main.async {
                    title.alpha = 0.2
                    imageView.alpha = 0.06

                    var arr = inputs[index].map { UInt8($0 * 255) }
                    let size = sqrt(Double(inputs[index].count))
                    let image = byteArrayToCGImage(raw: &arr, w: Int(size), h: Int(size))
                    let predict = brain?.predict(inputs: inputs[index])
                    let max = predict!.max()
                    let mlIndex = predict?.firstIndex(of: max!)
                    let real = "Font Is: "
                    let guass = "NN Predict: "
                    let text = "\(real)\(categorys[label])" + "\n" + "\(guass)\(categorys[mlIndex!])"
                    let attr = NSMutableAttributedString(string: text)
                    
                    let startRange = (text as NSString).range(of: real)
                    let endRange = (text as NSString).range(of: guass)
                    
                    attr.addAttributes([.foregroundColor : UIColor.purple], range: NSRange(location: startRange.location + startRange.length, length: categorys[label].count))
                    
                    attr.addAttributes([.foregroundColor : label == mlIndex ? UIColor.green : UIColor.systemRed], range: NSRange(location: endRange.location + endRange.length, length: (categorys[mlIndex!].count)))
                    
                    attr.addAttributes([.font : UIFont(name: "AvenirNext-Bold", size: 18)! as UIFont], range: startRange)
                    
                    attr.addAttributes([.font : UIFont(name: "AvenirNext-Bold", size: 18)! as UIFont], range: endRange)
                    
                    title.attributedText = attr
                    
                    UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn) {
                        title.alpha = 1
                        imageView.image = UIImage(cgImage: image!)
                        imageView.alpha = 1
                    }
                }
            }
            
            nextImage()
        }
    }
    
    @objc func start() {
        
        self.startButton.setTitle("Restart", for: .normal)
        
        brain?.stop()
        
        if brain == nil {
            
            uiFunc()
            
            brain = Brain<CGFloat>.create(label: label ,number_of_input: number_of_input, number_of_hidden: number_of_hidden, number_of_outputs: number_of_outputs)
        }
        
        print(true)
        
        ml(on: true)
        
        DispatchQueue(label: "work").async { [self] in
            mlStart()
        }
    }
    
    @objc func save() {
        ml(on: false)
        
        let success = brain?.save(name: brain!.getLabel())
        
        print(success!)
        
        ml(on: true)
    }
    
    @objc func load() {
        ml(on: false)
        
        startButton.setTitle("Restart", for: .normal)
        
        brain?.stop()
        
        DispatchQueue(label: "work").async { [self] in
            
            guard let brainObj = Brain<CGFloat>.load(name: label) else {
                print(false)
                return
            }
            
            DispatchQueue.main.async {
                uiFunc()
            }
            
            brain = brainObj
            brain?.changeSize(number_of_input: number_of_input, number_of_hidden: number_of_hidden, number_of_outputs: number_of_outputs)
            label = brain!.getLabel()
            
            brain?.setTraindIndex(traindIndex: { target, index in
                updateImage(target.firstIndex(where: { num in
                    return num == 1
                })!, index)
            }, complete: {
                print(true)
                mlStart()
            })
        }
        
        ml(on: true)
    }
    
    func ml(on: Bool) {
        DispatchQueue.main.async {
            self.startButton.isEnabled = on
            self.saveButton.isEnabled = on
            self.loadButton.isEnabled = on
            self.frameRate = 2
        }
    }
    
    var uiUp = 0
    
    func mlStart() {
        
        uiUp = 0

        DispatchQueue(label: "work").async { [self] in
            brain?.start(inputs: inputs, targets: targets, iterations: iterations, numberOfTraningsForIteration: numberOfTraningsForIteration,
                         traindIndex: { target, index in
                            guard uiUp % 10 == 0 || uiUp == targets.count - 1 else {
                                uiUp += 1
                                return
                            }
                            
                            uiUp += 1
                            
                            updateImage(target.firstIndex(where: { num in
                                return num == 1
                            })!, index)
                         },
                         progressUpdate: { iteration in
                            let iter = " ( Iteration: \(iteration) ) "
                            
                            brain?.printDescription(inputs: inputs, targets: targets, title: iter)
                            
                            print()
                            
                         }, completed: {
                            
                            for i in 0..<targetsTest.count {
                                guard i % 4 == 0 || i == targets.count - 1 else {
                                    continue
                                }
                                
                                updateImage(targetsTest[i].firstIndex(where: { num in
                                    return num == 1
                                })!, i)
                            }
                            
                            print()
                            print()
                            let s = " .... Done .... "
                            brain?.printDescription(inputs: inputsTest, targets: targetsTest, title: s, fullDesc: true)
                            
                            print(s)
                         })
        }
    }
}

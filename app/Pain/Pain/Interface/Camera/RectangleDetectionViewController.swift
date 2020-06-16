//
//  RectangleDetectionViewController.swift
//  TestApp1
//
//  Created by Andrei Popa on 31/03/2020.
//  Copyright © 2020 Andrei Popa. All rights reserved.
//

import AVFoundation
import CoreImage
import Foundation
import UIKit
import Vision

extension CGPoint {
    func scaled(to size: CGSize, inverse: Bool = false) -> CGPoint {
        if !inverse {
            return CGPoint(x: self.x * size.width,
                           y: self.y * size.height)
        } else {
            return CGPoint(x: self.x * size.width,
                           y: (1 - self.y) * size.height)
        }
    }
}

class RectangleDetectionViewController: CameraViewController {
    // MARK: Static constants
    private static let SMALLER_EDGE = CGFloat(0.08)
    private static let BIGGER_EDGE = CGFloat(0.1)
    
    // MARK: Properties
    private let api = APICalls()

    private var detectionOverlay: CALayer!
    private var coverOverlay: CoverLayer!
    private var coverWeights: Weights!
    
    internal var imageDetection: Detection?
    internal var imagePixelBuffer: CVPixelBuffer!
    
    override func setupCapture() {
        super.setupCapture()
        takePhotoButton.isEnabled = false
        self.setupLayers()
        startCapturing()
    }
    
    func getCoverEdgeSizes(orientation: UIDeviceOrientation) -> Weights {
        var horizontal = RectangleDetectionViewController.SMALLER_EDGE
        var vertical = RectangleDetectionViewController.BIGGER_EDGE
        if orientation.isLandscape {
            swap(&vertical, &horizontal)
        }
        var rect = Weights(top: vertical, bottom: vertical, left: horizontal, right: horizontal)
        if orientation.isLandscape {
            rect.right += vertical * 1.0
        } else {
            rect.bottom += vertical * 1.0
        }
        return rect
    }
    
    func setupLayers() {
        detectionOverlay = CALayer()
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.frame = rootLayer.bounds
        rootLayer.insertSublayer(detectionOverlay, below: takePhotoButton.layer)
        
        coverWeights = getCoverEdgeSizes(orientation: currentCameraOrientation)
        coverOverlay = CoverLayer()
        coverOverlay.fillColor = UIColor.black.cgColor.copy(alpha: 0.2)
        coverOverlay.setShape(bounds: rootLayer.bounds, weights: coverWeights)
        
        rootLayer.insertSublayer(coverOverlay, below: takePhotoButton.layer)
    }
    
    private func orientationChange(size: CGSize) {
        detectionOverlay.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        coverWeights = getCoverEdgeSizes(orientation: currentCameraOrientation)
        coverOverlay.setShape(bounds: CGRect(x: 0, y: 0, width: size.width, height: size.height),
                              weights: coverWeights)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.orientationChange(size: rootLayer.bounds.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.orientationChange(size: size)
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let exifOrientation = exifOrientationFromDeviceOrientation()
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                        orientation: exifOrientation,
                                                        options: [:])
        let req = VNDetectRectanglesRequest(completionHandler: self.handleRectangles(pixelBuffer))
        req.maximumObservations = 8
        req.minimumConfidence = 0.6
        req.minimumAspectRatio = 0.3
        do {
            try imageRequestHandler.perform([req])
        } catch let error as NSError {
            print("Detection failed")
            print(error)
            return
        }
    }

    // Takes the found rectangles, filters them, draws them and cuts and skews the unique rectangle
    // found where it is the case
    func handleRectangles(_ pixelBuffer: CVPixelBuffer) -> ((VNRequest, Error?) -> Void) {
        return { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                guard let results = request.results as? [VNRectangleObservation] else {
                    print("Not the expected type")
                    return
                }
                let rectangles = self.observationsToRectangles(results)
                let filteredRectangles = self.filterDetections(rectangles)
                self.imagePixelBuffer = pixelBuffer
                if filteredRectangles.count == 1 {
                    let previous = self.imageDetection
                    self.imageDetection = filteredRectangles[0]
                    if previous == nil {
                        self.takePhotoButton.isEnabled = true
                    }
                } else {
                    if self.imageDetection != nil {
                        self.takePhotoButton.isEnabled = false
                    }
                    self.imageDetection = nil
                }
                let color = (filteredRectangles.count == 1 ? UIColor.green : UIColor.red)
                    .cgColor
                self.drawRectangles(rectangles: filteredRectangles, color: color)
            }
        }
    }
    
    // Takes the observed rectangles which have coordintates in [0, 1] and returns
    // the rectangles in `rootLayer`s bounds space (they can be out of bounds though)
    private func observationsToRectangles(_ observations: [VNRectangleObservation]) -> [Detection] {
        let bounds = rootLayer.bounds
        
        // The buffer should be 640x480 (the value `size` width x height, the bigger dimension first)
        // If the device is in portrait, the bigger dimension will be actually the height (the height and width are swapped)
        var trueBufferSize = bufferSize;
        if currentCameraOrientation.isPortrait {
            trueBufferSize = CGSize(width: bufferSize.height, height: bufferSize.width)
        }
        
        // The video will be centered in the view, but its dimensions don't correspond to the preview's layer dimensions
        // So we compute the scalings
        let xScale: CGFloat = bounds.size.width / trueBufferSize.width
        let yScale: CGFloat = bounds.size.height / trueBufferSize.height
        
        // The video will take the whole view, so the biger scale is the one the video scales with
        var scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        
        // One of the preview's layer dimensions will be equal to the view coresponding dimension,
        // the other will be bigger and centered, so one of the following values will be 0
        let xAdd = -(trueBufferSize.width * scale - bounds.size.width) / 2.0
        let yAdd = -(trueBufferSize.height * scale - bounds.size.height) / 2.0
        let transform = { (p: CGPoint) -> CGPoint in
            var p1 = p.scaled(to: trueBufferSize, inverse: true)
            p1 = CGPoint(x: p1.x * scale, y: p1.y * scale)
            p1 = CGPoint(x: p1.x + xAdd, y: p1.y + yAdd)
            return p1
        }
        return observations.map { (observation) -> Detection in
        Detection(original: observation,
                         relocated: Polygon(points: [
                             transform(observation.topLeft),
                             transform(observation.topRight),
                             transform(observation.bottomRight),
                             transform(observation.bottomLeft),
                         ])) }
    }
    
    private func filterDetections(_ rectangles: [Detection]) -> [Detection] {
        var rectangles = filterDetectionsByBounds(rectangles)
        rectangles = filterDetectionsByInclusion(rectangles)
        return rectangles
    }
    
    private func filterDetectionsByBounds(_ rectangles: [Detection]) -> [Detection] {
        let bounds = rootLayer.bounds
        let top = coverWeights.top * bounds.height
        let bottom = (1 - coverWeights.bottom) * bounds.height
        let left = coverWeights.left * bounds.width
        let right = (1 - coverWeights.right) * bounds.width
        let ratio = CGFloat(1.0 / 10.0)
        return rectangles.filter { detection in
            let rectangle = detection.relocated
            return rectangle.points.filter { p in
                let closeHorizontal =
                    (abs(p.y - top) < bounds.height * ratio || abs(p.y - bottom) < bounds.height * ratio)
                    && left - bounds.width * ratio < p.x && p.x < right + bounds.width * ratio
                let closeVertical =
                    (abs(p.x - left) < bounds.width * ratio || abs(p.x - right) < bounds.width * ratio)
                        && top - bounds.height * ratio < p.y && p.y < bottom + bounds.height * ratio
                return closeHorizontal || closeVertical
            }.count == rectangle.points.count
        }
    }
    
    // This is not used at the moment, but I will leave it here just in case
    private func filterDetectionsByInclusion(_ rectangles: [Detection]) -> [Detection] {
        let crossProduct = { (o: CGPoint, a: CGPoint, b: CGPoint) -> Double in
            Double((a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x))
        }
        return rectangles.filter { detection in
            let rectangle = detection.relocated
            var keep = true
            for otherDetection in rectangles {
                let otherRectangle = otherDetection.relocated
                if rectangle == otherRectangle {
                    continue
                }
                var rectangleOutside = false
                for point1 in rectangle.points {
                    var pointOutside = false
                    for i in 0..<4 {
                        if crossProduct(otherRectangle.points[i], otherRectangle.points[(i + 1) % 4], point1) < 0 {
                            pointOutside = true
                            break
                        }
                    }
                    if pointOutside {
                        rectangleOutside = true
                        break
                    }
                }
                if !rectangleOutside {
                    keep = false
                    break
                }
            }
            return keep
        }
    }

    func drawRectangles(rectangles: [Detection], color: CGColor) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil
        for rectangleDetection in rectangles {
            let rectangle = rectangleDetection.relocated
            let linePath = UIBezierPath()
            linePath.move(to: rectangle.points.last!)
            for point in rectangle.points {
                linePath.addLine(to: point)
            }
            let line = CAShapeLayer()
            line.path = linePath.cgPath
            line.fillColor = color
            line.opacity = 0.2
            detectionOverlay.addSublayer(line)
        }
        CATransaction.commit()
    }
    
    func cutAndSkew(pixelBuffer: CVPixelBuffer, rect: VNRectangleObservation) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            .oriented(exifOrientationFromDeviceOrientation())
        return self.cutAndSkew(ciImage: ciImage, rect: rect)
    }
    
    func cutAndSkew(ciImage: CIImage, rect: VNRectangleObservation) -> CGImage? {
        let ciContext = CIContext()
        let filter = CIFilter(name: "CIPerspectiveCorrection")!
        filter.setValue(CIVector(cgPoint: rect.topLeft.scaled(to: ciImage.extent.size)), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: rect.topRight.scaled(to: ciImage.extent.size)), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: rect.bottomRight.scaled(to: ciImage.extent.size)), forKey: "inputBottomRight")
        filter.setValue(CIVector(cgPoint: rect.bottomLeft.scaled(to: ciImage.extent.size)), forKey: "inputBottomLeft")
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        if let output = filter.outputImage,
            let cgImage = ciContext.createCGImage(output, from: output.extent) {
            return cgImage
        } else {
            return nil
        }
    }
    
    private func rotationAngle(orientation: UIDeviceOrientation) -> CGFloat {
        switch orientation {
        case .portrait: return CGFloat(.pi / 2.0)
        case .portraitUpsideDown: return CGFloat(3.0 * .pi / 2.0)
        case .landscapeRight: return CGFloat(0)
        case .landscapeLeft: return CGFloat(1.0 * .pi)
        default: return -1
        }
    }
    
    //MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch (segue.identifier ?? "") {
        case "ShowResults":
            guard let paintingTableController = segue.destination as? PaintingTableViewController else {
                fatalError("Unexpected segue destination: \(segue.destination)")
            }
            guard let imageDetection = self.imageDetection else {
                return
            }
            guard let cgImage = cutAndSkew(pixelBuffer: self.imagePixelBuffer, rect: imageDetection.original) else {
                fatalError("Could not create cgImage")
            }
            let uiImage = UIImage(cgImage: cgImage)
            paintingTableController.fromDetection = true
            api.uploadImageToServer(image: uiImage) { (paintings, err) in
                if let paintings = paintings {
                    paintingTableController.paintings = paintings
                    paintingTableController.tableView.reloadData()
                }
            }
        default:
            print(segue.identifier ?? "<nil>")
            fatalError("Unexpected transition")
        }
    }
    
    @IBAction func backToCameraAction(unwindSegue: UIStoryboardSegue) {
        
    }
}

struct Detection {
    var original: VNRectangleObservation
    var relocated: Polygon
}

struct Polygon: Equatable {
    var points: [CGPoint]
}

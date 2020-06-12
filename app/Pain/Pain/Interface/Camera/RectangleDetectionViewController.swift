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
    private var detectionOverlay: CALayer!
    private var coverOverlay: CoverLayer!
    
    override func setupCapture() {
        super.setupCapture()
        self.setupLayers()
        self.updateOverlayGeometry()
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
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX,
                                            y: rootLayer.bounds.midY)
        rootLayer.insertSublayer(detectionOverlay, below: takePhotoButton.layer)
        
        let weights = getCoverEdgeSizes(orientation: UIDevice.current.orientation)
        coverOverlay = CoverLayer()
        coverOverlay.fillColor = UIColor.black.cgColor.copy(alpha: 0.2)
        coverOverlay.setShape(bounds: rootLayer.bounds, weights: weights)
        
        rootLayer.insertSublayer(coverOverlay, below: takePhotoButton.layer)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let weights = getCoverEdgeSizes(orientation: UIDevice.current.orientation)
        coverOverlay.setShape(bounds: CGRect(x: 0, y: 0, width: size.width, height: size.height),
                              weights: weights)
    }
    
    func updateOverlayGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        // The buffer should be 640x480 (the value `size` width x height, the bigger dimension first)
        // If the device is in portrait, the bigger dimension will be actually the height (the height and width are swapped)
        var switchWidthHeight = false
        switch UIDevice.current.orientation {
        case .portraitUpsideDown, .portrait:
            switchWidthHeight = true
        default:
            ()
        }
        
        // The video will be centered in the view, but its dimensions don't correspond to the preview's layer dimensions
        // So we compute the scalings
        let xScale: CGFloat = switchWidthHeight ? bounds.size.width / bufferSize.height :
            bounds.size.width / bufferSize.width
        let yScale: CGFloat = switchWidthHeight ? bounds.size.height / bufferSize.width :
            bounds.size.height / bufferSize.height
        
        // The video will occupy the whole view, so the biger scale is the one the video scales with
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        var yMultiplier = 1.0
        switch UIDevice.current.orientation {
        case .portrait, .landscapeRight: yMultiplier = -1.0
        default: ()
        }
        let transformation = CGAffineTransform(rotationAngle: rotationAngle(orientation: UIDevice.current.orientation))
            .scaledBy(x: scale, y: scale * CGFloat(yMultiplier))
        detectionOverlay.setAffineTransform(transformation)
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
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
                guard var results = request.results as? [VNRectangleObservation] else {
                    print("Not the expected type")
                    return
                }
                results = self.filterRectangles(rectangles: results)
                results = self.filterRectanglesByBounds(rectangles: results)
                results = self.filterRectanglesByInclusion(rectangles: results)
    //            print("Result count: \(results.count)")
                self.drawRectangles(rectangles: results)
                if results.count != 1 {
    //                print("No extracted image, number of rectangles detected: \(results.count)")
                } else {
                
                    guard let cutImage = self.cutAndSkew(pixelBuffer: pixelBuffer, rect: results[0]) else {
                        print("Could not cut and skew the image!")
                        return
                    }
//                    self.correctedImage.image = UIImage(cgImage: cutImage)
                }
            }
        }
    }
    
    private func filterRectangles(rectangles: [VNRectangleObservation]) -> [VNRectangleObservation] {
        var rectangles = filterRectanglesByBounds(rectangles: rectangles)
        rectangles = filterRectanglesByInclusion(rectangles: rectangles)
        return rectangles
    }
    
    private func filterRectanglesByBounds(rectangles: [VNRectangleObservation]) -> [VNRectangleObservation] {
        return rectangles
    }
    
    private func filterRectanglesByInclusion(rectangles: [VNRectangleObservation]) -> [VNRectangleObservation] {
        return rectangles
    }
    
    func drawRectangles(rectangles: [VNRectangleObservation]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil
        for rectangle in rectangles {
            let linePath = UIBezierPath()
            let points = [rectangle.bottomLeft, rectangle.topLeft, rectangle.topRight, rectangle.bottomRight]
            print("\(rectangle.topLeft) \(rectangle.bottomRight)")
            linePath.move(to: points[3].scaled(to: bufferSize))
            for point in points {
                linePath.addLine(to: point.scaled(to: bufferSize))
            }
            let line = CAShapeLayer()
            line.path = linePath.cgPath
            line.fillColor = nil
            line.opacity = 1.0
            line.strokeColor = UIColor.red.cgColor
            detectionOverlay.addSublayer(line)
        }
        self.updateOverlayGeometry()
        CATransaction.commit()
    }
    
    func cutAndSkew(pixelBuffer: CVPixelBuffer, rect: VNRectangleObservation) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
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
}

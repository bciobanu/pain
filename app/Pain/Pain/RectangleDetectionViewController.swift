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
    // MARK: Properties
    private var detectionOverlay: CALayer!
    
    override func setupCapture() {
        super.setupCapture()
        print("Here")
        self.setupLayers()
        self.updateOverlayGeometry()
        startCapturing()
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
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateOverlayGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
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
    
    func filterRectanglesByBounds(rectangles: [VNRectangleObservation]) -> [VNRectangleObservation] {
        return rectangles
    }
    
    func filterRectanglesByInclusion(rectangles: [VNRectangleObservation]) -> [VNRectangleObservation] {
        return rectangles
    }
    
    func drawRectangles(rectangles: [VNRectangleObservation]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil
        for rectangle in rectangles {
            let linePath = UIBezierPath()
            let points = [rectangle.bottomLeft, rectangle.topLeft, rectangle.topRight, rectangle.bottomRight]
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
//        self.updateOverlayGeometry()
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
}

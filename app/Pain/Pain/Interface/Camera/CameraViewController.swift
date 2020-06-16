import AVFoundation
import CoreGraphics
import CoreImage
import UIKit


class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: Capture
    private let session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(
        label: "VideoDataOutput",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem)
    internal var previewLayer: AVCaptureVideoPreviewLayer!
    internal var bufferSize: CGSize = .zero
    
    // MARK: Animation
    internal var rootLayer: CALayer!

    // MARK: Properties
    @IBOutlet internal weak var previewView: UIView!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    override var prefersStatusBarHidden: Bool {
        true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCapture()
    }
    
    func setupCapture() {
        var deviceInput: AVCaptureDeviceInput
        let videoDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
            ).devices.first;
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        
        guard session.canAddInput(deviceInput) else {
            print("Could not add video device to session input")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video output to session")
            session.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames?
        captureConnection?.isEnabled = true
        do {
            try videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions(
                videoDevice!.activeFormat.formatDescription)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        if let orientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation) {
            previewLayer.connection?.videoOrientation = orientation
        }
        rootLayer.insertSublayer(previewLayer, below: takePhotoButton.layer)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        previewLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let deviceOrientation = UIDevice.current.orientation
        
        guard let videoPreviewLayerConnection = previewLayer.connection else {
            return
        }
        guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
            deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                return
        }
        
        videoPreviewLayerConnection.videoOrientation = newVideoOrientation
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput: CMSampleBuffer,
                       from: AVCaptureConnection) {
        // Implementation in the subclass
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop: CMSampleBuffer,
                       from: AVCaptureConnection) {
        // Implementation in the subclass
    }
    
    func startCapturing() {
        print("Start capturing")
        session.startRunning()
    }
    
    func tearDownCapture() {
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .up
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .right
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}

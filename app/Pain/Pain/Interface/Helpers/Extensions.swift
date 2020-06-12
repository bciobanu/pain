import UIKit
import AVFoundation

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
    
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension UIDeviceOrientation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .faceDown: return "<UIDeviceOrientation: face down>"
        case .faceUp: return "<UIDeviceOrientation: face up>"
        case .portrait: return "<UIDeviceOrientation: portrait>"
        case .portraitUpsideDown: return "<UIDeviceOrientation: portrait upside down>"
        case .landscapeLeft: return "<UIDeviceOrientation: landscape left>"
        case .landscapeRight: return "<UIDeviceOrientation: landscape right>"
        case .unknown: return "<UIDeviceOrientation: unknown>"
        default: return "<UIDeviceOrientation: other>"
        }
    }
}

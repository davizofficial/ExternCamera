import AVFoundation
import UIKit

class CameraPreviewView: UIView {
    var session: AVCaptureSession? {
        get { return (layer as? AVCaptureVideoPreviewLayer)?.session }
        set { (layer as? AVCaptureVideoPreviewLayer)?.session = newValue }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
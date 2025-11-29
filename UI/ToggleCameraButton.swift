import UIKit

class ToggleCameraButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        tintColor = .white
        imageView?.contentMode = .scaleAspectFit
    }
}
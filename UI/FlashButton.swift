import UIKit

class FlashButton: UIButton {
    var isOn = false {
        didSet {
            setImage(isOn ? UIImage(systemName: "bolt.fill") : UIImage(systemName: "bolt.slash.fill"), for: .normal)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        tintColor = .white
    }
}
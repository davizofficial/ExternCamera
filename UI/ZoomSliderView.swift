import UIKit

class ZoomSliderView: UIView {
    let slider = UISlider()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor(white: 0, alpha: 0.5)
        layer.cornerRadius = 10
        
        slider.minimumValue = 1
        slider.maximumValue = 10
        slider.value = 1
        slider.thumbTintColor = .white
        slider.minimumTrackTintColor = .white
        
        addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: centerYAnchor),
            slider.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8)
        ])
    }
}
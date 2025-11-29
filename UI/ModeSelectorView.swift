import UIKit

protocol ModeSelectorDelegate: AnyObject {
    func didSelectMode(_ mode: CameraMode)
}

class ModeSelectorView: UIView {
    
    weak var delegate: ModeSelectorDelegate?
    private var selectedMode: CameraMode = .photo
    private var modeButtons: [CameraMode: UIButton] = [:]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
        
        for mode in CameraMode.allCases {
            let button = UIButton(type: .system)
            button.setTitle(mode.rawValue, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            button.tintColor = mode == selectedMode ? .systemYellow : .white
            button.tag = CameraMode.allCases.firstIndex(of: mode) ?? 0
            button.addTarget(self, action: #selector(didTapMode), for: .touchUpInside)
            
            stackView.addArrangedSubview(button)
            modeButtons[mode] = button
            
            if mode != CameraMode.allCases.last {
                let spacer = UIView()
                spacer.widthAnchor.constraint(equalToConstant: 30).isActive = true
                stackView.addArrangedSubview(spacer)
            }
        }
    }
    
    @objc private func didTapMode(_ sender: UIButton) {
        let mode = CameraMode.allCases[sender.tag]
        selectMode(mode)
        delegate?.didSelectMode(mode)
    }
    
    private func selectMode(_ mode: CameraMode) {
        selectedMode = mode
        for (m, button) in modeButtons {
            button.tintColor = m == mode ? .systemYellow : .white
        }
    }
}

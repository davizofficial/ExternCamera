import UIKit

class TimerButton: UIButton {
    var onSelect: ((Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        setImage(UIImage(systemName: "timer"), for: .normal)
        tintColor = .white
    }
    
    func showTimerActions(completion: @escaping (Int) -> Void) {
        let alert = UIAlertController(title: "Timer", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "3 Detik", style: .default) { _ in completion(3) })
        alert.addAction(UIAlertAction(title: "10 Detik", style: .default) { _ in completion(10) })
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
}
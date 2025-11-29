import UIKit

class GridOverlayView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setStrokeColor(UIColor(white: 1.0, alpha: 0.3).cgColor)
        ctx.setLineWidth(1.0)
        
        let v1 = rect.width / 3
        let v2 = v1 * 2
        ctx.move(to: CGPoint(x: v1, y: 0))
        ctx.addLine(to: CGPoint(x: v1, y: rect.height))
        ctx.move(to: CGPoint(x: v2, y: 0))
        ctx.addLine(to: CGPoint(x: v2, y: rect.height))
        
        let h1 = rect.height / 3
        let h2 = h1 * 2
        ctx.move(to: CGPoint(x: 0, y: h1))
        ctx.addLine(to: CGPoint(x: rect.width, y: h1))
        ctx.move(to: CGPoint(x: 0, y: h2))
        ctx.addLine(to: CGPoint(x: rect.width, y: h2))
        
        ctx.strokePath()
    }
}
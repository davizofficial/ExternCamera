import UIKit

class SquareFrameOverlay: UIView {
    
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
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Calculate square frame (centered, width = screen width)
        let squareSize = rect.width
        let squareY = (rect.height - squareSize) / 2
        let squareFrame = CGRect(x: 0, y: squareY, width: squareSize, height: squareSize)
        
        // Draw black overlay on top and bottom
        context.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
        
        // Top overlay
        if squareY > 0 {
            context.fill(CGRect(x: 0, y: 0, width: rect.width, height: squareY))
        }
        
        // Bottom overlay
        let bottomY = squareY + squareSize
        if bottomY < rect.height {
            context.fill(CGRect(x: 0, y: bottomY, width: rect.width, height: rect.height - bottomY))
        }
        
        // Draw white border around square frame
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1.0)
        context.stroke(squareFrame)
    }
}

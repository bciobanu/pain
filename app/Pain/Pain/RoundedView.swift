import UIKit

class RoundedView: UIView {

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.layer.shadowOpacity = 0.2
        self.layer.shadowRadius = 1
    }

}

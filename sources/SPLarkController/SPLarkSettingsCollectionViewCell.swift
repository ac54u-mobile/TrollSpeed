// The MIT License (MIT)
// Copyright © 2017 Ivan Vorobei (hello@ivanvorobei.by)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

@available(iOS 8.2, *)
public class SPLarkSettingsCollectionViewCell: UICollectionViewCell {

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let backgroundColorView = UIView()
    let iconBackgroundView = UIView()
    let iconImageView = UIImageView()

    private static let pressDownScale: CGFloat = 0.975
    private static let animationDuration: TimeInterval = 0.28
    private static let animationDamping: CGFloat = 0.86

    private func animatePress() {
        UIView.animate(withDuration: Self.animationDuration, delay: 0, usingSpringWithDamping: Self.animationDamping, initialSpringVelocity: 0, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction], animations: {
            self.transform = CGAffineTransform(scaleX: Self.pressDownScale, y: Self.pressDownScale)
        }, completion: nil)
    }

    private func animateRelease() {
        UIView.animate(withDuration: Self.animationDuration, delay: 0, usingSpringWithDamping: Self.animationDamping, initialSpringVelocity: 0, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction], animations: {
            self.transform = .identity
        }, completion: nil)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        animatePress()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animateRelease()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animateRelease()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        self.backgroundColor = .clear

        self.backgroundColorView.layer.masksToBounds = true
        self.backgroundColorView.layer.cornerRadius = 18
        self.backgroundColorView.layer.cornerCurve = .continuous
        self.contentView.addSubview(self.backgroundColorView)

        self.iconBackgroundView.layer.cornerRadius = 11
        self.iconBackgroundView.layer.cornerCurve = .continuous
        self.iconBackgroundView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.12)
        self.contentView.addSubview(self.iconBackgroundView)

        self.iconImageView.contentMode = .scaleAspectFit
        self.iconImageView.tintColor = .systemIndigo
        self.iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        self.iconBackgroundView.addSubview(self.iconImageView)

        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        self.titleLabel.adjustsFontForContentSizeCategory = true
        self.titleLabel.numberOfLines = 1
        self.titleLabel.textAlignment = .left
        self.titleLabel.baselineAdjustment = .alignBaselines
        self.titleLabel.textColor = UIColor.label
        self.titleLabel.text = "Title"
        self.contentView.addSubview(self.titleLabel)
        
        self.subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        self.subtitleLabel.adjustsFontForContentSizeCategory = true
        self.subtitleLabel.numberOfLines = 1
        self.subtitleLabel.textAlignment = .right
        self.subtitleLabel.textColor = UIColor.secondaryLabel
        self.subtitleLabel.text = "Subtitle"
        self.contentView.addSubview(self.subtitleLabel)
    }
    
    func setHighlighted(_ state: Bool, color: UIColor) {
        self.backgroundColorView.backgroundColor = state ? color.withAlphaComponent(0.18) : UIColor.secondarySystemGroupedBackground
        self.iconBackgroundView.backgroundColor = state ? color.withAlphaComponent(0.22) : UIColor.systemIndigo.withAlphaComponent(0.12)
        self.iconImageView.tintColor = state ? color : UIColor.systemIndigo
    }

    func setIcon(_ systemName: String) {
        self.iconImageView.image = UIImage(systemName: systemName)
    }
    
    func setEnabled(_ enabled: Bool) {
        self.contentView.alpha = enabled ? 1.0 : 0.4
        self.isUserInteractionEnabled = enabled
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.contentView.alpha = 1.0
        self.isUserInteractionEnabled = true
        self.titleLabel.text = "Title"
        self.subtitleLabel.text = "Subtitle"
        self.iconImageView.image = nil
        self.layoutSubviews()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundColorView.frame = self.contentView.bounds
        
        let iconSize: CGFloat = 42
        let sideInset: CGFloat = 13
        self.iconBackgroundView.frame = CGRect(x: sideInset, y: (bounds.height - iconSize) / 2, width: iconSize, height: iconSize)
        self.iconImageView.frame = self.iconBackgroundView.bounds.insetBy(dx: 10, dy: 10)
        self.subtitleLabel.sizeToFit()
        let subtitleWidth = min(self.subtitleLabel.bounds.width, bounds.width * 0.32)
        self.subtitleLabel.frame = CGRect(x: bounds.width - sideInset - subtitleWidth, y: 0, width: subtitleWidth, height: bounds.height)
        let titleX = self.iconBackgroundView.frame.maxX + 13
        self.titleLabel.frame = CGRect(x: titleX, y: 0, width: max(0, self.subtitleLabel.frame.minX - titleX - 12), height: bounds.height)
    }
}

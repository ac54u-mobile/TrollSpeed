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

final class SPLarkSettingsSectionHeader: UICollectionReusableView {
    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .secondaryLabel
        addSubview(titleLabel)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = bounds.insetBy(dx: 27, dy: 0)
    }
}

@available(iOS 8.2, *)
open class SPLarkSettingsController: UIViewController {
    
    public let titleLabel = UILabel()
    let closeButton = SPLarkSettingsCloseButton()
    let collectionView = SPLarkSettingsCollectionView()
    
    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .slide }
    
    open func settingsCount() -> Int {
        fatalError("SPLarkSettingsController - Need implement function")
    }

    open func settingsSectionCount() -> Int { return 1 }
    open func settingsCount(section: Int) -> Int { return section == 0 ? settingsCount() : 0 }
    open func settingIndex(indexPath: IndexPath) -> Int { return indexPath.row }
    open func settingSectionTitle(section: Int) -> String? { return nil }
    open func settingIconName(index: Int) -> String { return "slider.horizontal.3" }
    
    open func settingTitle(index: Int, highlighted: Bool) -> String {
        fatalError("SPLarkSettingsController - Need implement function")
    }
    
    open func settingSubtitle(index: Int, highlighted: Bool) -> String? {
        fatalError("SPLarkSettingsController - Need implement function")
    }
    
    open func settingHighlighted(index: Int) -> Bool {
        fatalError("SPLarkSettingsController - Need implement function")
    }
    
    open func settingColorHighlighted(index: Int) -> UIColor {
        fatalError("SPLarkSettingsController - Need implement function")
    }
    
    open func settingDidSelect(index: Int, completion: @escaping () -> ()) {
        fatalError("SPLarkSettingsController - Need implement function")
    }
    
    open func settingEnabled(index: Int) -> Bool {
        return true
    }
    
    open func reload(index: Int) {
        self.collectionView.reloadItems(at: [IndexPath.init(row: index, section: 0)])
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = NSLocalizedString("Settings", comment: "")
        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        self.titleLabel.adjustsFontForContentSizeCategory = true
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.label
        self.titleLabel.numberOfLines = 0
        self.view.addSubview(self.titleLabel)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.view.addSubview(self.collectionView)
        
        self.closeButton.sizeToFit()
        self.closeButton.addTarget(self, action: #selector(self.tapCloseButton), for: .touchUpInside)
        self.view.addSubview(self.closeButton)
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.titleLabel.sizeToFit()
        self.titleLabel.frame = CGRect.init(x: 27, y: 36, width: self.view.frame.width - 27 * 2, height: self.titleLabel.frame.height)
        self.collectionView.layout(y: self.titleLabel.frame.origin.y + self.titleLabel.frame.height + 14)
        self.closeButton.layout(bottomX: self.view.frame.width - 19, y: self.titleLabel.frame.origin.y + self.titleLabel.frame.height / 2 - self.closeButton.frame.height / 2 - 2)
    }
    
    @objc func tapCloseButton() {
        self.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 8.2, *)
extension SPLarkSettingsController: UICollectionViewDataSource, UICollectionViewDelegate {

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionView === self.collectionView ? settingsSectionCount() : 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case self.collectionView:
            return self.settingsCount(section: section)
        default:
            return 0
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.collectionView:
            let cell = self.collectionView.dequeueCell(indexPath: indexPath)
            let index = settingIndex(indexPath: indexPath)
            let highlighted = self.settingHighlighted(index: index)
            let enabled = self.settingEnabled(index: index)
            cell.titleLabel.text = self.settingTitle(index: index, highlighted: highlighted)
            cell.subtitleLabel.text = self.settingSubtitle(index: index, highlighted: highlighted)
            cell.setIcon(self.settingIconName(index: index))
            cell.isAccessibilityElement = true
            cell.accessibilityTraits = enabled ? .button : [.button, .notEnabled]
            cell.accessibilityLabel = cell.titleLabel.text
            cell.accessibilityValue = cell.subtitleLabel.text
            cell.setHighlighted(
                highlighted,
                color: highlighted ? self.settingColorHighlighted(index: index) : UIColor.secondarySystemGroupedBackground
            )
            cell.setEnabled(enabled)
            return cell
        default:
            return UICollectionViewCell()
        }
    }

    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SPLarkSettingsSectionHeader", for: indexPath) as! SPLarkSettingsSectionHeader
        header.titleLabel.text = settingSectionTitle(section: indexPath.section)?.uppercased()
        return header
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? SPLarkSettingsCollectionViewCell {
            let index = settingIndex(indexPath: indexPath)
            self.settingDidSelect(index: index) {
                let highlighted = self.settingHighlighted(index: index)
                cell.titleLabel.text = self.settingTitle(index: index, highlighted: highlighted)
                cell.subtitleLabel.text = self.settingSubtitle(index: index, highlighted: highlighted)
                cell.accessibilityValue = cell.subtitleLabel.text
                cell.setHighlighted(
                    highlighted,
                    color: highlighted ? self.settingColorHighlighted(index: index) : UIColor.secondarySystemGroupedBackground
                )
            }
        }
    }
}

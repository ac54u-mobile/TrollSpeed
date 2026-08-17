//
//  TSSettingsController.swift
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

import UIKit

@objc public protocol TSSettingsControllerDelegate {
    func settingHighlighted(key: String) -> Bool
    func settingDidSelect(key: String) -> Void
}

@objc open class TSSettingsController : SPLarkSettingsController
{
    @objc open weak var delegate: TSSettingsControllerDelegate?
    @objc open var alreadyLaunched: Bool = false
    internal var restartRequired = false

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        closeButton.backgroundColor = .tertiarySystemFill
        closeButton.color = .secondaryLabel
    }

    open override func settingsCount() -> Int {
        return TSSettingsIndex.allCases.count
    }

    private let sections: [[TSSettingsIndex]] = [
        [.displayMode],
        [.passthroughMode, .keepInPlace, .hideAtSnapshot],
        [.singleLineMode, .usesInvertedColor, .usesRotation, .usesLargeFont],
        [.usesArrowPrefixes, .usesBitrate],
    ]

    open override func settingsSectionCount() -> Int { return sections.count }
    open override func settingsCount(section: Int) -> Int { return sections[section].count }
    open override func settingIndex(indexPath: IndexPath) -> Int { return sections[indexPath.section][indexPath.row].rawValue }

    open override func settingSectionTitle(section: Int) -> String? {
        let titles = ["Monitor", "Behavior", "Appearance", "Data Format"]
        return NSLocalizedString(titles[section], comment: "Settings section")
    }

    open override func settingIconName(index: Int) -> String {
        switch TSSettingsIndex.allCases[index] {
        case .displayMode: return "waveform.path.ecg"
        case .passthroughMode: return "hand.tap"
        case .keepInPlace: return "pin.fill"
        case .hideAtSnapshot: return "camera.viewfinder"
        case .singleLineMode: return "line.3.horizontal"
        case .usesInvertedColor: return "circle.lefthalf.filled"
        case .usesRotation: return "rotate.right"
        case .usesLargeFont: return "textformat.size"
        case .usesArrowPrefixes: return "arrow.up.arrow.down"
        case .usesBitrate: return "gauge"
        }
    }

    open override func settingTitle(index: Int, highlighted: Bool) -> String {
        return TSSettingsIndex.allCases[index].title
    }

    open override func settingSubtitle(index: Int, highlighted: Bool) -> String? {
        return TSSettingsIndex.allCases[index].subtitle(highlighted: highlighted, restartRequired: restartRequired)
    }

    private func settingKey(index: Int) -> String {
        return TSSettingsIndex.allCases[index].key
    }

    open override func settingHighlighted(index: Int) -> Bool {
        return delegate?.settingHighlighted(key: settingKey(index: index)) ?? false
    }

    private var isFPSMode: Bool {
        return delegate?.settingHighlighted(key: HUDUserDefaultsKeyDisplayMode) ?? false
    }

    open override func settingEnabled(index: Int) -> Bool {
        guard isFPSMode else { return true }
        let setting = TSSettingsIndex.allCases[index]
        switch setting {
        case .singleLineMode, .usesArrowPrefixes, .usesBitrate:
            return false
        default:
            return true
        }
    }

    open override func settingColorHighlighted(index: Int) -> UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 28/255.0, green: 74/255.0, blue: 82/255.0, alpha: 1.0)
            } else {
                return UIColor(red: 22/255.0, green: 160/255.0, blue: 133/255.0, alpha: 1.0)
            }
        }
    }

    open override func settingDidSelect(index: Int, completion: @escaping () -> ()) {
        if index == TSSettingsIndex.passthroughMode.rawValue && alreadyLaunched {
            restartRequired = true
        }
        delegate?.settingDidSelect(key: settingKey(index: index))
        UISelectionFeedbackGenerator().selectionChanged()
        completion()

        // When display mode is toggled, update enabled/disabled state of affected cells in-place
        if index == TSSettingsIndex.displayMode.rawValue {
            for cell in collectionView.visibleCells {
                if let settingCell = cell as? SPLarkSettingsCollectionViewCell,
                   let indexPath = collectionView.indexPath(for: settingCell) {
                    settingCell.setEnabled(settingEnabled(index: settingIndex(indexPath: indexPath)))
                }
            }
        }
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard let currentOrientation = view.window?.windowScene?.interfaceOrientation else {
            return [.portrait]
        }
        switch currentOrientation {
        case .unknown: fallthrough
        case .portrait:
            return [.portrait]
        case .portraitUpsideDown:
            return [.portraitUpsideDown]
        case .landscapeLeft:
            return [.landscapeLeft]
        case .landscapeRight:
            return [.landscapeRight]
        @unknown default:
            return [.portrait]
        }
    }

    open override var shouldAutorotate: Bool { false }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != self.traitCollection.userInterfaceStyle {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

//
// Copyright (c) 2023 - present, LLC “V Kontakte”
//
// 1. Permission is hereby granted to any person obtaining a copy of this Software to
// use the Software without charge.
//
// 2. Restrictions
// You may not modify, merge, publish, distribute, sublicense, and/or sell copies,
// create derivative works based upon the Software or any part thereof.
//
// 3. Termination
// This License is effective until terminated. LLC “V Kontakte” may terminate this
// License at any time without any negative consequences to our rights.
// You may terminate this License at any time by deleting the Software and all copies
// thereof. Upon termination of this license for any reason, you shall continue to be
// bound by the provisions of Section 2 above.
// Termination will be without prejudice to any rights LLC “V Kontakte” may have as
// a result of this agreement.
//
// 4. Disclaimer of warranty and liability
// THE SOFTWARE IS MADE AVAILABLE ON THE “AS IS” BASIS. LLC “V KONTAKTE” DISCLAIMS
// ALL WARRANTIES THAT THE SOFTWARE MAY BE SUITABLE OR UNSUITABLE FOR ANY SPECIFIC
// PURPOSES OF USE. LLC “V KONTAKTE” CAN NOT GUARANTEE AND DOES NOT PROMISE ANY
// SPECIFIC RESULTS OF USE OF THE SOFTWARE.
// UNDER NO CIRCUMSTANCES LLC “V KONTAKTE” BEAR LIABILITY TO THE LICENSEE OR ANY
// THIRD PARTIES FOR ANY DAMAGE IN CONNECTION WITH USE OF THE SOFTWARE.
//

import UIKit

struct DebugSettingsViewModel {
    var title: String
    var sections: [DebugSettingsSection]

    subscript(section: Int) -> DebugSettingsSection {
        precondition(
            section < self.sections.count,
            "Section index: \(section) is out of range. Section count: \(self.sections.count)"
        )
        return self.sections[section]
    }

    subscript(section: Int, cell: Int) -> DebugSettingsCellViewModel {
        let section = self[section]

        precondition(
            cell < section.cells.count,
            "Cell index: \(cell) is out of range. Cell count in section(\(section): \(section.cells.count)"
        )

        return section.cells[cell]
    }

    subscript(indexPath: IndexPath) -> DebugSettingsCellViewModel {
        self[indexPath.section, indexPath.row]
    }
}

struct DebugSettingsSection {
    var title: String
    var cells: [DebugSettingsCellViewModel]
}

protocol DebugSettingsCellViewModel {
    func configureCell(_ cell: UITableViewCell)
    var action: () -> Void { get set }
}

struct DebugSettingsCheckboxCellViewModel: DebugSettingsCellViewModel {
    var title: String
    var checked: Bool
    var action: () -> Void

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = self.title
        cell.accessoryView = nil
        cell.accessoryType = self.checked ? .checkmark : .none
    }
}

final class DebugSettingsToggleCellViewModel: DebugSettingsCellViewModel {
    var title: String
    var isOn: Bool
    var action: () -> Void

    lazy var toggle = {
        let toggle = UISwitch()
        toggle.addTarget(
            self,
            action: #selector(self.onToggle),
            for: .valueChanged
        )
        toggle.onTintColor = UIColor.azure
        return toggle
    }()

    init(title: String, isOn: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isOn = isOn
        self.action = action
    }

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = self.title
        cell.accessoryView = self.toggle
        self.toggle.isOn = self.isOn
    }

    @objc
    private func onToggle() {
        self.action()
    }
}

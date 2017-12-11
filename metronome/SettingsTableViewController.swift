//
//  SettingsTableViewController.swift
//  metronome
//
//  Created by Erika Ji on 12/11/17.
//  Copyright © 2017 Erika Ji. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    // MARK: Constants
    let headers = ["Metronome Tones", "About"]
    let tones = ["Logic", "Seiko", "Woodblock (High)", "Woodblock (Low)"]
    let aboutNames = ["Developer", "Fonts", "Icons", "Sounds"]
    let aboutValues = ["Erika Ji", "Open Sans, Varela Round", "Icons8", "Freesounds, Logic, Seiko"]
    
    // MARK: Core
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = 45 // gets rid of error
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Functions
    override func numberOfSections(in tableView: UITableView) -> Int {
        return headers.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return tones.count
        case 1:
            return aboutNames.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SettingsTonesTableViewCell
            cell.tonesLabel.text = tones[indexPath.row]
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            // accurately mark current setting as checked
            let currentToneIndex = UserDefaults.standard.integer(forKey: "tone")
            if indexPath.row == currentToneIndex {
                cell.accessoryType = .checkmark
            }

            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "aboutcell", for: indexPath) as! SettingsAboutTableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.none

            cell.aboutNameLabel.text = aboutNames[indexPath.row]
            cell.aboutValueLabel.text = aboutValues[indexPath.row]
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headers[section]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            // uncheck other rows
            for cell in self.tableView.visibleCells {
                cell.accessoryType = .none
            }
            
            // check the new row
            if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
                UserDefaults.standard.set (indexPath.row, forKey: "tone")
                cell.accessoryType = .checkmark
            }
        case 1:
            // keep real row selection marked
            let currentToneIndex = UserDefaults.standard.integer(forKey: "tone")
            let cell = tableView.cellForRow(at: IndexPath(item: currentToneIndex, section: 0))
            cell?.accessoryType = .checkmark
            break
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            // deselect rows other than the row for the setting
            if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
                cell.accessoryType = .none
            }
        case 1:
            break
        default:
            break
        }
    }

}

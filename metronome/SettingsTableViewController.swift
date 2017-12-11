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
    let sounds = ["Logic", "Seiko", "Woodblock (High)", "Woodblock (Low)"]
    let about = ["Developer", "Fonts", "Icons", "Sounds"]
    let currentSoundIndex = 3
    
    // MARK: Core
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "aboutcell")
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
            return sounds.count
        case 1:
            return about.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = sounds[indexPath.row]
            if indexPath.row == currentSoundIndex {
                cell.accessoryType = .checkmark
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "aboutcell", for: indexPath)
            cell.textLabel?.text = about[indexPath.row]
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let selectedIndexPaths = indexPathsForSelectedRowsInSection(indexPath.section)
        if selectedIndexPaths?.count == 1 {
            tableView.deselectRowAtIndexPath(selectedIndexPaths!.first!, animated: true)
        }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
                cell.accessoryType = .checkmark
            }
            
        case 1:
            break
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
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

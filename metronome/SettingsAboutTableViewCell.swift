//
//  SettingsAboutTableViewCell.swift
//  metronome
//
//  Created by Erika Ji on 12/11/17.
//  Copyright © 2017 Erika Ji. All rights reserved.
//

import UIKit

class SettingsAboutTableViewCell: UITableViewCell {

    @IBOutlet weak var aboutNameLabel: UILabel!
    @IBOutlet weak var aboutValueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

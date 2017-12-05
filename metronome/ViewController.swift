//
//  ViewController.swift
//  metronome
//
//  Created by Erika Ji on 12/4/17.
//  Copyright © 2017 Erika Ji. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITextFieldDelegate {
    // MARK: Properties
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var playPause: UIButton!
    @IBOutlet weak var knobPlaceholder: UIView!
    
    var metronomeOn = 0
    var tempo = 90
    var knob: Knob!
    var player: AVAudioPlayer?
    var beatTimer = Timer()
    
    
    
    // MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup
        setupTempoLabel()
        setupKnob()
        view.tintColor = UIColor.red
        view.bringSubview(toFront: playPause)

        // Ongoing
        updateLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: setupTempoLabel
    func setupTempoLabel() {
        tempoLabel.text = String(tempo)
        tempoLabel.font = UIFont(name: "OpenSans", size: 144.0)
    }
    
    // MARK: setupKnob
    func setupKnob() {
        knob = Knob(frame: knobPlaceholder.bounds)
        knob.minimumValue = 40
        knob.maximumValue = 208
        knob.value = Float(tempo)

        knob.lineWidth = 4.0
        knob.pointerLength = 12.0
        knob.addTarget(self, action: #selector(self.knobValueChanged), for: .valueChanged)
        knobPlaceholder.addSubview(knob)
    }

    // MARK: updateLabel
    @objc func updateLabel() {
        tempoLabel.text = NumberFormatter.localizedString(from: NSNumber(value: tempo), number: NumberFormatter.Style.none)
    }
    
    // MARK: UITextFieldDelegate
    /* func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        tempoLabel.text = textField.text
    } */
    
    
    
    // MARK: playSound
    @objc func playSound() {
        //  Metronome sound courtesy of Freesound.org
        guard let url = Bundle.main.url(forResource: "Woodblock", withExtension: "wav") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }

    // MARK: setTimeInterval
    func getTimeInterval(tempo: String) -> Double {
        let bpm = Int(tempo)!
        let timeInterval:Double=(60.0/Double(bpm))
        // Debug: print("Tempo:", tempo, " BPM:", bpm, " Interval:", timeInterval)
        return timeInterval
    }
    
    // MARK: knobValueChanged
    @objc func knobValueChanged(knob: Knob) {
        tempo = Int(knob.value)
        updateLabel()
    }


    
    // MARK: Actions
    @IBAction func playPauseButton(_ sender: UIButton) {
        if metronomeOn == 0 {
            metronomeOn = 1
            sender.setImage(UIImage(named:"Pause_White"),for: .normal)
            // Play sound once upon pressing the button, then rely on the timer
            playSound()
            let timeIntervalDouble = getTimeInterval(tempo: tempoLabel.text!)
            beatTimer = Timer.scheduledTimer(timeInterval: timeIntervalDouble, target: self, selector: #selector(self.playSound), userInfo: nil, repeats: true)
        } else {
            metronomeOn = 0
            sender.setImage(UIImage(named:"Play_White"),for: .normal)
            beatTimer.invalidate()
        }
    }
}


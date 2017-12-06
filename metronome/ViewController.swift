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
    // MARK: Constants
    let tempoValues = [40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60, 63, 66, 69, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116, 120, 126, 132, 138, 144, 152, 160, 168, 176, 184, 192, 200, 208]

    let tempoNames = ["Largo": [40, 42, 44, 46, 48, 50, 52, 54, 56, 58],
                      "Larghetto": [60, 63],
                      "Adagio": [66, 69, 72],
                      "Andante": [76, 80, 84, 88, 92, 96, 100, 104],
                      "Moderato": [108, 112, 116],
                      "Allegro": [120, 126, 132, 138, 144, 152, 160, 168],
                      "Presto": [176, 184, 192, 200],
                      "Prestissimo": [208]]

    enum TempoConstants {
        static let minimumTempo = 40
        static let maximumTempo = 208
        static let startingTempo = 92
    }
    
    
    
    // MARK: Properties
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var tempoNameLabel: UILabel!
    @IBOutlet weak var playPause: UIButton!
    @IBOutlet weak var knobPlaceholder: UIView!
    
    var knob: Knob!
    var player: AVAudioPlayer?
    var beatTimer = Timer()
    var metronomeOn = 0 // metronome starts out off
    var tempo = TempoConstants.startingTempo
    

    
    // MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup
        setupTempoLabels()
        setupKnob()
        view.tintColor = UIColor.red
        view.bringSubview(toFront: playPause)
        updateLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: setupTempoLabel
    func setupTempoLabels() {
        tempoLabel.text = String(tempo)
        tempoLabel.font = UIFont(name: "OpenSans", size: 144.0)
        tempoNameLabel.text = getTempoName(tempo: tempo)
        tempoNameLabel.font = UIFont(name: "OpenSans", size: 30.0)
    }
    
    // MARK: getTempoName
    func getTempoName(tempo: Int) -> String {
        for (name, tempoArray) in tempoNames {
            if tempoArray.contains(tempo) {
                return name
            }
        }
        return ""
    }
    
    // MARK: setupKnob
    func setupKnob() {
        knob = Knob(frame: knobPlaceholder.bounds)
        knob.minimumValue = Float(TempoConstants.minimumTempo)
        knob.maximumValue = Float(TempoConstants.maximumTempo)
        knob.startAngle = -CGFloat(CGFloat.pi * 7.0 / 5.0);
        knob.endAngle = CGFloat(CGFloat.pi * 2.0 / 5.0);
        knob.value = Float(tempo)

        knob.lineWidth = 8.0
        knob.pointerLength = 32.0
        knob.addTarget(self, action: #selector(self.knobValueChanged), for: .valueChanged)
        knobPlaceholder.addSubview(knob)
    }

    // MARK: updateLabel
    @objc func updateLabel() {
        var newTempo = getClosestTempo(inputTempo: tempo)
        tempoLabel.text = NumberFormatter.localizedString(from: NSNumber(value: newTempo), number: NumberFormatter.Style.none)
        tempoNameLabel.text = getTempoName(tempo: newTempo)
    }
    
    // MARK: getClosestTempo
    func getClosestTempo(inputTempo: Int) -> Int {
        var closestTempo = inputTempo
        if tempoValues.contains(inputTempo) {
            return closestTempo
        } else {
            closestTempo = tempoValues.first!
            for item in tempoValues {
                if (abs(inputTempo - item) <= abs(inputTempo - closestTempo)) {
                    closestTempo = item
                }
            }
        }
        return closestTempo
    }
    
    
    
    // MARK: knobValueChanged
    @objc func knobValueChanged(knob: Knob) {
        tempo = Int(knob.value)
        updateLabel()
        if metronomeOn == 1 {
            updateBeat()
        }
    }

    // MARK: updateBeat
    func updateBeat() {
        beatTimer.invalidate()
        let timeIntervalDouble = getTimeInterval(tempo: tempoLabel.text!)
        beatTimer = Timer.scheduledTimer(timeInterval: timeIntervalDouble, target: self, selector: #selector(self.playSound), userInfo: nil, repeats: true)
    }

    // MARK: getTimeInterval
    func getTimeInterval(tempo: String) -> Double {
        let bpm = Int(tempo)!
        let timeInterval: Double = 60.0 / Double(bpm)
        // Debug: print("Tempo:", tempo, " BPM:", bpm, " Interval:", timeInterval)
        return timeInterval
    }
    
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
    
    
    
    // MARK: Actions
    @IBAction func playPauseButton(_ sender: UIButton) {
        if metronomeOn == 0 {
            metronomeOn = 1
            sender.setImage(UIImage(named:"Pause_White"),for: .normal)
            playSound() // Play first sound before changing to use the timer
            updateBeat()
        } else {
            metronomeOn = 0
            sender.setImage(UIImage(named:"Play_White"),for: .normal)
            beatTimer.invalidate()
        }
    }
}

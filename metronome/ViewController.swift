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
        static let minimumTempoIndex = 0 // 40
        static let startingTempoIndex = 19 // 92
        static let maximumTempoIndex = 38 // 208
    }
    
    enum VisualConstants {
        static let startAngle = -CGFloat(CGFloat.pi * 7.0 / 5.0)
        static let endAngle = CGFloat(CGFloat.pi * 2.0 / 5.0)
        static let lineWidth = 8.0
        static let pointerLength = 32.0
    }
    
    
    
    // MARK: Properties
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var tempoNameLabel: UILabel!
    @IBOutlet weak var knobPlaceholder: UIView!
    @IBOutlet weak var playPause: UIButton!
    
    var knob: Knob!
    var player: AVAudioPlayer?
    var beatTimer = Timer()
    var metronomeOn = 0
    var currentTempoIndex = TempoConstants.startingTempoIndex
    

    
    // MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup
        setupTempoLabels()
        setupKnob()
        view.tintColor = UIColor.red
        view.bringSubview(toFront: playPause)
        updateLabel(tempoIndex: currentTempoIndex)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: setupTempoLabels
    func setupTempoLabels() {
        let currentTempo = tempoValues[currentTempoIndex]
        tempoLabel.text = String(currentTempo)
        tempoLabel.font = UIFont(name: "OpenSans", size: 144.0)
        tempoNameLabel.text = getTempoName(tempo: currentTempo)
        tempoNameLabel.font = UIFont(name: "OpenSans", size: 30.0)
    }
    
    // MARK: getTempoName
    func getTempoName(tempo: Int) -> String {
        for (name, tempoArray) in tempoNames {
            if tempoArray.contains(tempo) {
                return name
            }
        }
        return "" // if this function fails, return empty string
    }
    
    
    
    // MARK: setupKnob
    func setupKnob() {
        knob = Knob(frame: knobPlaceholder.bounds)
        knob.minimumValue = Float(TempoConstants.minimumTempoIndex)
        knob.maximumValue = Float(TempoConstants.maximumTempoIndex)
        knob.value = Float(currentTempoIndex)

        knob.startAngle = VisualConstants.startAngle
        knob.endAngle = VisualConstants.endAngle
        knob.lineWidth = CGFloat(VisualConstants.lineWidth)
        knob.pointerLength = CGFloat(VisualConstants.pointerLength)
        knob.addTarget(self, action: #selector(self.knobValueChanged), for: .valueChanged)
        knobPlaceholder.addSubview(knob)
    }
    
    
    
    // MARK: knobValueChanged
    @objc func knobValueChanged(inputKnob: Knob) {
        currentTempoIndex = Int(round(inputKnob.value))
        if currentTempoIndex > TempoConstants.maximumTempoIndex {
            currentTempoIndex = TempoConstants.maximumTempoIndex
        }
        let currentTempo = tempoValues[currentTempoIndex]
        updateLabel(tempoIndex: currentTempoIndex)
        if metronomeOn == 1 {
            updateBeat(tempo: currentTempo)
        }
        // code below makes the pointer snap into place
        knob.setValue(value: Float(currentTempoIndex), animated: false)
    }


    
    // MARK: updateLabel
    @objc func updateLabel(tempoIndex: Int) {
        let tempo = tempoValues[tempoIndex]
        tempoLabel.text = NumberFormatter.localizedString(from: NSNumber(value: tempo), number: NumberFormatter.Style.none)
        tempoNameLabel.text = getTempoName(tempo: tempo)
    }

    

    // MARK: updateBeat
    func updateBeat(tempo: Int) {
        beatTimer.invalidate()
        let timeInterval: Double = 60.0 / Double(tempo)
        beatTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.playSound), userInfo: nil, repeats: true)
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
            let currentTempo = tempoValues[currentTempoIndex]
            updateBeat(tempo: currentTempo)
        } else {
            metronomeOn = 0
            sender.setImage(UIImage(named:"Play_White"),for: .normal)
            beatTimer.invalidate()
        }
    }
}

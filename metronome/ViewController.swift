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
    let tempoValues = [40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60, 63, 66, 69, 72,
                       76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116, 120, 126,
                       132, 138, 144, 152, 160, 168, 176, 184, 192, 200, 208]
    
    let tempoNames = ["Largo": [40, 42, 44, 46, 48, 50, 52, 54, 56, 58],
                      "Larghetto": [60, 63],
                      "Adagio": [66, 69, 72],
                      "Andante": [76, 80, 84, 88, 92, 96, 100, 104],
                      "Moderato": [108, 112, 116],
                      "Allegro": [120, 126, 132, 138, 144, 152, 160, 168],
                      "Presto": [176, 184, 192, 200],
                      "Prestissimo": [208]]

    enum TempoConstants {
        static let minimumTempoIndex = 0    // bpm =  40
        static let startingTempoIndex = 19  // bpm =  92
        static let maximumTempoIndex = 38   // bpm = 208
    }
    
    enum VisualConstants {
        static let startAngle = -CGFloat(CGFloat.pi * 6.0 / 5.0)
        static let endAngle = CGFloat(CGFloat.pi * 1.0 / 5.0)
        static let lineWidth = 18.0
        static let lineColor = UIColor(red: 0, green: 0.42, blue: 0.7, alpha: 1.0) // #006bb3
        
        static let circularPointer = true
        static let pointerRadius = lineWidth / 2.0 - 2.0
        
        static let pendulumColor = UIColor.darkGray.cgColor
        static let pendulumBobColor = UIColor.white.cgColor
    }
    
    enum ToneConstants {
        static let toneNames = ["Logic", "Seiko", "Woodblock (High)", "Woodblock (Low)"]
        static let startingToneIndex = 3 // start with Woodblock (Low)
    }
    
    
    
    // MARK: Variables
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var tempoNameLabel: UILabel!
    @IBOutlet weak var knobPlaceholder: UIView!
    @IBOutlet weak var pendulumPlaceholder: UIView!
    @IBOutlet weak var playPause: UIButton!
    
    // Knob
    var knob: Knob!

    // Pendulum
    var pendulumTrackLayer = CAShapeLayer()
    var pendulumBobLayer = CAShapeLayer()
    
    // Player
    var player: AVAudioPlayer?
    var beatTimer = RepeatingTimer()
    
    // Status
    var metronomeOn = false
    var currentTempoIndex = TempoConstants.startingTempoIndex
    var currentToneIndex = ToneConstants.startingToneIndex
    
    

    // MARK: Core
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI elements
        setupTempoLabels()
        setupKnob()
        setupPendulum()
        UserDefaults.standard.set(currentToneIndex, forKey: "tone")
        
        // Allow the settings page to trigger beat changes
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateBeat), name:NSNotification.Name(rawValue: "updateBeatNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playOneSound), name:NSNotification.Name(rawValue: "playOneSoundNotification"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar for this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: setupTempoLabels
    func setupTempoLabels() {
        tempoLabel.font = UIFont(name: "OpenSans", size: 144.0)
        tempoNameLabel.font = UIFont(name: "OpenSans", size: 30.0)
        updateLabel(tempoIndex: currentTempoIndex)
    }
    
    // MARK: updateLabel
    func updateLabel(tempoIndex: Int) {
        let tempo = tempoValues[tempoIndex]
        tempoLabel.text = NumberFormatter.localizedString(from: NSNumber(value: tempo), number: NumberFormatter.Style.none)
        tempoNameLabel.text = getTempoName(tempo: tempo)
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
        // Setup track
        knob = Knob(frame: knobPlaceholder.bounds)
        knob.minimumValue = Float(TempoConstants.minimumTempoIndex)
        knob.maximumValue = Float(TempoConstants.maximumTempoIndex)
        knob.startAngle = VisualConstants.startAngle
        knob.endAngle = VisualConstants.endAngle
        knob.lineWidth = CGFloat(VisualConstants.lineWidth)
        
        // Setup pointer
        knob.value = Float(currentTempoIndex) // note: needs to be determined before angles are set
        knob.circularPointer = VisualConstants.circularPointer
        knob.pointerRadius = CGFloat(VisualConstants.pointerRadius)
        
        knob.addTarget(self, action: #selector(self.knobValueChanged), for: .valueChanged)
        knobPlaceholder.addSubview(knob)
        view.tintColor = VisualConstants.lineColor
        view.bringSubview(toFront: playPause)
    }

    // MARK: setupPendulum
    func setupPendulum() {
        // Setup track
        pendulumTrackLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: pendulumPlaceholder.bounds.maxX, height: CGFloat(VisualConstants.lineWidth)), cornerRadius: 25).cgPath
        pendulumTrackLayer.fillColor = VisualConstants.pendulumColor
        pendulumPlaceholder.layer.addSublayer(pendulumTrackLayer)
        
        // Setup bob
        let pendulumBobRect = CGRect(x: 2.0, y: 2.0, width: VisualConstants.pointerRadius * 2.0, height: VisualConstants.pointerRadius * 2.0)
        pendulumBobLayer.path = UIBezierPath(ovalIn: pendulumBobRect).cgPath
        pendulumBobLayer.fillColor = VisualConstants.pendulumBobColor
        pendulumPlaceholder.layer.addSublayer(pendulumBobLayer)
    }
    
    
    
    // MARK: knobValueChanged
    @objc func knobValueChanged(inputKnob: Knob) {
        let newTempoIndex = Int(round(inputKnob.value))
        if currentTempoIndex != newTempoIndex { // only make changes when truly needed
            currentTempoIndex = newTempoIndex
            updateLabel(tempoIndex: currentTempoIndex)
            if metronomeOn == true {
                updateBeat()
                updatePendulum()
            }
            knob.value = Float(currentTempoIndex)
        }
    }

    
    
    // MARK: updateBeat
    @objc func updateBeat() {
        beatTimer.suspend()
        currentToneIndex = UserDefaults.standard.integer(forKey: "tone") // update tone
    
        let currentTempo = tempoValues[currentTempoIndex]
        // 60 seconds/min * 1 min/(n beats) * 1,000 milliseconds/second = # milliseconds/beat
        let timeInterval: Int = Int(60.0 / Double(currentTempo) * 1000.0)
            
        beatTimer.timer.schedule(deadline: .now(), repeating: .milliseconds(timeInterval))
        beatTimer.timer.setEventHandler(handler: { [weak self] in
                self?.playSound()
            })
        beatTimer.resume()
    }
    
    // MARK: playOneSound
    @objc func playOneSound() {
        beatTimer.suspend()
        currentToneIndex = UserDefaults.standard.integer(forKey: "tone") // update tone
        playSound()
    }
    
    // MARK: playSound
    @objc func playSound() {
        let currentToneName = ToneConstants.toneNames[currentToneIndex]
        guard let url = Bundle.main.url(forResource: currentToneName, withExtension: "wav") else { return }
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
    
    
    
    // MARK: updatePendulum
    func updatePendulum() {
        let endX = pendulumPlaceholder.bounds.maxX - CGFloat(2.0 * VisualConstants.pointerRadius) - 2
        let currentTempo = tempoValues[currentTempoIndex]
        let timeInterval: Double = 60.0 / Double(currentTempo) // 60 seconds/min * 1 min/(n beats) = # seconds/beat
        
        let moveToRight = CABasicAnimation(keyPath: "position")
        moveToRight.fromValue = [0, 0]
        moveToRight.toValue = [endX, 0]
        moveToRight.duration = timeInterval
        moveToRight.beginTime = 0
        
        let moveToLeft = CABasicAnimation(keyPath: "position")
        moveToLeft.fromValue = [endX, 0]
        moveToLeft.toValue = [0, 0]
        moveToLeft.duration = timeInterval
        moveToLeft.beginTime = moveToRight.duration

        let backAndForth = CAAnimationGroup()
        backAndForth.animations = [moveToRight, moveToLeft]
        backAndForth.duration = moveToRight.duration + moveToLeft.duration
        backAndForth.repeatCount = Float.infinity
        backAndForth.isRemovedOnCompletion = false
        
        pendulumBobLayer.add(backAndForth, forKey: "backAndForth")
    }
    
    // MARK: pausePendulum
    func pausePendulum() {
        let pausedTime = pendulumBobLayer.convertTime(CACurrentMediaTime(), from: nil)
        pendulumBobLayer.speed = 0.0
        pendulumBobLayer.timeOffset = pausedTime
    }
    
    // MARK: restartPendulum
    func restartPendulum() {
        pendulumBobLayer.speed = 1.0
    }
    
    
    
    // MARK: Actions
    @IBAction func playPauseButton(_ sender: UIButton) {
        if metronomeOn == false {
            metronomeOn = true
            sender.setImage(UIImage(named:"Pause_White"),for: .normal)
            updateBeat()
            updatePendulum()
            restartPendulum()
        } else {
            metronomeOn = false
            sender.setImage(UIImage(named:"Play_White"),for: .normal)
            beatTimer.suspend()
            pausePendulum()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? SettingsTableViewController {
            destinationViewController.metronomeOn = metronomeOn
        }
    }
}

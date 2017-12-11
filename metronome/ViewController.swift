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
        static let startAngle = -CGFloat(CGFloat.pi * 6.0 / 5.0)
        static let endAngle = CGFloat(CGFloat.pi * 1.0 / 5.0)
        static let lineWidth = 18.0
        static let lineColor = UIColor(red: 0, green: 0.42, blue: 0.7, alpha: 1.0) // #006bb3
        static let circularPointer = true
        static let pointerRadius = lineWidth / 2.0 - 2.0
    }
    
    
    
    // MARK: Properties
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var tempoNameLabel: UILabel!
    @IBOutlet weak var knobPlaceholder: UIView!
    @IBOutlet weak var pendulumPlaceholder: UIView!
    @IBOutlet weak var playPause: UIButton!
    @IBOutlet weak var settings: UIButton!
    
    // Knob
    var knob: Knob!

    // Pendulum
    var pendulumTrackLayer = CAShapeLayer()
    var pendulumBobLayer = CAShapeLayer()
    
    // Player
    var player: AVAudioPlayer?
    var beatTimer = Timer()

    // Initialize
    var metronomeOn = 0
    var currentTempoIndex = TempoConstants.startingTempoIndex
    var soundName = "Woodblock (Low)"
    
    

    // MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        // Setup
        setupTempoLabels()
        setupKnob()
        setupPendulum()
        view.tintColor = VisualConstants.lineColor
        view.bringSubview(toFront: playPause)
        updateLabel(tempoIndex: currentTempoIndex)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
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
        knob.circularPointer = VisualConstants.circularPointer
        knob.pointerRadius = CGFloat(VisualConstants.pointerRadius)
        knob.addTarget(self, action: #selector(self.knobValueChanged), for: .valueChanged)
        knobPlaceholder.addSubview(knob)
    }
    
    
    
    // MARK: setupPendulum
    func setupPendulum() {
        pendulumTrackLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: pendulumPlaceholder.bounds.maxX, height: CGFloat(VisualConstants.lineWidth)), cornerRadius: 25).cgPath
        pendulumTrackLayer.fillColor = VisualConstants.lineColor.cgColor
        pendulumPlaceholder.layer.addSublayer(pendulumTrackLayer)
        
        let pendulumBobRect = CGRect(x: 2.0, y: 2.0, width: VisualConstants.pointerRadius * 2.0, height: VisualConstants.pointerRadius * 2.0)
        pendulumBobLayer.path = UIBezierPath(ovalIn: pendulumBobRect).cgPath
        pendulumBobLayer.fillColor = UIColor.white.cgColor
        pendulumPlaceholder.layer.addSublayer(pendulumBobLayer)
    }
    
    
    
    // MARK: knobValueChanged
    @objc func knobValueChanged(inputKnob: Knob) {
        let newTempoIndex = Int(round(inputKnob.value))
        if currentTempoIndex != newTempoIndex { // only make changes when truly needed
            currentTempoIndex = newTempoIndex
            let currentTempo = tempoValues[currentTempoIndex]
            updateLabel(tempoIndex: currentTempoIndex)
            if metronomeOn == 1 {
                updateBeat(tempo: currentTempo)
                updatePendulum(tempo: currentTempo)
            }
            knob.value = Float(currentTempoIndex)
        }
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
        playSound()
        let timeInterval: Double = 60.0 / Double(tempo) // 60 sec/min * 1 min/tempo beats = # secs/beat
        beatTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.playSound), userInfo: nil, repeats: true)
    }
    
    // MARK: playSound
    @objc func playSound() {
        //  Metronome sound courtesy of Freesound.org
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") else { return }
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
    func updatePendulum(tempo: Int) {
        // Definitions
        let endX = pendulumPlaceholder.bounds.maxX - CGFloat(2.0 * VisualConstants.pointerRadius) - 2
        let timeInterval: Double = 60.0 / Double(tempo) // 60 sec/min * 1 min/tempo beats = # secs/beat
        
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
        if metronomeOn == 0 {
            metronomeOn = 1
            sender.setImage(UIImage(named:"Pause_White"),for: .normal)
            let currentTempo = tempoValues[currentTempoIndex]
            updateBeat(tempo: currentTempo)
            updatePendulum(tempo: currentTempo)
            restartPendulum()
        } else {
            metronomeOn = 0
            sender.setImage(UIImage(named:"Play_White"),for: .normal)
            beatTimer.invalidate()
            pausePendulum()
        }
    }
    
    @IBAction func settingsButton(_ sender: Any) {
    }
    @IBAction func exitSettings(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

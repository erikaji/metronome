//
//  ViewController.swift
//  metronome
//
//  Created by Erika Ji on 12/4/17.
//  Copyright © 2017 Erika Ji. All rights reserved.
//

import UIKit
import AudioKit
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
    // UI Outlets
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
    
    // Metronome, courtesy of AudioKit
    var metronome = AKSamplerMetronome()
    var mixer = AKMixer()
    
    var sequencer = AKSequencer()
    var sampler = AKMIDISampler()
    var callbackInst = AKCallbackInstrument()
    
    // Status
    var metronomeOn = false
    var currentTempoIndex = TempoConstants.startingTempoIndex
    var currentToneIndex = ToneConstants.startingToneIndex
    
    
    
    // MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI elements
        setupTempoLabels()
        setupKnob()
        setupPendulum()
        UserDefaults.standard.set(currentToneIndex, forKey: "tone")
        
        // Setup Metronome
        setupMetronome()
        
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
    }
    
    
    
    // MARK: Tempo Labels
    // setupTempoLabels
    func setupTempoLabels() {
        tempoLabel.font = UIFont(name: "OpenSans", size: 144.0)
        tempoNameLabel.font = UIFont(name: "OpenSans", size: 30.0)
        updateLabel(tempoIndex: currentTempoIndex)
    }
    
    // updateLabel
    func updateLabel(tempoIndex: Int) {
        let tempo = tempoValues[tempoIndex]
        tempoLabel.text = NumberFormatter.localizedString(from: NSNumber(value: tempo), number: NumberFormatter.Style.none)
        tempoNameLabel.text = getTempoName(tempo: tempo)
    }
    
    // getTempoName
    func getTempoName(tempo: Int) -> String {
        for (name, tempoArray) in tempoNames {
            if tempoArray.contains(tempo) { return name }
        }
        return "" // if this function fails, return empty string
    }
    
    
    
    // MARK: Knob & Pendulum
    // setupKnob
    func setupKnob() {
        // Setup track
        knob = Knob(frame: knobPlaceholder.bounds)
        knob.minimumValue = Float(TempoConstants.minimumTempoIndex)
        knob.maximumValue = Float(TempoConstants.maximumTempoIndex)
        knob.startAngle = VisualConstants.startAngle
        knob.endAngle = VisualConstants.endAngle
        knob.lineWidth = CGFloat(VisualConstants.lineWidth)
        
        // Setup knob pointer
        knob.value = Float(currentTempoIndex) // note: needs to be determined before angles are set
        knob.circularPointer = VisualConstants.circularPointer
        knob.pointerRadius = CGFloat(VisualConstants.pointerRadius)
        
        knob.addTarget(self, action: #selector(self.knobValueChanged), for: .valueChanged)
        knobPlaceholder.addSubview(knob)
        view.tintColor = VisualConstants.lineColor
        view.bringSubview(toFront: playPause)
    }
    
    // setupPendulum
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
    
    // knobValueChanged
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
    
    
    
    // MARK: Metronome
    // setupMetronome
    func setupMetronome() {
        // Specify metronome tone
        let currentToneName = ToneConstants.toneNames[currentToneIndex]
        do { try sampler.loadWav(currentToneName)
        } catch { print("Error: could not load initial metronome tone.") }
        
        // Start AudioKit
        AudioKit.output = sampler
        do { try AudioKit.start()
        } catch { AKLog("AudioKit did not start!") }
        
        // Enable background playback
        do { try AKSettings.setSession(category: .playback, with: .mixWithOthers)
            AKSettings.playbackWhileMuted = true
        } catch { print("Error: could not enable background mode.") }
        
        // Create two tracks for the sequencer
        let metronomeTrack = sequencer.newTrack()
        metronomeTrack?.setMIDIOutput(sampler.midiIn)
        let callbackTrack = sequencer.newTrack()
        callbackTrack?.setMIDIOutput(callbackInst.midiIn)
        
        // Create the MIDI data
        for i in 0 ..< 2 {
            // This will trigger the sampler on the two down beats
            metronomeTrack?.add(noteNumber: 60, velocity: 127, position: AKDuration(beats: Double(i)), duration: AKDuration(beats: 1))
            // Set the midiNote number to the current beat number; use this in the callback
            callbackTrack?.add(noteNumber: MIDINoteNumber(i), velocity: 127, position: AKDuration(beats: Double(i)), duration: AKDuration(beats: 1))
        }
        
        // Set the callback
        callbackInst.callback = {status, noteNumber, velocity in
            guard status == .noteOn else { return }
            self.movePendulum(noteNumber: Int(noteNumber))
        }
        
        // Prepare the sequencer
        sequencer.enableLooping(AKDuration(beats: 2))
    }
    
    
    
    // MARK: Beat
    // updateBeat
    @objc func updateBeat() {
        sequencer.stop()
        // Change tone
        currentToneIndex = UserDefaults.standard.integer(forKey: "tone") // update tone
        let currentToneName = ToneConstants.toneNames[currentToneIndex]
       /* guard let toneUrl = Bundle.main.url(forResource: currentToneName, withExtension: "caf")
            else { fatalError("The metronome tone specified is invalid.") }
        metronome.sound = toneUrl*/
        
        do { try sampler.loadWav(currentToneName)
        } catch { print("Error: could not load initial metronome tone.") }
        
        // Change tempo
        let currentTempo = Double(tempoValues[currentTempoIndex])
        /*let now = AVAudioTime(hostTime: mach_absolute_time())
        metronome.setTempo(currentTempo, at: now)*/
        sequencer.setTempo(currentTempo)
        
        sequencer.play()
    }
    
    // playOneSound
    @objc func playOneSound() {
        currentToneIndex = UserDefaults.standard.integer(forKey: "tone") // update tone
        let currentToneName = ToneConstants.toneNames[currentToneIndex]
        do {
            let toneFile = try AKAudioFile(readFileName: currentToneName + ".caf")
            let player = try AKAudioPlayer(file: toneFile)
            player.volume = 0.75
            AudioKit.output=player
            player.play()
        } catch let error { print(error.localizedDescription) }
    }
    
    
    
    // MARK: Pendulum
    // movePendulum
    func movePendulum(noteNumber: Int) {
        print("hello. moving pendulum")
        DispatchQueue.main.async {
            print(self.pendulumPlaceholder.bounds.maxX)
            let startX = 0
            let endX = self.pendulumPlaceholder.bounds.maxX - CGFloat(2.0 * VisualConstants.pointerRadius) - 2
            let timeInterval: Double = 60.0 / Double(self.sequencer.tempo)
            // 60 seconds/min * 1 min/(n beats) = # seconds/beat
            
            let move = CABasicAnimation(keyPath: "position")
            move.duration = timeInterval
            move.beginTime = 0
            move.isRemovedOnCompletion = false
            move.fillMode = kCAFillModeForwards
            
            /* var pendulumNumber: Int
            if self.sequencer.currentRelativePosition.beats < 1 {
                pendulumNumber = 0
            } else {
                pendulumNumber = 1
            } */
            
            print("sequencer no: \(noteNumber)")

            if noteNumber == 0 {
                move.fromValue = [startX, 0]
                move.toValue = [endX, 0]
            } else {
                move.fromValue = [endX, 0]
                move.toValue = [startX, 0]
            }
            print("mid1")
            self.pendulumBobLayer.add(move, forKey: "move")
            print("mid2")
            if noteNumber == 0 {
                // self.pendulumBobLayer.position = CGPoint(x: endX, y: 0)
            } else {
                // self.pendulumBobLayer.position = CGPoint(x: startX, y: 0)
            }
            print("end animation")
            
            /*
            let moveToRight = CABasicAnimation(keyPath: "position")
            moveToRight.fromValue = [startX, 0]
            moveToRight.toValue = [endX, 0]
            moveToRight.duration = timeInterval
            moveToRight.beginTime = 0
            
            let moveToLeft = CABasicAnimation(keyPath: "position")
            moveToLeft.fromValue = [endX, 0]
            moveToLeft.toValue = [startX, 0]
            moveToLeft.duration = timeInterval
            moveToLeft.beginTime = moveToRight.duration
            
            let backAndForth = CAAnimationGroup()
            backAndForth.animations = [moveToRight, moveToLeft]
            backAndForth.duration = moveToRight.duration + moveToLeft.duration
            backAndForth.repeatCount = Float.infinity
            backAndForth.isRemovedOnCompletion = false
            
            self.pendulumBobLayer.add(backAndForth, forKey: "backAndForth")
 */
            
        }
    }
    
    // updatePendulum
    func updatePendulum() {
        /*let startX = 0
        let endX = pendulumPlaceholder.bounds.maxX - CGFloat(2.0 * VisualConstants.pointerRadius) - 2
        let timeInterval: Double = 60.0 / Double(metronome.tempo)
        // 60 seconds/min * 1 min/(n beats) = # seconds/beat
        
        let moveToRight = CABasicAnimation(keyPath: "position")
        moveToRight.fromValue = [startX, 0]
        moveToRight.toValue = [endX, 0]
        moveToRight.duration = timeInterval
        moveToRight.beginTime = 0
        
        let moveToLeft = CABasicAnimation(keyPath: "position")
        moveToLeft.fromValue = [endX, 0]
        moveToLeft.toValue = [startX, 0]
        moveToLeft.duration = timeInterval
        moveToLeft.beginTime = moveToRight.duration
        
        let backAndForth = CAAnimationGroup()
        backAndForth.animations = [moveToRight, moveToLeft]
        backAndForth.duration = moveToRight.duration + moveToLeft.duration
        backAndForth.repeatCount = Float.infinity
        backAndForth.isRemovedOnCompletion = false
        
        pendulumBobLayer.add(backAndForth, forKey: "backAndForth")*/
    }
    
    // pausePendulum
    func pausePendulum() {
        /* let pausedTime = pendulumBobLayer.convertTime(CACurrentMediaTime(), from: nil)
        pendulumBobLayer.speed = 0.0
        pendulumBobLayer.timeOffset = pausedTime */
    }
    
    // restartPendulum
    func restartPendulum() {
       /* CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        pendulumBobLayer.position = CGPoint(x: 0, y: 0)
        CATransaction.commit()
        print("done")
        pendulumBobLayer.speed = 1.0 */
    }
    
    
    
    // MARK: Actions
    @IBAction func playPauseButton(_ sender: UIButton) {
        if metronomeOn == false {
            metronomeOn = true
            sender.setImage(UIImage(named:"Pause_White"),for: .normal)
            updateBeat()
            updatePendulum()
            // metronome.play()
            // sequencer.play()
            restartPendulum()
        } else {
            metronomeOn = false
            sender.setImage(UIImage(named:"Play_White"),for: .normal)
            pausePendulum()
            // metronome.stop()
            sequencer.stop()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? SettingsTableViewController {
            destinationViewController.metronomeOn = metronomeOn
        }
    }
}


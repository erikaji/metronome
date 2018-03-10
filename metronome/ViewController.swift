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
    
    // Status
    var metronomeOn = false
    var currentTempoIndex = TempoConstants.startingTempoIndex
    var currentToneIndex = ToneConstants.startingToneIndex
    
    // Metronome, courtesy of AudioKit
    var metronome = AKSamplerMetronome()
    var mixer = AKMixer()
    
    // Thread - REMOVE
    var timebaseInfo = mach_timebase_info_data_t()
    var thread_id: thread_port_t = 0
    var thread: Thread?
    var lastValue = 0.0
    
    
    
    // MARK: Core
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI elements
        setupTempoLabels()
        setupKnob()
        setupPendulum()
        UserDefaults.standard.set(currentToneIndex, forKey: "tone")
        
        // Setup Metronome
        let currentToneName = ToneConstants.toneNames[currentToneIndex]
        guard let soundUrl = Bundle.main.url(forResource: currentToneName, withExtension: "caf")
            else {
                print("Error: unable to retrieve the default metronome tone.")
                fatalError()
        }
        metronome.sound = soundUrl
        metronome >>> mixer
        mixer.volume = 1.0
        AudioKit.output = mixer
        
        // Enable background playback
        do {
            try AKSettings.setSession(category: .playback, with: .mixWithOthers)
            AKSettings.playbackWhileMuted = true
        } catch {
            print("Error: unable to enable background playback.")
        }
        
        // Start Metronome
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        
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
        if thread != nil { thread!.cancel() } // REMOVE

        // change tone
        currentToneIndex = UserDefaults.standard.integer(forKey: "tone") // update tone
        let currentToneName = ToneConstants.toneNames[currentToneIndex]
        guard let soundUrl = Bundle.main.url(forResource: currentToneName, withExtension: "caf")
            else {
                print("Error: unable to retrieve the default metronome tone.")
                fatalError()
        }
        metronome.sound = soundUrl
        
        // REMOVE
        let currentTempo = Double(tempoValues[currentTempoIndex])
        let timeInterval: Double = 60.0 / currentTempo
        startMachTimer(seconds: timeInterval)
        
        // change tempo
        let now = AVAudioTime(hostTime: mach_absolute_time())
        metronome.setTempo(currentTempo, at: now)
    }
    
    // MARK: playOneSound
    @objc func playOneSound() {
        currentToneIndex = UserDefaults.standard.integer(forKey: "tone") // update tone
        let currentToneName = ToneConstants.toneNames[currentToneIndex]
        do {
            let mixloop = try AKAudioFile(readFileName: currentToneName + ".caf")
            let player = try AKAudioPlayer(file: mixloop)
            player.volume = 0.75
            AudioKit.output=player
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
    
    
    
    // MARK: MachTimer - REMOVE
    func startMachTimer(seconds: Double) {
        Thread.detachNewThread {
            autoreleasepool {
                self.configureThread()
                self.thread = Thread.current
                print(Thread.current)
                var when = mach_absolute_time()
                repeat {
                    when += self.nanosToAbs(UInt64(seconds * Double(NSEC_PER_SEC))) // how long to wait
                    mach_wait_until(when)
                    if !self.metronomeOn { break } // prevents lagging sound
                    if Thread.current.isCancelled {
                        print ("thread is cancelled")
                        break }
                } while(self.metronomeOn)
            }
        }
    }
    
    func configureThread() {
        mach_timebase_info(&timebaseInfo)
        
        let clock2abs = Double(timebaseInfo.denom) / Double(timebaseInfo.numer) * Double(NSEC_PER_SEC)
        var policy = thread_time_constraint_policy()
        policy.period      = UInt32(0.00 * clock2abs)
        policy.computation = UInt32(0.03 * clock2abs) // 30 ms of work
        policy.constraint  = UInt32(0.05 * clock2abs)
        policy.preemptible = 0
        
        thread_id = pthread_mach_thread_np(pthread_self())
        let THREAD_TIME_CONSTRAINT_POLICY_COUNT = mach_msg_type_number_t(MemoryLayout<thread_time_constraint_policy>.size / MemoryLayout<integer_t>.size)
        
        let ret: Int32 = withUnsafeMutablePointer(to: &policy) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(THREAD_TIME_CONSTRAINT_POLICY_COUNT)) {
                thread_policy_set(thread_id, UInt32(THREAD_TIME_CONSTRAINT_POLICY), $0, THREAD_TIME_CONSTRAINT_POLICY_COUNT)
            }
        }
        
        if ret != KERN_SUCCESS {
            mach_error("thread_policy_set:", ret)
            exit(1)
        }
    }
    
    func nanosToAbs(_ nanos: UInt64) -> UInt64 {
        return nanos * UInt64(timebaseInfo.denom) / UInt64(timebaseInfo.numer)
    }
    
    
    
    // MARK: Actions
    @IBAction func playPauseButton(_ sender: UIButton) {
        if metronomeOn == false {
            metronomeOn = true
            sender.setImage(UIImage(named:"Pause_White"),for: .normal)
            updateBeat()
            updatePendulum()
            restartPendulum()
            metronome.play()
        } else {
            metronomeOn = false
            sender.setImage(UIImage(named:"Play_White"),for: .normal)
            pausePendulum()
            metronome.stop()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? SettingsTableViewController {
            destinationViewController.metronomeOn = metronomeOn
        }
    }
}


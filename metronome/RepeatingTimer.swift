//
//  RepeatingTimer.swift
//  metronome
//
//  Created by Erika Ji on 12/15/17.
//  Copyright © 2017 Erika Ji. All rights reserved.
//
// RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
// crashes that occur from calling resume multiple times on a timer that is
// already resumed (noted by https://github.com/SiftScience/sift-ios/issues/52).
// This class was designed by Daniel Galasko
// (https://medium.com/@danielgalasko/a-background-repeating-timer-in-swift-412cecfd2ef9).
//

import UIKit

class RepeatingTimer {
    private enum State {
        case suspended
        case resumed
    }
    
    private var state: State = .suspended
    var eventHandler: (() -> Void)?
    
    /* TEMP */
    var testBeatFrequency = Date().timeIntervalSince1970
    
    public lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now(), repeating: .milliseconds(200))
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
            
            /* TEMP */
            let newDate = Date().timeIntervalSince1970
            print("herrospecial", newDate-(self?.testBeatFrequency)!)
            self?.testBeatFrequency = newDate
            
            
        })
        return t
    }()
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }
    
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}

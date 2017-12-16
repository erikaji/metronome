//
//  RepeatingTimer.swift
//  metronome
//
//  Created by Erika Ji on 12/15/17.
//  Copyright © 2017 Erika Ji. All rights reserved.
//
//  This RepeatingTimer class extends the RepeatingTimer class specified by Daniel Galasko
//  (https://medium.com/@danielgalasko/a-background-repeating-timer-in-swift-412cecfd2ef9).
//
//  RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
//  crashes that occur from calling resume multiple times on a timer that is
//  already resumed (noted by https://github.com/SiftScience/sift-ios/issues/52).
//
//  We use RepeatingTimer / DispatchSourceTimer instead of the standard Timer function in
//  order to keep the timer accurate when the app goes into the background. (If we use the
//  standard Timer function, especially when bpm is high, moving the app into the
//  background significantly delays the click that immediately follows.)
//

import UIKit

class RepeatingTimer {
    // MARK: Constants & Variables
    private enum State {
        case suspended
        case resumed
    }
    
    private var state: State = .suspended
    private var eventHandler: (() -> Void)?
    
    public lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now(), repeating: .milliseconds(200))
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        
    
        })
        return t
    }()
    
    
    
    // MARK: Deinitialization
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
    
    
    
    // MARK: Functions
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

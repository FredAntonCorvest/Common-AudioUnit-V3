//  SimplePlayEngine+Recording.swift
//
//  Created by Fred Anton Corvest (FAC) on 13/11/2016.
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import AVFoundation

/*
 SimplePlayEngine utility extension to manage recording of the main mixer node output to a file.
 
 The SimplePlayEngine class is provided by Apple in the sample "AudioUnitV3Example: A Basic AudioUnit Extension and Host Implementation"
 https://developer.apple.com/library/content/samplecode/AudioUnitV3Example/Introduction/Intro.html
 
 As the visibility of the playback engine property (AVAudioEngine) in the class SimplePlayEngine is private you should change it to internal in order to use this extension (or to fileprivate and move this extension to the same file).
 
 How to use the extension in the ViewController:
 
 ...
 
    if (!self.engine.isRecording) {
        self.engine.startRecording(toURL: URL(fileURLWithPath: "YOUR_PATH/output.aif"))
    } else {
        self.engine.stopRecording()
    }
 
 ...
 
 */

extension SimplePlayEngine {
    /// Returns the recording status
    var isRecording : Bool {
        get {
            guard let number = objc_getAssociatedObject(self, &RecordingStatus.recording) as? NSNumber else {
                return false
            }
            return number.boolValue
        }
    }
    
    /// Starts to record the main mixer node output to the given URL using the format of the bus 0. The engine must be running.
    func startRecording(toURL: URL) {
        startRecording(toURL: toURL, format: self.engine.mainMixerNode.outputFormat(forBus: 0))
    }
    
    /// Starts to record the main mixer node output to the given URL using the given format. The engine must be running.
    func startRecording(toURL: URL, format: AVAudioFormat) {
        if (self.engine.isRunning && !self.isRecording) {            
            guard let outfile = try? AVAudioFile(forWriting: toURL, settings: format.settings) else {return}
            
            self.engine.mainMixerNode.installTap(onBus: 0,
                                                 bufferSize: 4096,
                                                 format: self.engine.outputNode.outputFormat(forBus: 0),
                                                 block: {
                                                    (buff: AVAudioPCMBuffer, time: AVAudioTime) in _ = try? outfile.write(from: buff)
            })
            
            setRecording(status: true)
        }
    }
    
    /// Stops the recording. The engine must be running.
    func stopRecording() {
        if (self.engine.isRunning && self.isRecording) {
            self.engine.mainMixerNode.removeTap(onBus: 0)
            setRecording(status: false)
        }
    }
    
    private struct RecordingStatus {
        static var recording : NSNumber?
    }
    
    private func setRecording(status : Bool) {
        objc_setAssociatedObject(self, &RecordingStatus.recording, NSNumber.init(value: status), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

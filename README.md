# Common-AudioUnit-V3
Utilities related to the new version 3 Audio Units provided by Apple

### FacAUAudioUnit

> Fred: Apple provided in the Filter sample code an example about the preset management based on a static array containing the parameters value of each preset. This solution is perfect to learn the basis of the presets management but not sufficient if you want to load/store presets data from/to files. So I've created an AUAudioUnit subclass providing convenience methods and the first version provides presets management.

FacAUAudioUnit provides loading and saving of user's presets from/to the disk. There are two methods: **loadPresets** and **savePreset**. Subclassers should call loadPresets in the init method, savePreset can be called in the ViewController.

Usage in Filter sample code provided by Apple:

1. InstrumentDemo.h
```objective-c 
#import "FacAUAudioUnit.h"

@interface AUv3InstrumentDemo : FacAUAudioUnit
```

2. InstrumentDemo.mm
```objective-c 
- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
	//...

	[self loadPresets];	
	return self;
}
```

3. ViewController.swift
```swift
/// Saves the content of the AUParameterTree to a preset file on the disk (document folder)
@IBAction func saveAsPreset(_ sender: AnyObject?) {
	let audioUnit = playEngine.testAudioUnit as! AUv3InstrumentDemo
        audioUnit.savePreset("Slow", havingDescription: "Demo slow preset", asDefault: true)
}
```

4. Slow.preset
```JSON
{
  "Name" : "slow",
  "Description" : "Demo slow preset",
  "Format" : "FAC_MAGIC_NUMBER",
  "IsDefault" : false,
  "Version" : "1.0",
  "Date" : "Nov 20, 2016, 4:50:55 PM",
  "Parameters" : [
    {
      "KeyPath" : "attack",
      "Value" : 3
    },
    {
      "KeyPath" : "release",
      "Value" : 3
    }
  ]
}
```

### SimplePlayEngine+Recording.swift

> Fred: As AuV3 developers, one of the first things I've needed is the ability to record the output of my App for signal analysing purposes or simply sampling.

SimplePlayEngine utility extension to manage recording of the main mixer node output to a file. The SimplePlayEngine class is provided by Apple in the sample [AudioUnitV3Example: A Basic AudioUnit Extension and Host Implementation"](
https://developer.apple.com/library/content/samplecode/AudioUnitV3Example/Introduction/Intro.html)

Usage (Swift):
```swift
if (!self.engine.isRecording) {
	self.engine.startRecording(toURL: URL(fileURLWithPath:"YOUR_PATH/output.aif"))
} else {
	self.engine.stopRecording()
}
```

Usage (Objective-C):
```objective-c
if (![engine isRecording]) {
	[engine startRecordingToURL: [NSURL URLWithString:@"YOUR_PATH/output.aif"]];
} else {
	[engine stopRecording];
}
```

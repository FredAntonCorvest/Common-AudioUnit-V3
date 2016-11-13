# Common-AudioUnit-V3
Utilities related to the new version 3 Audio Units

### SimplePlayEngine+Recording.swift

SimplePlayEngine utility extension to manage recording of the main mixer node output to a file.The SimplePlayEngine class is provided by Apple in the sample [AudioUnitV3Example: A Basic AudioUnit Extension and Host Implementation"](
https://developer.apple.com/library/content/samplecode/AudioUnitV3Example/Introduction/Intro.html)

Usage:
```swift
if (!self.engine.isRecording) {
	self.engine.startRecording(toURL: URL(fileURLWithPath:"YOUR_PATH/output.aif"))
} else {
	self.engine.stopRecording()
}
```

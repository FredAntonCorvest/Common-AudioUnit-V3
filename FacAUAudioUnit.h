//  FacAUAudioUnit.h
//
//  Created by Fred Anton Corvest (FAC) on 19/11/2016.
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

#import <AVFoundation/AVFoundation.h>

/*!
 @class         FacAUAudioUnit
 @brief         An AUAudioUnit subclass providing convenience methods created by Fred Anton Corvest (FAC), first version provides presets management.
 @discussion    Provides loading and saving of user's presets from/to the disk.
                Ps: Sets the key UIFileSharingEnabled to true in the Info.plist to support iTunes file sharing
*/
@interface FacAUAudioUnit : AUAudioUnit

/*!
 @method        loadPresets
 @brief         Loads available presets in memory
 @discussion    Installs(copies) the factory presets to the user document folder and load each presets file in memory. 
                The factory presets are provided by the developer in the resource bundle of the application extension.
                Subclassers should call loadPresets in the init method.
 */
-(void) loadPresets;

/*!
 @method        savePreset
 @brief         Saves the presets to the user document folder
 @discussion    Saves the content of the AUParameterTree to a preset file on the disk (document folder).
                The developer can copy those files to create a set of factory presets in the resource bundle of the application extension.
                Ps: For now the preset is only saved on disk and will only be available in the AUAudioUnit::factoryPresets at the next loading of the application.
 @param name
    Name of the preset
 @param description
    Description of the preset
 @para isDefault
    Defines if this preset is the default one
 */
-(void) savePreset:(NSString*) name havingDescription:(NSString*) description asDefault:(BOOL)isDefault;

@end

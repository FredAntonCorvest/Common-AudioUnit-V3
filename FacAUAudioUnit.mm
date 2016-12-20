//  FacAUAudioUnit.mm
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

#import "FacAUAudioUnit.h"

#define FILE_EXTENSION "preset"

#pragma mark - FacAUAudioUnit : AUAudioUnit

@implementation FacAUAudioUnit {
    AUAudioUnitPreset *_currentPreset;
    NSInteger _currentFactoryPresetIndex;
    NSArray<AUAudioUnitPreset *> *_presets;
    NSArray *_presetsParameters;
    NSString *_documentsPath;
    NSString *_presetUID;
    NSString *_presetVersion;
}

@synthesize factoryPresets = _presets;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError presetFolderName:(NSString*) presetFolderName presetVersion:(NSString*) presetVersion {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];
    
    if (self == nil) {
        return nil;
    }
    
    _presetUID = [NSString stringWithFormat:@"%02X%02X", componentDescription.componentManufacturer, componentDescription.componentSubType];
    _presetVersion = presetVersion;
    
    #if TARGET_OS_IPHONE
    NSString* presetFolder = @"presets";
    #elif TARGET_OS_MAC
    NSString* presetFolder = [NSString stringWithFormat:@"%@/presets", presetFolderName];
    #endif
    
    _documentsPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:presetFolder];
    // WARNING: When you use the App you get the folder Users/YourUserName/... BUT when you use a host (logic...) you get /Users/YourUserName/Library/Containers/YourExtensionBundleId/...
    // Example: /Users/Name/Library/Containers/com.name.AppOSX.AppExtensionOSX/Data/Documents/
    
    #if TARGET_OS_MAC
    NSError * error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:_documentsPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error != nil) {
        NSLog(@"[FacAUAudioUnit::init] %@", error.description);
    }
    #endif
    
    return self;
}

-(void)dealloc {
    _presets = nil;
    _presetsParameters = nil;
}

-(void) loadPresets {
    [self installFactoryPresets];
    // Copies the factory presets to the user document folder
    
    NSMutableArray* presetItems = [NSMutableArray new];
    NSMutableArray* presetItemsParameters = [NSMutableArray new];
    
    _currentFactoryPresetIndex = 0;
    __block NSError* error = nil;
    
    [self explorePath:_documentsPath andDoBlockForEachFile:^bool (NSInteger position, NSString* filePath) {
        // Loads each presets file in memory
        
        NSData *jsonData = [NSData dataWithContentsOfFile:[_documentsPath stringByAppendingPathComponent:filePath.lastPathComponent]];
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        
        if (error != nil) {
            NSLog(@"[FacAUAudioUnit::loadPresets] %@", error.description);
            return false;
        }
        
        NSString* uid = [dictionary objectForKey:@"UID"];
        
        if (![uid isEqualToString:_presetUID]) {
            NSLog(@"[FacAUAudioUnit::loadPresets] Invalid UID %@ (%@ required)", uid, _presetUID);
            return false;
        }
        
        AUAudioUnitPreset* newPreset = [AUAudioUnitPreset new];
        newPreset.number = position;
        newPreset.name = [dictionary objectForKey:@"Name"];
        
        [presetItems addObject:newPreset];
        [presetItemsParameters addObject:[dictionary objectForKey:@"Parameters"]];
        
        if (_currentFactoryPresetIndex == 0 && [[dictionary objectForKey:@"IsDefault"] boolValue]) {
            _currentFactoryPresetIndex = position;
        }
        
        return true;
    }];
    
    _presets = [NSArray arrayWithArray:presetItems];
    // Contains AUAudioUnitPreset (# and name)
    
    _presetsParameters = [NSArray arrayWithArray:presetItemsParameters];
    // Contains the value of each parameter
    
    if (_presets.count > 0) {
        self.currentPreset = _presets[_currentFactoryPresetIndex];
    }
}

-(void) savePreset:(NSString*) name havingDescription:(NSString*) description asDefault:(BOOL)isDefault {
    NSMutableArray *parameters = [NSMutableArray new];
    
    [[self.parameterTree allParameters] enumerateObjectsUsingBlock:^(AUParameter * _Nonnull parameter, NSUInteger idx, BOOL * _Nonnull stop) {
        // Stores the KeyPath and the Value of each parameter
        [parameters addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                               parameter.keyPath, @"KeyPath",
                               [NSNumber numberWithFloat:parameter.value], @"Value", nil]];
    }];
    
    NSDictionary* presetDictionnary = [NSDictionary dictionaryWithObjectsAndKeys:
                                 name, @"Name",
                                 description, @"Description",
                                 [NSNumber numberWithBool:isDefault] , @"IsDefault",
                                 _presetVersion, @"Version",
                                 _presetUID, @"UID",
                                 [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                dateStyle:NSDateFormatterMediumStyle
                                                                timeStyle:NSDateFormatterMediumStyle], @"Date",
                                 parameters, @"Parameters", nil];
    // Stores presets data
    
    NSString* presetFile = [NSString stringWithFormat:@"%@.%@", [_documentsPath stringByAppendingPathComponent:name], @FILE_EXTENSION]; NSError* error = nil;
    [[NSJSONSerialization dataWithJSONObject:presetDictionnary options:NSJSONWritingPrettyPrinted error:&error] writeToFile:presetFile atomically:true];
    // Saves the content of the AUParameterTree to a preset file on the disk
    
    if (error != nil) {
        NSLog(@"[FacAUAudioUnit::loadPresets] %@", error.description);
    } else {
        NSLog(@"[FacAUAudioUnit::loadPresets] Preset saved in %@", presetFile);
    }
}

-(void) installFactoryPresets {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    __block NSError* error = nil;
    
    [self explorePath:[NSBundle bundleForClass: self].bundlePath andDoBlockForEachFile:^bool (NSInteger position, NSString* filePath) {
        NSString *documentPresetFile = [_documentsPath stringByAppendingPathComponent:filePath.lastPathComponent];
        
        if ([fileManager fileExistsAtPath:documentPresetFile] == NO) {
            [fileManager copyItemAtPath:filePath toPath:documentPresetFile error:&error];
            // Copies from bundle to the document folder
            if (error != nil) {
                NSLog(@"[FacAUAudioUnit::loadPresets] %@", error.description);
                return false;
            }
        }
        
        return true;
    }];
}

typedef bool (^blockOnPath) (NSInteger position, NSString* filePath);

-(void) explorePath:(NSString*) path andDoBlockForEachFile:(blockOnPath)block {
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
    NSString *file; int idx = 0;
    while (file = [dirEnum nextObject]) {
        if ([[file pathExtension] isEqualToString: @FILE_EXTENSION]) {
            if (block(idx, [path stringByAppendingPathComponent:file])) {
                idx++;
            }
        }
    }
}

#pragma mark- AUAudioUnit (Optional Properties)

- (AUAudioUnitPreset *) currentPreset{
    if (_currentPreset.number >= 0) {
        return [_presets objectAtIndex:_currentFactoryPresetIndex];
    } else {
        // < -1 TODO user preset
        return _currentPreset;
    }
}

- (void) setCurrentPreset:(AUAudioUnitPreset *)currentPreset {
    if (currentPreset == nil) {
        NSLog(@"[FacAUAudioUnit::loadPresets] Invalid preset");
        return;
    }
    
    if (currentPreset.number >= 0 && currentPreset.number < _presetsParameters.count) {
        NSArray* presetParameters = _presetsParameters[currentPreset.number];
        [presetParameters enumerateObjectsUsingBlock:^(NSDictionary* dictionary, NSUInteger idx, BOOL *stop) {
            AUParameter* currentParameter = [self.parameterTree valueForKeyPath:[dictionary objectForKey:@"KeyPath"]];
            if (currentParameter != nil) {
                currentParameter.value = [[dictionary objectForKey:@"Value"] doubleValue];
            } else {
                NSLog(@"[FacAUAudioUnit::loadPresets] Invalid parameter address in preset %@", currentPreset.name);
                *stop = true;
            }
        }];
        
        _currentPreset = currentPreset;
        _currentFactoryPresetIndex = _currentPreset.number;
    } else if (nil != currentPreset.name) {
        _currentPreset = currentPreset;
    } else {
        NSLog(@"[FacAUAudioUnit::loadPresets] Invalid AUAudioUnitPreset");
    }
}

@end

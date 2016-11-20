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

#define FILE_VERSION "1.0"
#define FILE_EXTENSION "preset"
#define FILE_FORMAT "FAC_MAGIC_NUMBER"

#pragma mark - FacAUAudioUnit : AUAudioUnit

@implementation FacAUAudioUnit {
    AUAudioUnitPreset *_currentPreset;
    NSInteger _currentFactoryPresetIndex;
    NSArray<AUAudioUnitPreset *> *_presets;
    NSArray *_presetsParameters;
    NSString *_documentsPath;
}

@synthesize factoryPresets = _presets;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];
    
    if (self == nil) {
        return nil;
    }
    
    _documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
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
        
        NSString* fileFormat = [dictionary objectForKey:@"Format"];
        
        if (![fileFormat isEqualToString:@FILE_FORMAT]) {
            NSLog(@"[FacAUAudioUnit::loadPresets] Invalid file format %@ (%@ required)", fileFormat, @FILE_FORMAT);
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
                                 @FILE_VERSION, @"Version",
                                 @FILE_FORMAT, @"Format",
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

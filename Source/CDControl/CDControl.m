/*
	CDControl.m
	cocoaDialog
	Copyright (C) 2004 Mark A. Stratman <mark@sporkstorms.org>

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import "Dialogs.h"

@implementation CDControl

#pragma mark - Internal Control Methods

- (NSString*) controlNib { return @""; }

- (CDOptions*) controlOptionsFromArgs:(NSArray*)args {

  return [CDOptions getOpts:args availableKeys:self.availableKeys depreciatedKeys:self.depreciatedKeys];
}

- (CDOptions *) controlOptionsFromArgs:(NSArray *)args withGlobalKeys:(NSDictionary *)globalKeys {

  NSMutableDictionary *allKeys = @{}.mutableCopy;

  [allKeys addEntriesFromDictionary:globalKeys];

  !self.availableKeys ?: [allKeys addEntriesFromDictionary:self.availableKeys];

  return [CDOptions getOpts:args availableKeys:allKeys depreciatedKeys:self.depreciatedKeys];
}

- (void) dealloc { !timer ?: [timer invalidate]; }

- (NSString *) formatSecondsForString:(NSInteger)timeInSeconds {

  static NSString *timerFormat = nil;
  timerFormat = timerFormat ?: [self.options hasOpt:@"timeout-format"]
  ? [self.options optValue:@"timeout-format"]
  : @"Time remaining: %";

  NSString *returnString = timerFormat;

  NSInteger seconds =  timeInSeconds % 60,
            minutes = (timeInSeconds / 60) % 60,
              hours =  timeInSeconds / 3600,
               days =  timeInSeconds /(3600 * 24);

//  NSString *relative = days > 0 ? days > 1  ? [NSString stringWithFormat:@"%d days", days]
//                                            : [NSString stringWithFormat:@"%d day", days]
//                                : hours > 0 ? hours > 1   ? [NSString stringWithFormat:@"%d hours", hours]
//                                                          : [NSString stringWithFormat:@"%d hour", hours]
//                                            : minutes > 0 ? minutes > 1 ? [NSString stringWithFormat:@"%d minutes", minutes]
//                                                                        : [NSString stringWithFormat:@"%d minute", minutes]
//                                                          : seconds > 0 ? seconds > 1) {
//            relative = [NSString stringWithFormat:@"%d seconds", seconds];
//          }
//          else {
//            relative = [NSString stringWithFormat:@"%d second", seconds];
//          }
//        }
//      }
//    }
//  }
    NSString *relative =

      days > 0 ? days > 1  ? [NSString stringWithFormat:@"%d days", days]
                           : [NSString stringWithFormat:@"%d day", days]
               : hours > 0 ? hours > 1   ? [NSString stringWithFormat:@"%d hours", hours]
                                         : [NSString stringWithFormat:@"%d hour", hours]
                           : minutes > 0 ? minutes > 1 ? [NSString stringWithFormat:@"%d minutes", minutes]
                                                       : [NSString stringWithFormat:@"%d minute", minutes]
                           : seconds > 0 ? seconds > 1 ? [NSString stringWithFormat:@"%d seconds", seconds]
                                                       : [NSString stringWithFormat:@"%d second", seconds]
              : @"unknown";

  returnString = [returnString stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%d", seconds]];
  returnString = [returnString stringByReplacingOccurrencesOfString:@"%m" withString:[NSString stringWithFormat:@"%d", minutes]];
  returnString = [returnString stringByReplacingOccurrencesOfString:@"%h" withString:[NSString stringWithFormat:@"%d", hours]];
  returnString = [returnString stringByReplacingOccurrencesOfString:@"%d" withString:[NSString stringWithFormat:@"%d", days]];
  returnString = [returnString stringByReplacingOccurrencesOfString:@"%r" withString:relative];
  return returnString;
}
- initWithOptions:(CDOptions *)opts {

  self = [super initWithOptions:opts];
  controlExitStatus       = -1;
  controlExitStatusString = nil;
  controlReturnValues     = @[].mutableCopy;
  controlItems            = @[].mutableCopy;
  return self;
}

- (BOOL) loadControlNib:(NSString *)nib {

  // Load nib
  if (nib) {
    if (![nib isEqualToString:@""] && ![NSBundle loadNibNamed:nib owner:self]) {
      if ([self.options hasOpt:@"debug"])
        [self debug:[NSString stringWithFormat:@"Could not load control interface: \"%@.nib\"", nib]];

      return NO;
    }
  }
  else return [self debug:@"Control did not specify a NIB interface file to load."], NO;

  panel = [CDPanel.alloc initWithOptions:self.options];
  icon  = [CDIcon.alloc  initWithOptions:self.options];
  if (controlPanel) {
    [panel setPanel:controlPanel];
    [icon  setPanel:panel];
  }
  !controlIcon ?: [icon setControl:controlIcon];
  return YES;
}

+ (void) printHelpTo:(NSFileHandle *)fh {

  if (!fh) return;
  [fh writeData:[@"Usage: cocoaDialog <run-mode> [options]\n\tAvailable run-modes:\n" dataUsingEncoding:NSUTF8StringEncoding]];
  NSArray *sortedAvailableKeys = [self.availableControls.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

  NSEnumerator *en = [sortedAvailableKeys objectEnumerator];
  id key;
  unsigned i = 0;
  unsigned currKey = 0;
  while (key = [en nextObject]) {
    if (i == 0) {
      [fh writeData:[@"\t\t" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [fh writeData:[key dataUsingEncoding:NSUTF8StringEncoding]];
    if (i <= 6 && currKey != [sortedAvailableKeys count] - 1) {
      [fh writeData:[@", " dataUsingEncoding:NSUTF8StringEncoding]];
      i++;
    }
    if (i == 6) {
      [fh writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
      i = 0;
    }
    currKey++;
  }

  [fh writeData:[@"\n\tGlobal Options:\n\t\t--help, --debug, --title, --width, --height,\n\t\t--string-output, --no-newline\n\nSee http://mstratman.github.com/cocoadialog/#documentation\nfor detailed documentation.\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) runControl {
  // The control must either: 1) sub-class -(NSString *) controlNib, return the name of the NIB, and then connect "controlPanel" in IB or 2) set the panel manually with [panel setPanel:(NSPanel *)]  when creating the control.
  if (panel.panel) {
    // Set icon
    !icon.control ?: [icon setIconFromOptions];
    // Reposition Panel
    [panel setPosition];
    [panel setFloat];
    [NSApp run];
  }
  else {
    if ([self.options hasOpt:@"debug"]) {
      [self debug:@"The control has not specified the panel it is to use and cocoaDialog cannot continue."];
    }
    exit(255);
  }
}

- (void) setTimeout {

  timeout = 0.0f;
  timer = nil;
  // Only initialize timeout if the option is provided
  if ([self.options hasOpt:@"timeout"]) {
    if ([[NSScanner scannerWithString:[self.options optValue:@"timeout"]] scanFloat:&timeout]) {
      mainThread = NSThread.currentThread;
      [NSThread detachNewThreadSelector:@selector(createTimer) toTarget:self withObject:nil];
    } else if ([self.options hasOpt:@"debug"])
      [self debug:@"Could not parse the timeout option."];
  }
  [self setTimeoutLabel];
}

- (void) setTimeoutLabel {

  if (!timeoutLabel) return;

  NSRect labelRect = timeoutLabel.frame;
  float labelNewHeight = -4.0f, labelHeightDiff = labelNewHeight - labelRect.size.height;

  [timeoutLabel setStringValue:[self formatSecondsForString:(int)timeout]];

  if (![timeoutLabel.stringValue isEqualToString:@""] && timeout != 0.0f) {

    NSTextStorage     *textStorage = [NSTextStorage.alloc initWithString:timeoutLabel.stringValue];
    NSTextContainer *textContainer = [NSTextContainer.alloc initWithContainerSize:(NSSize){labelRect.size.width, FLT_MAX}];
    NSLayoutManager *layoutManager = NSLayoutManager.new;

    [layoutManager           addTextContainer:textContainer];
    [textStorage             addLayoutManager:layoutManager];
    [layoutManager glyphRangeForTextContainer:textContainer];

    labelNewHeight  = [layoutManager usedRectForTextContainer:textContainer].size.height;
    labelHeightDiff = labelNewHeight - labelRect.size.height;

    // Set label's new height
    NSRect l = NSMakeRect(labelRect.origin.x, labelRect.origin.y - labelHeightDiff, labelRect.size.width, labelNewHeight);
    [timeoutLabel setFrame: l];
  }

  else [timeoutLabel setHidden:YES];

  // Set panel's new width and height
  NSSize p = [panel.panel.contentView frame].size;
  p.height += labelHeightDiff;
  [panel.panel setContentSize:p];
}

- (void) createTimer {

  @autoreleasepool {
    timerThread = NSThread.currentThread;
    NSRunLoop *_runLoop = NSRunLoop.currentRunLoop;
    timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(processTimer) userInfo:nil repeats:YES];
    [_runLoop addTimer:timer forMode:NSRunLoopCommonModes];
    [_runLoop run];
  }
}
- (void) stopTimer {

  [timer invalidate];
  timer = nil;
  [self performSelector:@selector(stopControl) onThread:mainThread withObject:nil waitUntilDone:YES];
}

- (void) processTimer {
  // Decrease timeout value
  timeout = timeout - 1.0f;
  // Update and position the label if it exists
  if (timeout > 0.0f) {
    if (timeoutLabel != nil) {
      [timeoutLabel setStringValue:[self formatSecondsForString:(int)timeout]];
    }
  }
  else {
    controlExitStatus = 0;
    controlExitStatusString = @"timeout";
    controlReturnValues = [NSMutableArray array];
    [self stopTimer];
  }
}

- (void) stopControl {
  // Stop timer
  !timerThread ?: [timerThread cancel];

  // Stop any modal windows currently running
  [NSApp stop:self];
  if (![self.options hasOpt:@"quiet"] && controlExitStatus != -1 && controlExitStatus != -2) {
    if ([self.options hasOpt:@"string-output"]) {
      controlExitStatusString = controlExitStatusString ?: [NSString stringWithFormat:@"%d", controlExitStatus];
      [controlReturnValues insertObject:controlExitStatusString atIndex:0];
    }
    else
      [controlReturnValues insertObject:[NSString stringWithFormat:@"%d", controlExitStatus] atIndex:0];
  }
  if (controlExitStatus == -1) controlExitStatus = 0;
  if (controlExitStatus == -2) controlExitStatus = 1;

  if (controlReturnValues) {   // Print all the returned lines

    NSFileHandle *fh = NSFileHandle.fileHandleWithStandardOutput;

    for (unsigned i = 0; i < controlReturnValues.count; i++) {

      !fh ?: [fh writeData:[controlReturnValues[i] dataUsingEncoding:NSUTF8StringEncoding]];

      if ((![self.options hasOpt:@"no-newline"] || i+1 < controlReturnValues.count) && fh)

        [fh writeData:[[NSString stringWithString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }

  } else if ([self.options hasOpt:@"debug"]) [self debug:@"Control returned nil."];

  exit(controlExitStatus);   // Return the exit status
}

#pragma mark - Subclassable Control Methods -
- (NSDictionary *) availableKeys {return nil;}
- (void) createControl {};
- (BOOL) validateOptions { return YES; }
- (NSDictionary *) depreciatedKeys {return nil;}
- (NSDictionary *) globalAvailableKeys {
  NSNumber *vOne = @CDOptionsOneValue;
  NSNumber *vNone = @CDOptionsNoValues;
  return @{@"help": vNone,
           @"debug": vNone,
           @"quiet": vNone,
           @"timeout": vOne,
           @"timeout-format": vOne,
           @"string-output": vNone,
           @"no-newline": vNone,
           // Panel
           @"title": vOne,
           @"width": vOne,
           @"height": vOne,
           @"posX": vOne,
           @"posY": vOne,
           @"no-float": vNone,
           @"minimize": vNone,
           @"resize": vNone,
           // Icon
           @"icon": vOne,
           @"icon-bundle": vOne,
           @"icon-type": vOne,
           @"icon-file": vOne,
           @"icon-size": vOne,
           @"icon-width": vOne,
           @"icon-height": vOne};
}
- (BOOL) validateControl:(CDOptions *)options {return YES;}



#pragma mark - CDControl
+ (NSDictionary *) availableControls {

  return @{
           @"checkbox" : CDCheckboxControl.class,
           @"dropdown" : CDPopUpButtonControl.class,
           @"fileselect" : CDFileSelectControl.class,
           @"filesave" : CDFileSaveControl.class,
           @"inputbox" : CDInputboxControl.class,
           @"msgbox" : CDMsgboxControl.class,
           @"notify" : CDNotifyControl.class,
           @"ok-msgbox" : CDOkMsgboxControl.class,
           @"progressbar" : CDProgressbarControl.class,
           @"radio" : CDRadioControl.class,
           @"slider" : CDSlider.class,
           @"secure-inputbox" : CDInputboxControl.class,
           @"secure-standard-inputbox" : CDStandardInputboxControl.class,
           @"standard-dropdown" : CDStandardPopUpButtonControl.class,
           @"standard-inputbox" : CDStandardInputboxControl.class,
           @"textbox" : CDTextboxControl.class,
           @"yesno-msgbox" : CDYesNoMsgboxControl.class};

}

@end



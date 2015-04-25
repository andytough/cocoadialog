/*
	AppController.h
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

#import <Foundation/Foundation.h>
#import <Dialogs/Dialogs.h>

@interface AppController : NSObject {
    CDControl               *currentControl;
    IBOutlet NSPanel        *aboutPanel;
    IBOutlet NSTextField    *aboutAppLink;
    IBOutlet NSTextField    *aboutText;
    NSMutableArray          *arguments;
}

    - (NSString *) appVersion;
    - (void) chooseControl:(NSString *)runMode useOptions:options addExtraOptionsTo:(NSMutableDictionary *)extraOptions;
    -(void)setHyperlinkForTextField:(NSTextField*)aTextField replaceString:(NSString *)aString withURL:(NSString *)aURL;
@end

@interface NSAttributedString (Hyperlink)
    +(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL withFont:(NSFont *)aFont;
@end

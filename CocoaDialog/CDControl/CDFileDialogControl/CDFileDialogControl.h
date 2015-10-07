/*
	CDFileDialogControl.h
	cocoaDialog
	Copyright (C) 2004-2006 Mark A. Stratman <mark@sporkstorms.org>
 
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

#import "CDControl.h"

@interface CDFileDialogControl : CDControl <NSOpenSavePanelDelegate>
{
    NSSavePanel *savePanel;
    NSMutableArray * extensions;
}

- (BOOL) isExtensionAllowed:(NSString*)filename;

// Set options common to any file save panel
- (void) setMisc;

@end

@interface CDFileSaveControl   : CDFileDialogControl @end
@interface CDFileSelectControl : CDFileDialogControl @end


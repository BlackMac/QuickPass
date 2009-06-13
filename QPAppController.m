/*
 Copyright (c) 2009, Stefan Lange-Hegermann
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of source.bricks nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY STEFAN LANGE-HEGERMANN ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL STEFAN LANGE-HEGERMANN BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "QPAppController.h"
#include "pronpas.h"

@interface NSStatusItem (Hack)
- (NSRect)hackFrame;
@end

@implementation NSStatusItem (Hack)
- (NSRect)hackFrame
{
    return [_fWindow frame];
}
@end

@implementation QPAppController
+ (void)initialize {
	NSDictionary *defaultValues=[NSDictionary dictionaryWithObjectsAndKeys:
			@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890#*?-_",@"validchars",
			@"6",@"minlength",									// Minimum length for random passwords
			@"8",@"maxlength",									// Maximum length for random passwords
			@"6",@"minlengthpron",								// Minimum length for pronouncable passwords
			@"8",@"maxlengthpron",								// Maximum length for pronouncable passwords
			[NSNumber numberWithBool:YES],@"firststart",		// Is it the applications first start?
			[NSNumber numberWithBool:YES],@"genpronpass",		// Generate pronouncable passwords
			[NSNumber numberWithBool:YES],@"genrandpass",		// Generate random passwords
			[NSNumber numberWithBool:NO],@"proncap",			// Capitalize random characters in pronouncable passwords
			[NSNumber numberWithBool:YES],@"pronrpunct",		// Append number after password
			[NSNumber numberWithBool:YES],@"pronleet",			// Replace some characters in pronouncable passwords with 1337 representati0n
			@"5",@"passcount",									// Number of random passwords to generate
			@"5",@"passcountpron",								// Number of pronouncable passwords to generate
			nil];
			
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
	srand ( time(NULL) );
	seedPWD();
}

- (IBAction) toggleStartup:(id)sender
{
	if ([sender state]==NSOnState) {
		[self addStartupItem];
	} else {
		[self removeStartupItem];
	}
}

- (void)addStartupItem
{
	NSMutableDictionary *lwDomain=[[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"loginwindow"] mutableCopy];
	NSMutableArray *lwLaunchDict=[[lwDomain objectForKey:@"AutoLaunchedApplicationDictionary"] mutableCopy];
	NSDictionary *appDict=[NSDictionary dictionaryWithObjectsAndKeys:@"YES",@"Hide",[[NSBundle mainBundle] bundlePath],@"Path",nil];
	[lwLaunchDict addObject:appDict];
	[lwDomain setValue:lwLaunchDict forKey:@"AutoLaunchedApplicationDictionary"];
	
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:lwDomain forName:@"loginwindow"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[lwDomain release];
	[lwLaunchDict release];
}

- (void)removeStartupItem
{
	int i;
	NSMutableDictionary *lwDomain=[[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"loginwindow"] mutableCopy];
	NSMutableArray *lwLaunchDict=[[lwDomain objectForKey:@"AutoLaunchedApplicationDictionary"] mutableCopy];
	
	for (i=0;i<[lwLaunchDict count];i++) {
		if ([[[lwLaunchDict objectAtIndex:i] objectForKey:@"Path"] isEqualTo:[[NSBundle mainBundle] bundlePath]]) {
			[lwLaunchDict removeObjectAtIndex:i];
		}
	}
	
	[lwDomain setValue:lwLaunchDict forKey:@"AutoLaunchedApplicationDictionary"];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:lwDomain forName:@"loginwindow"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[lwDomain release];
	[lwLaunchDict release];
}

- (void)awakeFromNib
{
	[self activateStatusMenu];
	
	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"firststart"] isEqualTo:@"YES"]) {
		myTimer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(showInfo:) userInfo:nil repeats:NO];
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:@"NO" forKey:@"firststart"];
	}
}

- (IBAction)showInfo:(id)sender
{
	NSRect screenRect = [[NSScreen mainScreen] frame];
	if (myTimer)
		[myTimer invalidate];
	float left=[theItem hackFrame].origin.x;
	NSPoint winframe=NSMakePoint(left-268 , screenRect.size.height-200);
	[helpWindow setFrameOrigin:winframe];
	[helpWindow fadeIn];
	myTimer=[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(hideInfo:) userInfo:nil repeats:NO];
}

- (IBAction)hideInfo:(id)sender
{
	if (myTimer)
		[myTimer invalidate];
	myTimer=nil;
	[helpWindow fadeOut];
}

- (void)activateStatusMenu
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];

    theItem = [bar statusItemWithLength:NSVariableStatusItemLength];
	
    [theItem retain];
	[theItem setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"key" ofType:@"png"]]];
    [theItem setHighlightMode:YES];
	[theItem setAction:@selector(refreshMenu)];

}

-(NSString *)generatePassword
{
	int i;
	int charval;
	
	NSString *validChars=[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"validchars"];
	int minval=[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"minlength"] intValue];
	int maxval=[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"maxlength"] intValue];

	int subval=maxval-minval+1;
	int loops=rand()%subval+minval;

	NSMutableString *tmpstring=[NSMutableString string];
	for (i=0;i<loops;i++) {
		charval=rand()%[validChars length];
		[tmpstring appendString:[validChars substringWithRange:NSMakeRange(charval,1)]];
	}
	return tmpstring;
}

-(NSString *)generatePronouncablePassword
{
	//NSMutableString *tmpPass=@"";
	int minval=[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"minlengthpron"] intValue];
	int maxval=[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"maxlengthpron"] intValue];

	int subval=maxval-minval+1;
	int loops=rand()%subval+minval;

	char *cstring;
	
	cstring=getPWD(loops);
	NSMutableString *tmpPass=[NSMutableString stringWithCString:cstring];
	free(cstring);
	
	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"proncap"] boolValue]) {
		int i;
		NSString *lcPass=tmpPass;
		tmpPass=[NSMutableString string];
		NSString *ucPass=[lcPass uppercaseString];
		
		for (i=0;i<[lcPass length];i++) {
			if (rand()%3!=1) {
				[tmpPass appendString:[lcPass substringWithRange:NSMakeRange(i,1)]];
			} else {
				[tmpPass appendString:[ucPass substringWithRange:NSMakeRange(i,1)]];
			}
		}
	}
	
	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"pronrpunct"] boolValue]) {
		int num=rand()%99;
		return [tmpPass stringByAppendingFormat:@"%i",num];
	}
	
	return tmpPass;
}

-(void)refreshMenu
{
	int a;
	int passcount=[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"passcount"] intValue];
	int passcountpron=[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"passcountpron"] intValue];
	
	BOOL showRandom=[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"genrandpass"] boolValue];
	BOOL showPron=[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"genpronpass"] boolValue];
	
	while ([[theMenu itemArray] count]>4) {
		[theMenu removeItemAtIndex:0];
	}
	
	if (showRandom) {
		for (a=0;a<passcount;a++) {
			[theMenu insertItemWithTitle:[self generatePassword] action:@selector(copyMenuEntry:) keyEquivalent:@"" atIndex:0];
		}
	}
	
	if (showPron && showRandom) [theMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
	
	if (showPron) {
		for (a=0;a<passcountpron;a++) {
			[theMenu insertItemWithTitle:[self generatePronouncablePassword] action:@selector(copyMenuEntry:) keyEquivalent:@"" atIndex:0];
		}
	}
	
	[theItem popUpStatusItemMenu:theMenu];
}

-(void)copyMenuEntry:(NSMenuItem *)test
{
	NSPasteboard *pboard=[NSPasteboard generalPasteboard];
	[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	if (![pboard setString:[test title] forType:NSStringPboardType]) {
		NSLog(@"Error");
	}
}

-(IBAction) closeApp:(id)sender {
	[NSApp terminate:self];
}

-(IBAction) about:(id)sender {
	[helpWindow fadeOut];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.sourcebricks.com/page/quickpass.html?qpabout=true"]];
}

-(IBAction) preferences:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[prefsWindow setAlphaValue:0];
	[prefsWindow makeKeyAndOrderFront:self];
	[[prefsWindow animator] setAlphaValue:1.0];
}

-(IBAction) resetChars:(id)sender {
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890#*?-_" forKey:@"validchars"];
	//[validField setStringValue:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890#*?-_"];
}
@end

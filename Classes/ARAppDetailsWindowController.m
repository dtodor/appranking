/*
 * Copyright (c) 2010 Todor Dimitrov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "ARAppDetailsWindowController.h"
#import "ARStorageManager.h"


@implementation ARAppDetailsWindowController

@synthesize application;

- (void)windowDidLoad {
	[super windowDidLoad];
	
	[self addObserver:self forKeyPath:@"application" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (!self.application) {
		ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
		self.application = [NSEntityDescription insertNewObjectForEntityForName:@"ARApplication" 
														 inManagedObjectContext:storageManager.managedObjectContext];
	}
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"application"];
	self.application = nil;
	[super dealloc];
}

- (IBAction)commitChanges:(NSButton *)sender {
	ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
	NSError *error = nil;
	if (![storageManager.managedObjectContext save:&error]) {
		NSLog(@"Unable to save app info, error = %@", [error localizedDescription]);
		[self presentError:error];
	}
	NSWindow *sheet = [self window];
	[NSApp endSheet:sheet returnCode:DidSaveChanges];
	[sheet orderOut:nil];
}

- (IBAction)discardChanges:(NSButton *)sender {
	ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
	[storageManager.managedObjectContext rollback];
	NSWindow *sheet = [self window];
	[NSApp endSheet:sheet returnCode:DidSaveChanges];
	[sheet orderOut:nil];
}

@end

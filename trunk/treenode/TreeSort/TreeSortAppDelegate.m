//
//  TreeSortAppDelegate.m
//  TreeSort
//
//  Created by Russell on 04/06/2011.
//  Copyright 2011 Jominy Research. All rights reserved.
//

#import "TreeSortAppDelegate.h"
#import "ESTreeNode.h"
#import "ESGroupNode.h"
#import "ESLeafNode.h"
#import "NSArray_Extensions.h"
#import "NSTreeController_Extensions.h"
#import "NSTreeNode_Extensions.h"
#import "NSIndexPath_Extensions.h"

NSString *ESNodeIndexPathPasteBoardType = @"ESNodeIndexPathPasteBoardType";

@implementation TreeSortAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (void)awakeFromNib;
{
	[testOutlineView registerForDraggedTypes:[NSArray arrayWithObject:ESNodeIndexPathPasteBoardType]];
}

/**
    Returns the directory the application uses to store the Core Data store file. This code uses a directory named "TreeSort" in the user's Library directory.
 */
- (NSURL *)applicationFilesDirectory {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"TreeSort"];
}


/**
    Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TreeSort" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (__persistentStoreCoordinator) {
        return __persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
        
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else {
        if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"TreeSort.storedata"];
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        [__persistentStoreCoordinator release], __persistentStoreCoordinator = nil;
        return nil;
    }

    return __persistentStoreCoordinator;
}


/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *) managedObjectContext {
    if (__managedObjectContext) {
        return __managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __managedObjectContext = [[NSManagedObjectContext alloc] init];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];

    return __managedObjectContext;
}


/**
    Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
    Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
 */
- (IBAction) saveAction:(id)sender {
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


// Both the methods below set the name of the inserted object automatically by a 'static' count variable
- (IBAction)newLeaf:(id)sender;
{
	ESLeafNode *leafNode = [NSEntityDescription insertNewObjectForEntityForName:@"Leaf" inManagedObjectContext:[self managedObjectContext]];
	static NSUInteger count = 0;
	leafNode.displayName = [NSString stringWithFormat:@"Leaf %i",++count];
	[treeController insertObject:leafNode atArrangedObjectIndexPath:[treeController indexPathForInsertion]];
}


- (IBAction)newGroup:(id)sender;
{
	ESGroupNode *groupNode = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:[self managedObjectContext]];
	static NSUInteger count = 0;
	groupNode.displayName = [NSString stringWithFormat:@"Group %i",++count];
	[treeController insertObject:groupNode atArrangedObjectIndexPath:[treeController indexPathForInsertion]];	
}


- (NSArray *)treeNodeSortDescriptors;
{
	return [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES] autorelease]];
}


// Copy and Paste

- (IBAction)copy:(id)sender
{	
    if ([[treeController selectedNodes] count] > 0 ) {
        NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
        [self writeToPasteboard:pasteBoard];
    }
}

- (IBAction)paste:(id)sender
{
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    if(![self readFromPasteboard:pasteBoard])
        NSLog(@"outlineView paste unsuccessful");
}

- (IBAction)cut:(id)sender
{
//	[outlineViewController cutItems];
}

- (IBAction)delete:(id)sender
{
//	[outlineViewController deleteItems];
}

- (void)writeToPasteboard:(NSPasteboard *)pasteBoard
{
    // Get the treeController. I know I've got a it as an outlet, but I want to make this more self-contained. Move this to
    // awakeFromNib in a viewController.
	//NSDictionary *bindingInfo = [testOutlineView infoForBinding:NSContentBinding]; 
	//NSTreeController *treeController = [bindingInfo valueForKey:NSObservedObjectKey];

    //[pasteBoard declareTypes:[NSArray arrayWithObject:ESNodeIndexPathPasteBoardType] owner:self];
    
    // The selected nodes are flattened and the selected managed objects found. The properties of each node are
    // then read into a dictionary which is inserted into an array.
    NSArray *selectedObjects = [treeController flattenedSelectedObjects];
    NSUInteger count = [selectedObjects count];
    
    if (count) {
		NSMutableArray	*copiedProperties = [NSMutableArray arrayWithCapacity:count]; 
        id treeObject;

		for (treeObject in selectedObjects ) {
            if ([treeObject respondsToSelector:@selector(dictionaryRepresentation)])
                [copiedProperties addObject:[treeObject dictionaryRepresentation]];
        }
        
//        NSLog(@"Copied dictionary array is: %@", copiedProperties);
		
		//NSData *copyData = [NSKeyedArchiver archivedDataWithRootObject:copyObjectsArray]; 
		
		//return copyData;
	}

    //[pasteBoard setData:[NSKeyedArchiver archivedDataWithRootObject:items] forType:ESNodeIndexPathPasteBoardType];
}

- (BOOL)readFromPasteboard:(NSPasteboard *)pasteBoard
{
    NSTreeNode *aNode;
    
    if([[treeController selectedNodes] count] > 0) {
		aNode = [[treeController selectedNodes] lastObject];			
		 // Paste at end of selection	
	} else {
		// Nothing selected so paste at end of all rows
		aNode = [[[treeController arrangedObjects] childNodes] lastObject];
		
	}
    return NO;
}


// undo and redo
-(BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    if ([anItem action] == @selector(undo:)) {
        return [[[self managedObjectContext] undoManager] canUndo];
    } 
    else if ([anItem action] == @selector(redo:)) {
        return [[[self managedObjectContext] undoManager] canRedo];
    }
    return YES;
}

-(IBAction)undo:sender
{
    [[[self managedObjectContext] undoManager] undo];
}


-(IBAction)redo:sender
{
    [[[self managedObjectContext] undoManager] redo];
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    // Save changes in the application's managed object context before the application terminates.

    if (!__managedObjectContext) {
        return NSTerminateNow;
    }

    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end


@implementation TreeSortAppDelegate (NSOutlineViewDragAndDrop)

// items is an array of treeNodes.[items valueForKey:@"indexPath"] is a KVC trick to produce an array of the selected managedObject indexPaths 

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteBoard;
{
	[pasteBoard declareTypes:[NSArray arrayWithObject:ESNodeIndexPathPasteBoardType] owner:self];
	[pasteBoard setData:[NSKeyedArchiver archivedDataWithRootObject:[items valueForKey:@"indexPath"]] forType:ESNodeIndexPathPasteBoardType];
	return YES;
}


- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)proposedParentItem proposedChildIndex:(NSInteger)proposedChildIndex;
{
	if (proposedChildIndex == -1) // will be -1 if the mouse is hovering over a leaf node
		return NSDragOperationNone;
    
	NSArray *draggedIndexPaths = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:ESNodeIndexPathPasteBoardType]];
	BOOL targetIsValid = YES;
	for (NSIndexPath *indexPath in draggedIndexPaths) {
		NSTreeNode *node = [treeController nodeAtIndexPath:indexPath];
		if (!node.isLeaf) {
			if ([proposedParentItem isDescendantOfNode:node] || proposedParentItem == node) { // can't drop a group on one of its descendants
				targetIsValid = NO;
				break;
			}
		}
	}
	return targetIsValid ? NSDragOperationMove : NSDragOperationNone;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)proposedParentItem childIndex:(NSInteger)proposedChildIndex;
{
	NSArray *droppedIndexPaths = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:ESNodeIndexPathPasteBoardType]];
	
	NSMutableArray *draggedNodes = [NSMutableArray array];
	for (NSIndexPath *indexPath in droppedIndexPaths)
		[draggedNodes addObject:[treeController nodeAtIndexPath:indexPath]];
    	
	NSIndexPath *proposedParentIndexPath;
	if (!proposedParentItem)
		proposedParentIndexPath = [[[NSIndexPath alloc] init] autorelease]; // makes a NSIndexPath with length == 0
	else
		proposedParentIndexPath = [proposedParentItem indexPath];
    
	[treeController moveNodes:draggedNodes toIndexPath:[proposedParentIndexPath indexPathByAddingIndex:proposedChildIndex]];
    
	return YES;
}

@end


@implementation TreeSortAppDelegate (NSOutlineViewDelegate)

// Returns a Boolean that indicates whether a given row should be drawn in the �group row� style. Off by default.
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item;
{
	if ([[(ESTreeNode *)[item representedObject] isLeaf] boolValue] || [(NSTreeNode *)item isLeaf])
		return NO;
    return [[[item representedObject] isSpecialGroup] boolValue];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item;
{
	if ([[(ESTreeNode *)[item representedObject] isLeaf] boolValue] || [(NSTreeNode *)item isLeaf])
		return NO;
	return [[[item representedObject] canCollapse] boolValue];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item;
{
	if ([[(ESTreeNode *)[item representedObject] isLeaf] boolValue] || [(NSTreeNode *)item isLeaf])
		return NO;
	return [[[item representedObject] canExpand] boolValue];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
	return [[(ESTreeNode *)[item representedObject] isSelectable] boolValue];
}


- (void)outlineViewItemDidCollapse:(NSNotification *)notification;
{
	ESGroupNode *collapsedItem = [[[notification userInfo] valueForKey:@"NSObject"] representedObject];
	collapsedItem.isExpanded = [NSNumber numberWithBool:NO];
}


- (void)outlineViewItemDidExpand:(NSNotification *)notification;
{
	ESGroupNode *expandedItem = [[[notification userInfo] valueForKey:@"NSObject"] representedObject];
	expandedItem.isExpanded = [NSNumber numberWithBool:YES];
}

@end

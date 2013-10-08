//
//  AppDelegate.m
//  dataTest
//
//  Created by mac on 12-11-30.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
#import "Post.h"
#import "Product.h"
#import "NSSQLManager.h"
//
#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;
@synthesize applicationDocumentsDirectory;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    
    [managedObjectModel release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [applicationDocumentsDirectory release];
    
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/test.db"];
    NSLog(@"%@",path);
    [[NSSQLManager shareInstance] connect:path];
    
    [Post make];
    [Product make];
    //
    Post *b = [[Post alloc] init];
    b.id =1;
    b.value=@"12345";
    //
    Product *a = [[Product alloc] init];
    a.id =1;
    a.name=@"ssssss";
    a.postId = 1;
    a.post = b;
    [a save];
    
    //
    Product *aaa = [[Product find:@"id=1"] lastObject];
    aaa.post = [[Post find:[NSString stringWithFormat:@"id=%d",aaa.postId]] lastObject];
    NSLog(@"%d,%@,%d,%@",aaa.id,aaa.name,aaa.post.id,aaa.post.value);
    //[aaa free];
    //
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

//
- (void)applicationWillTerminate:(UIApplication *)application
{
    NSError *error;
    
    if (managedObjectContext != nil) 
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) 
        {
            NSAssert(0, @"save changes failed when terminage application!");
        }
    }
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext != nil) 
    {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil) 
    {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel 
{
    if (managedObjectModel != nil) 
    {
        return managedObjectModel;
    }

    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator 
{
    if (persistentStoreCoordinator != nil)
    {
        return persistentStoreCoordinator;
    }
    
    NSError *error;
    
    NSURL *storeUrl = [NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"TestDB.sqlite"]];

    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error])
    {
        //NSAssert(0, @"persistentStoreCoordinator init failed!");
    }
    
    return persistentStoreCoordinator;
}

- (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    return basePath;
}

@end

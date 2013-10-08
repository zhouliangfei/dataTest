//
//  NSSQLManager.h
//  dataTest
//
//  Created by mac on 13-6-17.
//  Copyright (c) 2013年 383541328@qq.com All rights reserved.
//
#import <Foundation/Foundation.h>

//********************************************
#define SQLITE_ID   6
#define SQLITE_VOID 7

//********************************************
@class NSSQLTransaction;
@interface NSSQLManager : NSObject
@property(nonatomic,readonly) NSSQLTransaction *transaction;
@property(nonatomic,readonly) bool conned;
+(NSSQLManager*)shareInstance;
-(bool)connect:(NSString *)path;
-(bool)query:(NSString *)sql;
-(id)fetch:(NSString *)sql;
-(void)close;
@end

//********************************************
@interface NSSQLTransaction : NSObject
-(bool)end;
-(bool)begin;
-(bool)commit;
-(bool)rollback;
@end

//********************************************
@interface NSSQLObject : NSObject
+(id)find:(NSString *)sql;
+(bool)make;
-(bool)save;
-(bool)free;
@end

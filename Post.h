//
//  Post.h
//  dataTest
//
//  Created by mac on 13-7-1.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import "NSSQLManager.h"

@interface Post : NSSQLObject
@property(nonatomic,assign) int id;
@property(nonatomic,retain) NSString *value;
@end

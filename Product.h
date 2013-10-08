//
//  Product.h
//  dataTest
//
//  Created by mac on 13-6-24.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//
#import "Post.h"
#import "NSSQLManager.h"

@interface Product : NSSQLObject
@property(assign,nonatomic) int id;
@property(assign,nonatomic) int postId;
@property(retain,nonatomic) NSString *name;
@property(retain,nonatomic) Post *post;
@end
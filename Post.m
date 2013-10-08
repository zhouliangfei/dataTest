//
//  Post.m
//  dataTest
//
//  Created by mac on 13-7-1.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import "Post.h"

@implementation Post
@synthesize id;
@synthesize value;
-(void)dealloc{
    [value release];
    [super dealloc];
}
@end

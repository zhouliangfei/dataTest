//
//  Product.m
//  dataTest
//
//  Created by mac on 13-6-24.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import "Product.h"

@implementation Product
@synthesize id;
@synthesize postId;
@synthesize name;
@synthesize post;

-(void)dealloc{
    [post release];
    [name release];
    [super dealloc];
}
@end

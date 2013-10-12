//
//  UISwipeView.m
//  UISwipeView
//
//  Created by mac on 13-1-15.
//  Copyright (c) 2013年 383541328@qq.com All rights reserved.
//

#import "UISwipeView.h"
#import <QuartzCore/QuartzCore.h>
//..........................................UISwipeViewCell......................................
@implementation UISwipeViewCell
@synthesize reuseIdentifier = identifier;
-(id)initWithReuseIdentifier:(NSString*)reuseIdentifier{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        identifier = [reuseIdentifier retain];
    }
    return self;
}
-(void)dealloc{
    [identifier release];
    [super dealloc];
}
@end

//............................................UISwipeView......................................
@implementation UISwipeView
@synthesize dataSource;
@synthesize delegate;
@synthesize orientation;
@synthesize currentIndex;
@synthesize alwaysBounce;
@synthesize perspective;
@synthesize clearance;
@synthesize angle;
@synthesize scale;
-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        scale = 1.f;
        cellSize = frame.size;
        perspective = -1.f / 400.f;
        alwaysBounce = YES;
        //
        positionCells = [[NSMutableArray alloc] init];
        visiableCells = [[NSMutableDictionary alloc] init];
        reusableTableCells = [[NSMutableArray alloc] init];
        //
        contentView = [[UIScrollView alloc] initWithFrame:self.bounds];
        [contentView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [contentView setDecelerationRate:UIScrollViewDecelerationRateFast];
        [contentView setShowsHorizontalScrollIndicator:NO];
        [contentView setShowsVerticalScrollIndicator:NO];
        [contentView setDelegate:self];
        [self addSubview:contentView];
    }
    return self;
}
-(void)dealloc{
    [reusableTableCells release];
    [visiableCells release];
    [positionCells release];
    [contentView release];
    [super dealloc];
}
-(void)layoutSubviews{
    [self scrollViewDidScroll:contentView];
}
-(void)reloadData{
    if (numberOfCell>0) {
        numberOfCell = 0;
        for (UISwipeViewCell *layer in contentView.subviews){
            if ([layer isKindOfClass:[UISwipeViewCell class]]) {
                [layer removeFromSuperview];
            }
        }
        //
        [positionCells removeAllObjects];
        [visiableCells removeAllObjects];
        [reusableTableCells removeAllObjects];
        [self scrollViewDidScroll:contentView];
    }
}
-(void)setCurrentIndex:(NSInteger)value{
    currentIndex = value;
    if (numberOfCell>0) {
        if (UISwipeOrientationLandscape == orientation) {
            [contentView setContentOffset:CGPointMake(currentIndex*(cellSize.width+clearance), 0)];
        }else{
            [contentView setContentOffset:CGPointMake(0, currentIndex*(cellSize.height+clearance))];
        }
    }
}
//
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (numberOfCell==0) {
        numberOfCell = [dataSource numberOfInSwipeView:self];
        if ([delegate performSelector:@selector(sizeOfInSwipeView:)]) {
            cellSize = [delegate sizeOfInSwipeView:self];
        }
        //
        if (UISwipeOrientationLandscape == orientation) {
            float border = (self.frame.size.width-cellSize.width) / 2.f;
            float magin = (self.frame.size.height-cellSize.height) / 2.f;
            float offset = border;
            for (uint i=0; i<numberOfCell; i++) {
                CGRect frame = CGRectMake(offset, magin, cellSize.width, cellSize.height);
                [positionCells addObject:[NSValue valueWithCGRect:frame]];
                offset += frame.size.width + clearance;
            }
            [contentView setAlwaysBounceVertical:NO];
            [contentView setAlwaysBounceHorizontal:alwaysBounce];
            [contentView setContentSize:CGSizeMake(border+offset-clearance ,self.frame.size.height)];
        }else{
            float border = (self.frame.size.height-cellSize.height) / 2.f;
            float magin = (self.frame.size.width-cellSize.width) / 2.f;
            float offset = border;
            for (uint i=0; i<numberOfCell; i++) {
                CGRect frame = CGRectMake(magin, offset, cellSize.width, cellSize.height);
                [positionCells addObject:[NSValue valueWithCGRect:frame]];
                offset += frame.size.height + clearance;
            }
            [contentView setAlwaysBounceVertical:alwaysBounce];
            [contentView setAlwaysBounceHorizontal:NO];
            [contentView setContentSize:CGSizeMake(self.frame.size.width, border+offset-clearance)];
        }
        if (currentIndex>0) {
            [self setCurrentIndex:MIN(currentIndex, numberOfCell-1)];
        }
    }
    //
    if (numberOfCell>0) {
        //可见区
        NSMutableSet *visibleIndices = [NSMutableSet set];
        for (int j=0;j<numberOfCell;j++){
            CGRect frame = [[positionCells objectAtIndex:j] CGRectValue];
            if ((CGRectContainsRect(frame, contentView.bounds) || CGRectIntersectsRect(frame, contentView.bounds))){
                [visibleIndices addObject:[NSNumber numberWithInteger:j]];
            }
        }
        //无效cell
        for (NSNumber *key in [visiableCells allKeys]){
            if (NO == [visibleIndices containsObject:key]){
                UIView *cell = [visiableCells objectForKey:key];
                [reusableTableCells addObject:cell];
                [visiableCells removeObjectForKey:key];
                [cell removeFromSuperview];
            }
        }
        //生成有效cell
        for (NSNumber *key in visibleIndices){
            UIView *cell = [visiableCells objectForKey:key];
            if (cell == nil){
                cell = [dataSource swipeView:self cellAtIndex:[key intValue]];
                if (cell){
                    [contentView addSubview:cell];
                    [visiableCells setObject:cell forKey:key];
                    [reusableTableCells removeObject:cell];
                }
            }
            if (cell) {
                CGRect frame = [[positionCells objectAtIndex:[key intValue]] CGRectValue];
                [cell setFrame:frame];
            }
        }
        //展示效果
        [self transformVisibleCells:visiableCells];
    }
    if ([delegate respondsToSelector:@selector(swipeViewDidScroll:)]) {
        [delegate swipeViewDidScroll:self];
    }
}
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (UISwipeOrientationLandscape == orientation) {
        if (velocity.x == 0) {
            NSInteger index = nearbyintf(targetContentOffset->x / (cellSize.width + clearance));
            NSInteger value = MIN(MAX(0, index), numberOfCell-1);
            targetContentOffset->x = value * (cellSize.width + clearance);
        } else {
            CGFloat t = fabsf(velocity.x / (1.0-contentView.decelerationRate));
            CGFloat d = velocity.x * t;
            //
            NSInteger index = nearbyintf((targetContentOffset->x+d) / (cellSize.width + clearance));
            currentIndex = MIN(MAX(0, index), numberOfCell-1);
            targetContentOffset->x = currentIndex * (cellSize.width + clearance);
        }
    }else{
        if (velocity.y == 0) {
            NSInteger index = nearbyintf(targetContentOffset->y / (cellSize.height + clearance));
            NSInteger value = MIN(MAX(0, index), numberOfCell-1);
            targetContentOffset->y = value * (cellSize.height + clearance);
        } else {
            CGFloat t = fabsf(velocity.y / (1.0-contentView.decelerationRate));
            CGFloat d = velocity.y * t;
            //
            NSInteger index = nearbyintf((targetContentOffset->y+d) / (cellSize.height + clearance));
            currentIndex = MIN(MAX(0, index), numberOfCell-1);
            targetContentOffset->y = currentIndex * (cellSize.height + clearance);
        }
    }
}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if ([delegate respondsToSelector:@selector(swipeViewDidBeginScroll:)]) {
        [delegate swipeViewDidBeginScroll:self];
    }
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if ([delegate respondsToSelector:@selector(swipeViewDidEndScroll:)]) {
        [delegate swipeViewDidEndScroll:self];
    }
}
//
-(UISwipeViewCell*)dequeueReusableCellWithIdentifier:(NSString*)identifier{
    for (UISwipeViewCell *cell in reusableTableCells){
        if ([identifier isEqualToString:cell.reuseIdentifier]){
            return cell;
        }
    }
    return nil;
}
-(UISwipeViewCell*)cellForIndex:(NSInteger)index{
    for (NSNumber *key in [visiableCells allKeys]){
        if ([key intValue]==index){
            return [visiableCells objectForKey:key];
        }
    }
    return nil;
}
-(NSInteger)indexForCell:(UISwipeViewCell*)cell{
    for (NSNumber *key in [visiableCells allKeys]){
        if ([visiableCells objectForKey:key]==cell){
            return [key integerValue];
        }
    }
    return NSNotFound;
}
//效果
-(void)transformVisibleCells:(NSDictionary*)value{
    if (angle != 0 || scale != 1) {
        if (UISwipeOrientationLandscape == orientation) {
            CGFloat bcx = CGRectGetMidX(contentView.bounds);
            CGFloat bsw = cellSize.width + clearance;
            for (UIView *cell in value.allValues){
                CGFloat distance = bcx - cell.center.x;
                if (distance < -bsw) {
                    distance = -bsw;
                }
                if (distance > bsw) {
                    distance = bsw;
                }
                if (distance == 0.0) {
                    cell.layer.transform = [self transform3DWithRotationAxis:false angle:0 scale:1 perspective:perspective];
                    cell.layer.zPosition = INT_MAX;
                }else{
                    CGFloat percentage = distance / bsw;
                    CGFloat angleVal = angle * percentage;
                    CGFloat scaleVal = scale + (1.0-scale) * (1.0-fabsf(percentage));
                    cell.layer.transform = [self transform3DWithRotationAxis:false angle:angleVal scale:scaleVal perspective:perspective];
                    cell.layer.zPosition = scaleVal * INT_MAX;
                }
            }
        }else{
            CGFloat bcy = CGRectGetMidY(contentView.bounds);
            CGFloat bsh = cellSize.height + clearance;
            for (UIView *cell in value.allValues){
                CGFloat distance = cell.center.y - bcy;
                if (distance < -bsh) {
                    distance = -bsh;
                }
                if (distance > bsh) {
                    distance = bsh;
                }
                if (distance == 0.0) {
                    cell.layer.transform = [self transform3DWithRotationAxis:true angle:0 scale:1 perspective:perspective];
                    cell.layer.zPosition = INT_MAX;
                }else{
                    CGFloat percentage = distance / bsh;
                    CGFloat angleVal = angle * percentage;
                    CGFloat scaleVal = scale + (1.0-scale) * (1.0-fabsf(percentage));
                    cell.layer.transform = [self transform3DWithRotationAxis:true angle:angleVal scale:scaleVal perspective:perspective];
                    cell.layer.zPosition = scaleVal * INT_MAX;
                }
            }
        }
    }
}
-(CATransform3D)transform3DWithRotationAxis:(bool)axis angle:(CGFloat)angleVal scale:(CGFloat)scaleVal perspective:(CGFloat)perspectiveVal {
    CATransform3D rotateTransform = CATransform3DIdentity;
    rotateTransform.m34 = perspectiveVal;
    if (axis) {
        rotateTransform = CATransform3DRotate(rotateTransform, angleVal*M_PI_2/180.0, 1.0, 0.0, 0.0);
    }else{
        rotateTransform = CATransform3DRotate(rotateTransform, angleVal*M_PI_2/180.0, 0.0, 1.0, 0.0);
    }
    //
    CATransform3D scaleTransform = CATransform3DIdentity;
    scaleTransform = CATransform3DScale(scaleTransform, scaleVal, scaleVal, 1.0);
    //
    return CATransform3DConcat(rotateTransform, scaleTransform);
}
@end

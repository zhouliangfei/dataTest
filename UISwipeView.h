//
//  UISwipeView.h
//  UISwipeView
//
//  Created by mac on 13-1-15.
//  Copyright (c) 2013年 383541328@qq.com All rights reserved.
//
/*
 
 UISwipeView *swipe = [[UISwipeView alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
 [swipe setDataSource:self];
 [swipe setDelegate:self];
 [swipe setCellAngle:45];
 [swipe setCellScale:2];
 [swipe setCellIndex:1];
 [swipe setCellSize:CGSizeMake(300, 200)];
 [swipe setBackgroundColor:[UIColor blackColor]];
 [self addSubview:swipe];
 
 //
 -(NSInteger)numberOfCellInSwipeView:(UISwipeView *)swipeView{
    return 10;
 }
 -(UISwipeViewCell *)swipeView:(UISwipeView *)swipeView cellAtIndex:(NSInteger)index{
 static NSString *productAlbumView = @"productAlbumView";
 UISwipeViewCell *cell = [swipeView dequeueReusableCellWithIdentifier:productAlbumView];
 if (nil == cell){
 cell = [[[UISwipeViewCell alloc] initWithReuseIdentifier:productAlbumView] autorelease];
 }
 [cell setBackgroundColor:[UIColor colorWithRed:(float)index/10.0 green:(float)(10-index)/10.0 blue:1 alpha:1]];
 return cell;
 }
 */
#import <UIKit/UIKit.h>

enum {
    UISwipeOrientationLandscape,
    UISwipeOrientationPortrait
};
typedef NSInteger UISwipeOrientation;

//代理............................................
@class UISwipeView;
@class UISwipeViewCell;
@protocol UISwipeViewDataSource<NSObject>
@required
-(NSInteger)numberOfInSwipeView:(UISwipeView *)swipeView;
-(UISwipeViewCell*)swipeView:(UISwipeView *)swipeView cellAtIndex:(NSInteger)index;
@end

@protocol UISwipeViewDelegate<NSObject>
@optional
-(CGSize)sizeOfInSwipeView:(UISwipeView *)swipeView;
-(void)swipeViewDidBeginScroll:(UISwipeView *)swipeView;
-(void)swipeViewDidScroll:(UISwipeView *)swipeView;
-(void)swipeViewDidEndScroll:(UISwipeView *)swipeView;
@end

//cell............................................
@interface UISwipeViewCell : UIView
@property(nonatomic,readonly) NSString *reuseIdentifier;
-(id)initWithReuseIdentifier:(NSString*)reuseIdentifier;
@end

//............................................
@interface UISwipeView : UIView<UIScrollViewDelegate>{
    CGSize cellSize;
    NSInteger numberOfCell;
    UIScrollView *contentView;
    NSMutableArray *positionCells;
    NSMutableArray *reusableTableCells;
    NSMutableDictionary *visiableCells;
}
@property(nonatomic,assign) id <UISwipeViewDataSource> dataSource;
@property(nonatomic,assign) id <UISwipeViewDelegate> delegate;
@property(nonatomic,assign) UISwipeOrientation orientation;
@property(nonatomic,assign) NSInteger currentIndex;
@property(nonatomic,assign) Boolean alwaysBounce;
@property(nonatomic,assign) CGFloat perspective;
@property(nonatomic,assign) CGFloat clearance;
@property(nonatomic,assign) CGFloat angle;
@property(nonatomic,assign) CGFloat scale;
//
-(UISwipeViewCell*)dequeueReusableCellWithIdentifier:(NSString*)identifier;
-(UISwipeViewCell*)cellForIndex:(NSInteger)index;
-(NSInteger)indexForCell:(UISwipeViewCell*)cell;
-(void)reloadData;
@end

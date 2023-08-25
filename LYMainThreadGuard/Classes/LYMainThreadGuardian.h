//
//  LYMainThreadGuardian.h
//  AAILiveness
//
//  Created by yanyuzhu on 2023/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LYMainThreadGuardianReportDelegate <NSObject>
- (void)didDetectNonMainThreadCall;
- (void)pushViewControllerOnNoneMainThread:(UIViewController *)viewController;

@end

@interface LYMainThreadGuardian : NSObject
@property (nonatomic, readwrite, assign) BOOL isEnabled;
@property (nonatomic, weak) id<LYMainThreadGuardianReportDelegate> delegate;

+ (BOOL)isEnabled;
+ (void)setIsEnabled:(BOOL)isEnabled;
+ (LYMainThreadGuardian *)sharedInstance;

@end

NS_ASSUME_NONNULL_END

//
//  LYMainThreadGuardian.m
//
//  Created by yanyuzhu on 2023/8/25.
//

#import "LYMainThreadGuardian.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString * const kLYMainThreadGuardianEnabledKey = @"kLYMainThreadGuardianEnabledKey";

@implementation LYMainThreadGuardian

+ (instancetype)sharedInstance {
  static LYMainThreadGuardian *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[LYMainThreadGuardian alloc] init];
  });
  return sharedInstance;
}

+ (BOOL)isEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:kLYMainThreadGuardianEnabledKey];
}

+ (void)setIsEnabled:(BOOL)isEnabled {
  [[NSUserDefaults standardUserDefaults] setBool:isEnabled forKey:kLYMainThreadGuardianEnabledKey];
  if (isEnabled) {
    
  }
}

+ (void)setupMainThreadGuardianHooks {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Swizzle any classes that implement one of these selectors.
    const SEL viewSelectors[] = {
      @selector(setNeedsLayout),
      @selector(layoutIfNeeded),
      @selector(setNeedsDisplay),
      @selector(layoutSubviews),
    };
//    const SEL navSelectors[] = {
//      @selector(pushViewController:animated:),
//      @selector(popoverPresentationController)
//    };
//    const SEL tableViewSelectors[] = {
//      @selector(reloadData)
//    };
//    const SEL collectionViewSelectors[] = {
//      @selector(reloadData)
//    };
    typedef void (^LYMainThreadGuardianVoidBlock)(id slf);

    for (int selectorIndex = 0; selectorIndex < sizeof(viewSelectors) / sizeof(SEL); ++selectorIndex) {
      SEL selector = viewSelectors[selectorIndex];
      SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
      LYMainThreadGuardianVoidBlock voidBlock = ^(id slf){
        if ([self isEnabled] && ![NSThread currentThread].isMainThread){
          [[LYMainThreadGuardian sharedInstance].delegate didDetectRefreshUIOnNonMainThreadCall];
        }
        ((void(*)(id, SEL))objc_msgSend)(
            slf, swizzledSelector
        );
      };
      [self replaceImplementationOfKnownSelector:selector onClass:[UIView class] withBlock:voidBlock swizzledSelector:swizzledSelector];
    }
    
    SEL navPushSelector = @selector(pushViewController:animated:);
    SEL navPushSwizzledSelector = [self swizzledSelectorForSelector:navPushSelector];
    typedef void (^LYPushVCImpBlock)(id slf, UIViewController *viewController, BOOL animated);
    
    LYPushVCImpBlock navPushSwizzledImpBlock = ^(id slf, UIViewController *viewController, BOOL animated) {
      if ([self isEnabled] && ![NSThread currentThread].isMainThread){
        [[LYMainThreadGuardian sharedInstance].delegate didDetectRefreshUIOnNonMainThreadCall];
        [[LYMainThreadGuardian sharedInstance].delegate pushViewControllerOnNoneMainThread:viewController];
      }
      ((void(*)(id, SEL, UIViewController*, BOOL))objc_msgSend)(
          slf, navPushSwizzledSelector, viewController, animated
      );
    };
    [self replaceImplementationOfKnownSelector:navPushSelector onClass:[UINavigationController class] withBlock:navPushSwizzledImpBlock swizzledSelector:navPushSwizzledSelector];
    
    SEL navPopSelector = @selector(popViewControllerAnimated:);
    SEL navPopSwizzledSelector = [self swizzledSelectorForSelector:navPopSelector];
    typedef UIViewController * (^LYPopVCImpBlock)(id slf, BOOL animated);
    LYPopVCImpBlock popImplBlock = ^UIViewController *(id slf, BOOL animated){
      UIViewController *returnValue = ((id(*)(id, SEL, BOOL))objc_msgSend)(
          slf, navPopSwizzledSelector, animated
      );
      if ([self isEnabled] && ![NSThread currentThread].isMainThread){
        [[LYMainThreadGuardian sharedInstance].delegate didDetectRefreshUIOnNonMainThreadCall];
        [[LYMainThreadGuardian sharedInstance].delegate popUpViewControllerOnNoneMainThread:returnValue];
      }
      return returnValue;
    };
    [self replaceImplementationOfKnownSelector:navPopSelector onClass:[UINavigationController class] withBlock:popImplBlock swizzledSelector:navPopSwizzledSelector];
    
    SEL tbReloadDataSelector = @selector(reloadData);
    SEL swizzle_tbReloadDataSelector = [self swizzledSelectorForSelector:tbReloadDataSelector];
    LYMainThreadGuardianVoidBlock tbReloadImpBlock = ^(id slf){
      if ([self isEnabled] && ![NSThread currentThread].isMainThread){
        [[LYMainThreadGuardian sharedInstance].delegate didDetectRefreshUIOnNonMainThreadCall];
      }
      ((void(*)(id, SEL))objc_msgSend)(
          slf, swizzle_tbReloadDataSelector
      );
    };
    [self replaceImplementationOfKnownSelector:tbReloadDataSelector onClass:[UITableView class] withBlock:tbReloadImpBlock swizzledSelector:swizzle_tbReloadDataSelector];
    
    SEL collectionReloadDataSelector = @selector(reloadData);
    SEL swizzle_collectionReloadDataSelector = [self swizzledSelectorForSelector:collectionReloadDataSelector];
    LYMainThreadGuardianVoidBlock collectionReloadImpBlock = ^(id slf){
      if ([self isEnabled] && ![NSThread currentThread].isMainThread){
        [[LYMainThreadGuardian sharedInstance].delegate didDetectRefreshUIOnNonMainThreadCall];
      }
      ((void(*)(id, SEL))objc_msgSend)(
          slf, swizzle_collectionReloadDataSelector
      );
    };
    [self replaceImplementationOfKnownSelector:collectionReloadDataSelector onClass:[UICollectionView class] withBlock:collectionReloadImpBlock swizzledSelector:swizzle_collectionReloadDataSelector];
  });
}

+ (void)load {
    // replace method
    
  dispatch_async(dispatch_get_main_queue(), ^{
      if ([self isEnabled]) {
        [self setupMainThreadGuardianHooks];
      }
  });
  
}

// 随机生成交换selector的名称
+ (SEL)swizzledSelectorForSelector:(SEL)selector {
    return NSSelectorFromString([NSString stringWithFormat:
        @"_mtguard_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)
    ]);
}


+ (void)replaceImplementationOfKnownSelector:(SEL)originalSelector
                                     onClass:(Class)class
                                   withBlock:(id)block
                            swizzledSelector:(SEL)swizzledSelector {
    // This method is only intended for swizzling methods that are know to exist on the class.
    // Bail if that isn't the case.
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    if (!originalMethod) {
        return;
    }
    
    IMP implementation = imp_implementationWithBlock(block);
    class_addMethod(class, swizzledSelector, implementation, method_getTypeEncoding(originalMethod));
    Method newMethod = class_getInstanceMethod(class, swizzledSelector);
    method_exchangeImplementations(originalMethod, newMethod);
}

static void replace(Class cls, NSString *selectorName)
{
    SEL selector = NSSelectorFromString(selectorName);
    
    Method method = class_getInstanceMethod(cls, selector);
    const char *typeDescription = (char *)method_getTypeEncoding(method);
    
    IMP originalImp = class_getMethodImplementation(cls, selector);
    IMP msgForwardIMP = _objc_msgForward;
    
    class_replaceMethod(cls, selector, msgForwardIMP, typeDescription);
    
    if (class_getMethodImplementation(cls, @selector(forwardInvocation:)) != (IMP)myForwardInvocation)
    {
        class_replaceMethod(cls, @selector(forwardInvocation:), (IMP)myForwardInvocation, typeDescription);
    }
    
    if (class_respondsToSelector(cls, selector))
    {
        NSString *originalSelectorName = [NSString stringWithFormat:@"ORIG_%@", selectorName];
        SEL originalSelector = NSSelectorFromString(originalSelectorName);
        if(!class_respondsToSelector(cls, originalSelector))
        {
            class_addMethod(cls, originalSelector, originalImp, typeDescription);
        }
    }
}

static void myForwardInvocation(id slf, SEL selector, NSInvocation *invocation)
{
    if (![NSThread currentThread].isMainThread)
    {
        NSLog(@"%@",[NSThread callStackSymbols]);
//
//        NSMutableArray *array = [NSMutableArray array];
//        [array addObject:nil];
    }
    
    NSString *selectorName = NSStringFromSelector(invocation.selector);
    NSString *origSelectorName = [NSString stringWithFormat:@"ORIG_%@", selectorName];
    SEL origSelector = NSSelectorFromString(origSelectorName);
    
    invocation.selector = origSelector;
    [invocation invoke];
}

+ (void)replaceImplementationOfSelector:(SEL)selector
                           withSelector:(SEL)swizzledSelector
                               forClass:(Class)cls
                  withMethodDescription:(struct objc_method_description)methodDescription
                    implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock {
    if ([self instanceRespondsButDoesNotImplementSelector:selector class:cls]) {
        return;
    }
    
    IMP implementation = imp_implementationWithBlock((id)(
        [cls instancesRespondToSelector:selector] ? implementationBlock : undefinedBlock)
    );
    
    Method oldMethod = class_getInstanceMethod(cls, selector);
    const char *types = methodDescription.types;
    if (oldMethod) {
        if (!types) {
            types = method_getTypeEncoding(oldMethod);
        }

        class_addMethod(cls, swizzledSelector, implementation, types);
        Method newMethod = class_getInstanceMethod(cls, swizzledSelector);
        method_exchangeImplementations(oldMethod, newMethod);
    } else {
        if (!types) {
            // Some protocol method descriptions don't have .types populated
            // Set the return type to void and ignore arguments
            types = "v@:";
        }
        class_addMethod(cls, selector, implementation, types);
    }
}

+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls {
  if ([cls instancesRespondToSelector:selector]) {
    unsigned int numMethods = 0;
    Method *methods = class_copyMethodList(cls, &numMethods);
    BOOL implementsSelector = NO;
      for (int index = 0; index < numMethods; index++) {
          SEL methodSelector = method_getName(methods[index]);
          if (selector == methodSelector) {
              implementsSelector = YES;
              break;
          }
      }
      
      free(methods);
      
      if (!implementsSelector) {
          return YES;
      }
  }
  return NO;
}
@end

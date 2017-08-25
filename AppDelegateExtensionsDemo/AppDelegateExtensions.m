//
//  AppDelegateExtensions.m
//  AppDelegateExtensionsDemo
//
//  Created by 苏合 on 2017/8/21.
//  Copyright © 2017年 AppDelegateExtensions. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AppDelegateExtensions.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSNotificationName const UIApplicationWillFinishLaunchingNotification = @"UIApplicationWillFinishLaunchingNotification";
NSNotificationName const UIApplicationDidRegisterUserNotificationSettingsNotification = @"UIApplicationDidRegisterUserNotificationSettingsNotification";
NSNotificationName const UIApplicationDidRegisterForRemoteNotificationsNotification = @"UIApplicationDidRegisterForRemoteNotificationsNotification";
NSNotificationName const UIApplicationDidFailToRegisterForRemoteNotificationsNotification = @"UIApplicationDidFailToRegisterForRemoteNotificationsNotification";
NSNotificationName const UIApplicationDidReceiveRemoteNotification = @"UIApplicationDidReceiveRemoteNotification";
NSNotificationName const UIApplicationDidReceiveRemoteWithFetchCompletionHandlerNotification = @"UIApplicationDidReceiveRemoteWithFetchCompletionHandlerNotification";
NSNotificationName const UIApplicationDidReceiveLocalNotification = @"UIApplicationDidReceiveLocalNotification";
NSNotificationName const UIApplicationHandleOpenURLNotification = @"UIApplicationHandleOpenURLNotification";
NSNotificationName const UIApplicationOpenURLWithSourceApplicationNotification = @"UIApplicationOpenURLWithSourceApplicationNotification";
NSNotificationName const UIApplicationOpenURLWithOptionsNotification = @"UIApplicationOpenURLWithOptionsNotification";
NSNotificationName const UIApplicationContinueUserActivityNotification = @"UIApplicationContinueUserActivityNotification";
NSNotificationName const UIApplicationPerformActionForShortcutItemNotification = @"UIApplicationPerformActionForShortcutItemNotification";
NSNotificationName const UIApplicationHandleWatchKitExtensionRequestNotification = @"UIApplicationHandleWatchKitExtensionRequestNotification";

NSString *const UIApplicationUserNotificationSettingsKey = @"UIApplicationUserNotificationSettingsKey";
NSString *const UIApplicationDeviceTokenKey = @"UIApplicationDeviceTokenKey";
NSString *const UIApplicationErrorKey = @"UIApplicationErrorKey";
NSString *const UIApplicationLocalNotificationKey = @"UIApplicationLocalNotificationKey";
NSString *const UIApplicationURLOptionsKey = @"UIApplicationURLOptionsKey";
UIApplicationOpenURLOptionsKey const UIApplicationOpenURLOptionsURLKey = @"UIApplicationOpenURLOptionsURLKey";
NSString *const UIApplicationContinueUserActivityKey = @"UIApplicationContinueUserActivityKey";
NSString *const UIApplicationRestorationHandlerKey = @"UIApplicationRestorationHandlerKey";
NSString *const UIApplicationShortcutItemKey = @"UIApplicationShortcutItemKey";
NSString *const UIApplicationCompletionHandlerKey = @"UIApplicationCompletionHandlerKey";
NSString *const UIApplicationWatchKitExtensionRequestUserInfoKey = @"UIApplicationWatchKitExtensionRequestUserInfoKey";
NSString *const UIApplicationWatchKitExtensionReplyKey = @"UIApplicationWatchKitExtensionReplyKey";
NSString *const UIApplicationRemoteNoficationUserInfoKey = @"UIApplicationRemoteNoficationUserInfoKey";
NSString *const UIApplicationFetchCompletionHandlerKey = @"UIApplicationFetchCompletionHandlerKey";

static inline BOOL isValidIMP(IMP impl)
{
#if defined(__arm64__)
    if (impl == NULL || impl == _objc_msgForward) return NO;
#else
    if (impl == NULL || impl == _objc_msgForward || impl == (IMP)_objc_msgForward_stret) return NO;
#endif
    return YES;
}

static BOOL addMethodWithIMP(Class cls, SEL oldSel, SEL newSel, IMP newIMP, const char *types, BOOL aggressive)
{
    if (!class_addMethod(cls, oldSel, newIMP, types))
    {
        return NO;
    }
    
    IMP parentIMP = NULL;
    Class superclass = class_getSuperclass(cls);
    while (superclass && !isValidIMP(parentIMP))
    {
        parentIMP = class_getMethodImplementation(superclass, oldSel);
        if (isValidIMP(parentIMP))
        {
            break;
        }
        else
        {
            parentIMP = NULL;
        }
        
        superclass = class_getSuperclass(superclass);
    }
    
    if (parentIMP)
    {
        if (aggressive)
        {
            return class_addMethod(cls, newSel, parentIMP, types);
        }
        
        class_replaceMethod(cls, newSel, newIMP, types);
        class_replaceMethod(cls, oldSel, parentIMP, types);
    }
    
    return YES;
}

static BOOL swizzleWithIMP(Class cls, SEL oldSel, SEL newSel, IMP newIMP, const char *types, BOOL aggressive)
{
    Method origMethod = class_getInstanceMethod(cls, oldSel);
    
    BOOL ret = class_addMethod(cls, newSel, newIMP, types);
    Method newMethod = class_getInstanceMethod(cls, newSel);
    method_exchangeImplementations(origMethod, newMethod);
    return ret;
}

static SEL selectorWithPattern(const char *prefix, const char *key, const char *suffix)
{
    size_t prefixLength = prefix ? strlen(prefix) : 0;
    size_t suffixLength = suffix ? strlen(suffix) : 0;
    
    char initial = key[0];
    if (prefixLength) initial = (char)toupper(initial);
    size_t initialLength = 1;
    
    const char *rest = key + initialLength;
    size_t restLength = strlen(rest);
    
    char selector[prefixLength + initialLength + restLength + suffixLength + 1];
    memcpy(selector, prefix, prefixLength);
    selector[prefixLength] = initial;
    memcpy(selector + prefixLength + initialLength, rest, restLength);
    memcpy(selector + prefixLength + initialLength + restLength, suffix, suffixLength);
    selector[prefixLength + initialLength + restLength + suffixLength] = '\0';
    
    return sel_registerName(selector);
}

static inline SEL prefixedSelector(SEL original) {
    return selectorWithPattern("adext_", sel_getName(original), NULL);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@implementation NSDictionary (AppDelegateExtensions)

+ (NSDictionary<NSNotificationName, NSString *> *)adext_selectors
{
    NSDictionary<NSNotificationName, NSString *> *selectors =
    @{
      UIApplicationWillFinishLaunchingNotification : NSStringFromSelector(@selector(application:willFinishLaunchingWithOptions:)),
      UIApplicationDidRegisterUserNotificationSettingsNotification : NSStringFromSelector(@selector(application:didRegisterUserNotificationSettings:)),
      UIApplicationDidRegisterForRemoteNotificationsNotification : NSStringFromSelector(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)),
      UIApplicationDidFailToRegisterForRemoteNotificationsNotification : NSStringFromSelector(@selector(application:didFailToRegisterForRemoteNotificationsWithError:)),
      UIApplicationDidReceiveRemoteNotification : NSStringFromSelector(@selector(application:didReceiveRemoteNotification:)),
      UIApplicationDidReceiveRemoteWithFetchCompletionHandlerNotification : NSStringFromSelector(@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)),
      UIApplicationDidReceiveLocalNotification : NSStringFromSelector(@selector(application:didReceiveLocalNotification:)),
      UIApplicationHandleOpenURLNotification : NSStringFromSelector(@selector(application:handleOpenURL:)),
      UIApplicationOpenURLWithSourceApplicationNotification : NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:)),
      UIApplicationOpenURLWithOptionsNotification : NSStringFromSelector(@selector(application:openURL:options:)),
      UIApplicationContinueUserActivityNotification : NSStringFromSelector(@selector(application:continueUserActivity:restorationHandler:)),
      UIApplicationPerformActionForShortcutItemNotification : NSStringFromSelector(@selector(application:performActionForShortcutItem:completionHandler:)),
      UIApplicationHandleWatchKitExtensionRequestNotification : NSStringFromSelector(@selector(application:handleWatchKitExtensionRequest:reply:)),
      };
    return selectors;
}

@end


@implementation NSInvocation (AppDelegateExtensions)

+ (NSInvocation *)adext_invocationWithNotificationName:(NSNotificationName)notificationName clazz:(Class)clazz target:(id)target
{
    SEL originalSelector = NSSelectorFromString([NSDictionary adext_selectors][notificationName]);
    SEL swizzledSelector = prefixedSelector(originalSelector);
    NSMethodSignature  *signature = [clazz instanceMethodSignatureForSelector:originalSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = swizzledSelector;
    return invocation;
}

- (id)adext_returnValueWithAddResult:(BOOL)addResult
{
    id returnValue;
    const char *returnType = self.methodSignature.methodReturnType;
    if (!addResult)
    {
        [self invoke];
        if( !strcmp(returnType, @encode(void)))
        {
            returnValue =  nil;
        }
        else if( !strcmp(returnType, @encode(id)))
        {
            [self getReturnValue:&returnValue];
        }
        else
        {
            NSUInteger length = [self.methodSignature methodReturnLength];
            void *buffer = (void *)malloc(length);
            [self getReturnValue:buffer];
            returnValue = [NSValue valueWithBytes:buffer objCType:returnType];
        }
    }
    else
    {
        if( !strcmp(returnType, @encode(BOOL)) )
        {
            returnValue = [NSValue valueWithBytes:"\1" objCType:returnType];
        }
        else
        {
            returnValue =  nil;
        }
    }
    return returnValue;
}

@end

typedef void (^ADEXTPostNotificationBlock)(NSObject *self, va_list arguments);

@interface AppDelegateExtension : NSObject

@property (nonatomic, assign) BOOL addSucceed;

@end

@implementation AppDelegateExtension

+ (NSMutableDictionary<NSNotificationName, AppDelegateExtension *> *)extensions
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary *extensions;
    dispatch_once(&onceToken, ^{
        extensions = [NSMutableDictionary dictionary];
    });
    return extensions;
}

+ (AppDelegateExtension *)installWithNotificationName:(NSNotificationName)notificationName clazz:(Class)clazz block:(id)block
{
    AppDelegateExtension *extension = [AppDelegateExtension new];
    SEL originalSelector = NSSelectorFromString([NSDictionary adext_selectors][notificationName]);
    SEL swizzledSelector = prefixedSelector(originalSelector);
    
    IMP swizzledImplementation = imp_implementationWithBlock(block);
    extension.addSucceed = addMethodWithIMP(clazz, originalSelector, swizzledSelector, swizzledImplementation, "v@:@", YES);
    if (!extension.addSucceed)
    {
        swizzleWithIMP(clazz, originalSelector, swizzledSelector, swizzledImplementation, "v@:@", YES);
    }
    [[self.class extensions] setObject:extension forKey:notificationName];
    return extension;
}

@end



void installAppDelegateExtensionsWithClass(Class clazz)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            [AppDelegateExtension installWithNotificationName:UIApplicationWillFinishLaunchingNotification clazz:clazz block:^BOOL(NSObject *self, id application, id options) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationWillFinishLaunchingNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&options atIndex:3];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationWillFinishLaunchingNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillFinishLaunchingNotification object:application userInfo:options];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationWillFinishLaunchingNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationDidRegisterUserNotificationSettingsNotification clazz:clazz block:^BOOL(NSObject *self, id application, id settings) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationDidRegisterUserNotificationSettingsNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&settings atIndex:3];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationDidRegisterUserNotificationSettingsNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidRegisterUserNotificationSettingsNotification object:application userInfo:settings ? @{UIApplicationUserNotificationSettingsKey : settings} : nil];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationDidRegisterUserNotificationSettingsNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationDidRegisterForRemoteNotificationsNotification clazz:clazz block:^BOOL(NSObject *self, id application, id deviceToken) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationDidRegisterForRemoteNotificationsNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&deviceToken atIndex:3];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationDidRegisterForRemoteNotificationsNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidRegisterForRemoteNotificationsNotification object:application userInfo:deviceToken ? @{UIApplicationDeviceTokenKey : deviceToken} : nil];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationDidRegisterForRemoteNotificationsNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationDidFailToRegisterForRemoteNotificationsNotification clazz:clazz block:^BOOL(NSObject *self, id application, id error) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationDidFailToRegisterForRemoteNotificationsNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&error atIndex:3];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationDidFailToRegisterForRemoteNotificationsNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFailToRegisterForRemoteNotificationsNotification object:application userInfo:error ? @{UIApplicationErrorKey : error} : nil];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationDidFailToRegisterForRemoteNotificationsNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationDidReceiveRemoteNotification clazz:clazz block:^BOOL(NSObject *self, id application, id remoteNotificationUserInfo) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationDidReceiveRemoteNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&remoteNotificationUserInfo atIndex:3];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationDidReceiveRemoteNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                NSMutableDictionary *userinfo = [NSMutableDictionary dictionary];
                if (remoteNotificationUserInfo)
                {
                    [userinfo setObject:remoteNotificationUserInfo forKey:UIApplicationRemoteNoficationUserInfoKey];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveRemoteNotification object:application userInfo:userinfo.count ? [userinfo copy] : nil];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationDidReceiveRemoteNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationDidReceiveRemoteWithFetchCompletionHandlerNotification clazz:clazz block:^BOOL(NSObject *self, id application, id remoteNotificationUserInfo, id fetchCompletionHandler) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationDidReceiveRemoteWithFetchCompletionHandlerNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&remoteNotificationUserInfo atIndex:3];
                [invocation setArgument:&fetchCompletionHandler atIndex:4];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationDidReceiveRemoteWithFetchCompletionHandlerNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                NSMutableDictionary *userinfo = [NSMutableDictionary dictionary];
                if (remoteNotificationUserInfo)
                {
                    [userinfo setObject:remoteNotificationUserInfo forKey:UIApplicationDidReceiveRemoteWithFetchCompletionHandlerNotification];
                }
                if (fetchCompletionHandler)
                {
                    [userinfo setObject:fetchCompletionHandler forKey:UIApplicationFetchCompletionHandlerKey];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveRemoteWithFetchCompletionHandlerNotification object:application userInfo:userinfo.count ? [userinfo copy] : nil];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationDidReceiveRemoteWithFetchCompletionHandlerNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationDidReceiveLocalNotification clazz:clazz block:^BOOL(NSObject *self, id application, id localNotification) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationDidReceiveLocalNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&localNotification atIndex:3];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationDidReceiveLocalNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveLocalNotification object:application userInfo:localNotification ? @{UIApplicationLocalNotificationKey : localNotification} : nil];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationDidReceiveLocalNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationHandleOpenURLNotification clazz:clazz block:^BOOL(NSObject *self, id application, id url) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationHandleOpenURLNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&url atIndex:3];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationHandleOpenURLNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationHandleOpenURLNotification object:application userInfo:url ? @{UIApplicationOpenURLOptionsURLKey : url} : nil];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationHandleOpenURLNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationOpenURLWithSourceApplicationNotification clazz:clazz block:^BOOL(NSObject *self, id application, id url, id sourceApplication, id annotation) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationOpenURLWithSourceApplicationNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&url atIndex:3];
                [invocation setArgument:&sourceApplication atIndex:4];
                [invocation setArgument:&annotation atIndex:5];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationOpenURLWithSourceApplicationNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                NSMutableDictionary *userinfo = [NSMutableDictionary dictionary];
                if (url)
                {
                    [userinfo setObject:url forKey:UIApplicationOpenURLOptionsURLKey];
                }
                if (sourceApplication)
                {
                    [userinfo setObject:sourceApplication forKey:UIApplicationOpenURLOptionsSourceApplicationKey];
                }
                if (annotation)
                {
                    [userinfo setObject:annotation forKey:UIApplicationOpenURLOptionsAnnotationKey];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationOpenURLWithSourceApplicationNotification object:application userInfo:userinfo.count ? [userinfo copy] : nil];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationOpenURLWithSourceApplicationNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationOpenURLWithOptionsNotification clazz:clazz block:^BOOL(NSObject *self, id application, id url, id options) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationOpenURLWithOptionsNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&url atIndex:3];
                [invocation setArgument:&options atIndex:4];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationOpenURLWithOptionsNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                NSMutableDictionary *userinfo = [NSMutableDictionary dictionary];
                if (url)
                {
                    [userinfo setObject:url forKey:UIApplicationOpenURLOptionsURLKey];
                }
                if (options)
                {
                    [userinfo setObject:options forKey:UIApplicationURLOptionsKey];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationOpenURLWithOptionsNotification object:application userInfo:userinfo];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationOpenURLWithOptionsNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationContinueUserActivityNotification clazz:clazz block:^BOOL(NSObject *self, id application, id userActivity, id restorationHandler) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationContinueUserActivityNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&userActivity atIndex:3];
                [invocation setArgument:&restorationHandler atIndex:4];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationContinueUserActivityNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                NSMutableDictionary *userinfo = [NSMutableDictionary dictionary];
                if (userActivity)
                {
                    [userinfo setObject:userActivity forKey:UIApplicationContinueUserActivityKey];
                }
                if (restorationHandler)
                {
                    [userinfo setObject:restorationHandler forKey:UIApplicationRestorationHandlerKey];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationContinueUserActivityNotification object:application userInfo:userinfo];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationContinueUserActivityNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationPerformActionForShortcutItemNotification clazz:clazz block:^BOOL(NSObject *self, id application, id item, id handler) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationPerformActionForShortcutItemNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&item atIndex:3];
                [invocation setArgument:&handler atIndex:4];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationPerformActionForShortcutItemNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                NSMutableDictionary *userinfo = [NSMutableDictionary dictionary];
                if (item)
                {
                    [userinfo setObject:item forKey:UIApplicationShortcutItemKey];
                }
                if (handler)
                {
                    [userinfo setObject:handler forKey:UIApplicationCompletionHandlerKey];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationPerformActionForShortcutItemNotification object:application userInfo:userinfo];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationPerformActionForShortcutItemNotification];
                return returnValue;
            }];
            
            [AppDelegateExtension installWithNotificationName:UIApplicationHandleWatchKitExtensionRequestNotification clazz:clazz block:^BOOL(NSObject *self, id application, id userInfo, id reply) {
                NSInvocation *invocation = [NSInvocation adext_invocationWithNotificationName:UIApplicationHandleWatchKitExtensionRequestNotification clazz:clazz target:self];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&userInfo atIndex:3];
                [invocation setArgument:&reply atIndex:4];
                BOOL addSucceed = [AppDelegateExtension extensions][UIApplicationHandleWatchKitExtensionRequestNotification].addSucceed;
                id returnValue = [invocation adext_returnValueWithAddResult:addSucceed];
                NSMutableDictionary *userinfo = [NSMutableDictionary dictionary];
                if (userInfo)
                {
                    [userinfo setObject:userInfo forKey:UIApplicationWatchKitExtensionRequestUserInfoKey];
                }
                if (reply)
                {
                    [userinfo setObject:reply forKey:UIApplicationWatchKitExtensionReplyKey];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationHandleWatchKitExtensionRequestNotification object:application userInfo:userinfo];
                [[AppDelegateExtension extensions] removeObjectForKey:UIApplicationHandleWatchKitExtensionRequestNotification];
                return returnValue;
            }];
        }
        
    });
}


#pragma clang diagnostic pop




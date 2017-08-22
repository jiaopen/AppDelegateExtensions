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
    
    // common case, actual swap
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

typedef struct { int i; } *empty_struct_ptr_t;
typedef union { int i; } *empty_union_ptr_t;

@implementation NSInvocation (AppDelegateExtensions)

- (BOOL)adext_setArgumentsFromArgumentList:(va_list)args {
    NSMethodSignature *signature = [self methodSignature];
    NSUInteger count = [signature numberOfArguments];
    for (NSUInteger i = 2;i < count;++i) {
        const char *type = [signature getArgumentTypeAtIndex:i];
        while (
               *type == 'r' ||
               *type == 'n' ||
               *type == 'N' ||
               *type == 'o' ||
               *type == 'O' ||
               *type == 'R' ||
               *type == 'V'
               ) {
            ++type;
        }
        
        switch (*type) {
            case 'c':
            {
                char val = (char)va_arg(args, int);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'i':
            {
                int val = va_arg(args, int);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 's':
            {
                short val = (short)va_arg(args, int);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'l':
            {
                long val = va_arg(args, long);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'q':
            {
                long long val = va_arg(args, long long);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'C':
            {
                unsigned char val = (unsigned char)va_arg(args, unsigned int);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'I':
            {
                unsigned int val = va_arg(args, unsigned int);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'S':
            {
                unsigned short val = (unsigned short)va_arg(args, unsigned int);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'L':
            {
                unsigned long val = va_arg(args, unsigned long);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'Q':
            {
                unsigned long long val = va_arg(args, unsigned long long);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'f':
            {
                float val = (float)va_arg(args, double);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'd':
            {
                double val = va_arg(args, double);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case 'B':
            {
                _Bool val = (_Bool)va_arg(args, int);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case '*':
            {
                char *val = va_arg(args, char *);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case '@':
            {
                __unsafe_unretained id val = va_arg(args, id);
                [self setArgument:&val atIndex:i];
                
                if (type[1] == '?') {
                    // @? is undocumented, but apparently used to represent
                    // a block -- not sure how to disambiguate it from
                    // a separate @ and ?, but I assume that a block parameter
                    // is a more common case than that
                    ++type;
                }
            }
                
                break;
                
            case '#':
            {
                Class val = va_arg(args, Class);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case ':':
            {
                SEL val = va_arg(args, SEL);
                [self setArgument:&val atIndex:i];
            }
                
                break;
                
            case '[':
                NSLog(@"Unexpected array within method argument type code \"%s\", cannot set invocation argument!", type);
                return NO;
                
            case 'b':
                NSLog(@"Unexpected bitfield within method argument type code \"%s\", cannot set invocation argument!", type);
                return NO;
                
            case '{':
                NSLog(@"Cannot get variable argument for a method that takes a struct argument!");
                return NO;
                
            case '(':
                NSLog(@"Cannot get variable argument for a method that takes a union argument!");
                return NO;
                
            case '^':
                switch (type[1]) {
                    case 'c':
                    case 'C':
                    {
                        char *val = va_arg(args, char *);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case 'i':
                    case 'I':
                    {
                        int *val = va_arg(args, int *);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case 's':
                    case 'S':
                    {
                        short *val = va_arg(args, short *);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case 'l':
                    case 'L':
                    {
                        long *val = va_arg(args, long *);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case 'q':
                    case 'Q':
                    {
                        long long *val = va_arg(args, long long *);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case 'f':
                    {
                        float *val = va_arg(args, float *);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case 'd':
                    {
                        double *val = va_arg(args, double *);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case 'B':
                    {
                        _Bool *val = va_arg(args, _Bool *);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case 'v':
                    {
                        void *val = va_arg(args, void *);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case '*':
                    case '@':
                    case '#':
                    case '^':
                    case '[':
                    {
                        void **val = va_arg(args, void **);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case ':':
                    {
                        SEL *val = va_arg(args, SEL *);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case '{':
                    {
                        empty_struct_ptr_t val = va_arg(args, empty_struct_ptr_t);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case '(':
                    {
                        empty_union_ptr_t val = va_arg(args, empty_union_ptr_t);
                        [self setArgument:&val atIndex:i];
                    }
                        
                        break;
                        
                    case '?':
                    {
                        // assume that this is a pointer to a function pointer
                        //
                        // even if it's not, the fact that it's
                        // a pointer-to-something gives us a good chance of not
                        // causing alignment or size problems
                        IMP *ptr = va_arg(args, IMP *);
                        [self setArgument:&ptr atIndex:i];
                    }
                        
                        break;
                        
                    case 'b':
                    default:
                        NSLog(@"Pointer to unexpected type within method argument type code \"%s\", cannot set method invocation!", type);
                        return NO;
                }
                
                break;
                
            case '?':
            {
                // this is PROBABLY a function pointer, but the documentation
                // leaves room open for uncertainty, so at least log a message
                NSLog(@"Assuming method argument type code \"%s\" is a function pointer", type);
                
                IMP ptr = va_arg(args, IMP);
                [self setArgument:&ptr atIndex:i];
            }
                
                break;
                
            default:
                NSLog(@"Unexpected method argument type code \"%s\", cannot set method invocation!", type);
                return NO;
        }
    }
    
    return YES;
}
@end

typedef void (^ADEXTPostNotificationBlock)(NSObject *self, va_list arguments);


void installAppDelegateExtensionsWithClass(Class clazz)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {
            @selector(application:didRegisterUserNotificationSettings:),
            @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:),
            @selector(application:didFailToRegisterForRemoteNotificationsWithError:),
            @selector(application:didReceiveRemoteNotification:),
            @selector(application:didReceiveLocalNotification:),
            @selector(application:handleOpenURL:),
            @selector(application:openURL:sourceApplication:annotation:),
            @selector(application:openURL:options:),
            @selector(application:continueUserActivity:restorationHandler:),
            @selector(application:performActionForShortcutItem:completionHandler:),
            @selector(application:handleWatchKitExtensionRequest:reply:),
        };
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        id blocks[] = {
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id settings = va_arg(arguments, id);
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidRegisterUserNotificationSettingsNotification object:application userInfo:settings ? @{UIApplicationUserNotificationSettingsKey : settings} : nil];
            },
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id deviceToken = va_arg(arguments, id);
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidRegisterForRemoteNotificationsNotification object:application userInfo:deviceToken ? @{UIApplicationDeviceTokenKey : deviceToken} : nil];
            },
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id error = va_arg(arguments, id);
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFailToRegisterForRemoteNotificationsNotification object:application userInfo:error ? @{UIApplicationErrorKey : error} : nil];
            },
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id userinfo = va_arg(arguments, id);
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveRemoteNotification object:application userInfo:userinfo];
            },
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id localNotification = va_arg(arguments, id);
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveLocalNotification object:application userInfo:localNotification ? @{UIApplicationLocalNotificationKey : localNotification} : nil];
            },
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id url = va_arg(arguments, id);
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationHandleOpenURLNotification object:application userInfo:url ? @{UIApplicationLaunchOptionsURLKey : url} : nil];
            },
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id url = va_arg(arguments, id);
                id sourceApplication = va_arg(arguments, id);
                id annotation = va_arg(arguments, id);
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
            },
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id url = va_arg(arguments, id);
                id options = va_arg(arguments, id);
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
            },
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id userActivity = va_arg(arguments, id);
                id restorationHandler = va_arg(arguments, id);
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
            },
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id item = va_arg(arguments, id);
                id handler = va_arg(arguments, id);
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
            },
            ^(NSObject *self, va_list arguments) {
                id application = va_arg(arguments, id);
                id userInfo = va_arg(arguments, id);
                id reply = va_arg(arguments, id);
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
            },
        };
#pragma clang diagnostic pop

        
        for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
            SEL originalSelector = selectors[index];
            SEL swizzledSelector = prefixedSelector(originalSelector);
            ADEXTPostNotificationBlock postNotificationBlock = blocks[index];
            __block BOOL addSucceed;
            
            IMP swizzledImplementation = imp_implementationWithBlock(^BOOL(NSObject *self, ...) {
                
                NSMethodSignature  *signature = [clazz instanceMethodSignatureForSelector:originalSelector];
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                invocation.target = self;
                invocation.selector = swizzledSelector;
                va_list arguments;
                va_start(arguments, self);
                [invocation adext_setArgumentsFromArgumentList:arguments];
                va_end(arguments);
                id returnValue;
                const char *returnType = signature.methodReturnType;
                if (!addSucceed)
                {
                    [invocation invoke];
                    
                    if( !strcmp(returnType, @encode(void)))
                    {
                        returnValue =  nil;
                    }
                    else if( !strcmp(returnType, @encode(id)))
                    {
                        [invocation getReturnValue:&returnValue];
                    }
                    else
                    {
                        NSUInteger length = [signature methodReturnLength];
                        void *buffer = (void *)malloc(length);
                        [invocation getReturnValue:buffer];
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
          
                va_start(arguments, self);
                postNotificationBlock(self, arguments);
                va_end(arguments);
                return returnValue;
            });
            
            addSucceed = addMethodWithIMP(clazz, originalSelector, swizzledSelector, swizzledImplementation, "v@:@", YES);
            if (!addSucceed)
            {
                swizzleWithIMP(clazz, originalSelector, swizzledSelector, swizzledImplementation, "v@:@", YES);
            }
        }
    });
}






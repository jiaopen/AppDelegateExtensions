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

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSNotificationName const UIApplicationWillFinishLaunchingNotification;
UIKIT_EXTERN NSNotificationName const UIApplicationDidRegisterUserNotificationSettingsNotification;
UIKIT_EXTERN NSNotificationName const UIApplicationDidRegisterForRemoteNotificationsNotification;
UIKIT_EXTERN NSNotificationName const UIApplicationDidFailToRegisterForRemoteNotificationsNotification;
UIKIT_EXTERN NSNotificationName const UIApplicationDidReceiveRemoteNotification  NS_DEPRECATED_IOS(3_0, 10_0, "Use UserNotifications Framework's -[UNUserNotificationCenterDelegate willPresentNotification:withCompletionHandler:] or -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:] for user visible notifications and -[UIApplicationDelegate application:didReceiveRemoteNotification:fetchCompletionHandler:] for silent remote notifications");
UIKIT_EXTERN NSNotificationName const UIApplicationDidReceiveLocalNotification NS_DEPRECATED_IOS(4_0, 10_0, "Use UserNotifications Framework's -[UNUserNotificationCenterDelegate willPresentNotification:withCompletionHandler:] or -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:]");
UIKIT_EXTERN NSNotificationName const UIApplicationHandleOpenURLNotification NS_DEPRECATED_IOS(2_0, 9_0, "Please use application:openURL:options:");
UIKIT_EXTERN NSNotificationName const UIApplicationOpenURLWithSourceApplicationNotification NS_DEPRECATED_IOS(2_0, 9_0, "Please use application:openURL:options:");
UIKIT_EXTERN NSNotificationName const UIApplicationOpenURLWithOptionsNotification;
UIKIT_EXTERN NSNotificationName const UIApplicationContinueUserActivityNotification;
UIKIT_EXTERN NSNotificationName const UIApplicationPerformActionForShortcutItemNotification;
UIKIT_EXTERN NSNotificationName const UIApplicationHandleWatchKitExtensionRequestNotification;

UIKIT_EXTERN NSString *const UIApplicationUserNotificationSettingsKey;
UIKIT_EXTERN NSString *const UIApplicationDeviceTokenKey;
UIKIT_EXTERN NSString *const UIApplicationErrorKey;
UIKIT_EXTERN NSString *const UIApplicationLocalNotificationKey;
UIKIT_EXTERN NSString *const UIApplicationURLOptionsKey;
UIKIT_EXTERN UIApplicationOpenURLOptionsKey const UIApplicationOpenURLOptionsURLKey;
UIKIT_EXTERN NSString *const UIApplicationContinueUserActivityKey;
UIKIT_EXTERN NSString *const UIApplicationRestorationHandlerKey;
UIKIT_EXTERN NSString *const UIApplicationShortcutItemKey;
UIKIT_EXTERN NSString *const UIApplicationCompletionHandlerKey;
UIKIT_EXTERN NSString *const UIApplicationWatchKitExtensionRequestUserInfoKey;
UIKIT_EXTERN NSString *const UIApplicationWatchKitExtensionReplyKey;
UIKIT_EXTERN NSString *const UIApplicationRemoteNoficationUserInfoKey;
UIKIT_EXTERN NSString *const UIApplicationFetchCompletionHandlerKey;


void installAppDelegateExtensionsWithClass(Class clazz);

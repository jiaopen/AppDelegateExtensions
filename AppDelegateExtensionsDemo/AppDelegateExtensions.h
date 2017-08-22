//
//  AppDelegateExtensions.h
//  AppDelegateExtensions
//
//  Created by 苏合 on 2017/8/21.
//  Copyright © 2017年 Mobike. All rights reserved.
//

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


void installAppDelegateExtensionsWithClass(Class clazz);

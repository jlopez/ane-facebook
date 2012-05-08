//
//  ChartbootLib.mm
//  ChartbootLib
//
//  Created by Jesus Lopez on 05/07/2012
//  Copyright (c) 2012 JLA. All rights reserved.
//
#import "FBConnect.h"
#import "NativeLibrary.h"

static NSString *const FBAccessTokenKey = @"FBAccessTokenKey";
static NSString *const FBExpirationDateKey = @"FBExpirationDateKey";
static NSString *const FBAutoLoginPermissionsKey = @"FBAutoLoginPermissionsKey";

static NSString *const FBAppIdKey = @"FBAppID";
static NSString *const FBPermissionsKey = @"FBPermissions";

static NSString *const FBLoginEvent = @"FACEBOOK_LOGIN_EVENT";
static NSString *const FBLoginCancelledEvent = @"FACEBOOK_LOGIN_CANCELLED_EVENT";
static NSString *const FBLoginFailedEvent = @"FACEBOOK_LOGIN_FAILED_EVENT";
static NSString *const FBLogoutEvent = @"FACEBOOK_LOGOUT_EVENT";
static NSString *const FBAccessTokenExtendedEvent = @"FACEBOOK_ACCESS_TOKEN_EXTENDED_EVENT";
static NSString *const FBSessionInvalidatedEvent = @"FACEBOOK_SESSION_INVALIDATED_EVENT";


@interface FacebookLib : NativeLibrary<FBSessionDelegate> {
@private
  Facebook *facebook;
}

@property (nonatomic, readonly) NSString *applicationId;

@end

@implementation FacebookLib

FN_BEGIN(FacebookLib)
  FN(applicationId, applicationId)
  FN(accessToken, accessToken)
  FN(expirationDate, expirationDate)
  FN(isFrictionlessRequestsEnabled, isFrictionlessRequestsEnabled)
  FN(login, loginWithPermissions:)
  FN(logout, logout)
  FN(extendAccessToken, extendAccessToken)
  FN(extendAccessTokenIfNeeded, extendAccessTokenIfNeeded)
  FN(shouldExtendAccessToken, shouldExtendAccessToken)
  FN(isSessionValid, isSessionValid)
FN_END

@synthesize applicationId;

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  [facebook release];
  [super dealloc];
}

- (void)updateToken:(NSString *)accessToken expiresAt:(NSDate *)expirationDate {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:accessToken forKey:FBAccessTokenKey];
  [defaults setObject:expirationDate forKey:FBExpirationDateKey];
  [defaults synchronize];
}

- (void)removeToken {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults objectForKey:FBAccessTokenKey]) {
    [defaults removeObjectForKey:FBAccessTokenKey];
    [defaults removeObjectForKey:FBExpirationDateKey];
    [defaults synchronize];
  }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSBundle *bundle = [NSBundle mainBundle];
  applicationId = [bundle objectForInfoDictionaryKey:FBAppIdKey];
  NSAssert(applicationId, @"Missing FBAppID");
  facebook = [[Facebook alloc] initWithAppId:applicationId andDelegate:self];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  id accessToken = [defaults objectForKey:FBAccessTokenKey];
  id expirationDate = [defaults objectForKey:FBExpirationDateKey];
  if (accessToken && expirationDate) {
    facebook.accessToken = accessToken;
    facebook.expirationDate = expirationDate;
  }

  NSString *loginPermissions = [bundle objectForInfoDictionaryKey:FBPermissionsKey];
  if (loginPermissions) {
    NSString *oldPermissions = [defaults objectForKey:FBAutoLoginPermissionsKey];
    if (![facebook isSessionValid] || ![oldPermissions isEqualToString:loginPermissions]) {
      [self loginWithPermissions:loginPermissions];
      [defaults setObject:loginPermissions forKey:FBAutoLoginPermissionsKey];
      [defaults synchronize];
    }
  }

  return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  return [facebook handleOpenURL:url];
}

- (void)fbDidLogin {
  [self updateToken:facebook.accessToken expiresAt:facebook.expirationDate];
  [self sendEventWithCode:FBLoginEvent level:@"INFO"];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
  if (cancelled)
    [self sendEventWithCode:FBLoginCancelledEvent level:@"INFO"];
  else
    [self sendEventWithCode:FBLoginFailedEvent level:@"INFO"];
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
  [self updateToken:accessToken expiresAt:expiresAt];
  [self sendEventWithCode:FBAccessTokenExtendedEvent level:@"INFO"];
}

- (void)fbDidLogout {
  [self removeToken];
  [self sendEventWithCode:FBLogoutEvent level:@"INFO"];
}

- (void)fbSessionInvalidated {
  [self removeToken];
  [self sendEventWithCode:FBSessionInvalidatedEvent level:@"INFO"];
}

- (NSString *)accessToken {
  return facebook.accessToken;
}

- (NSDate *)expirationDate {
  return facebook.expirationDate;
}

- (void)loginWithPermissions:(NSString *)permissions {
  NSArray *permArray = [permissions length] ? [permissions componentsSeparatedByString:@","] : nil;
  [facebook authorize:permArray];
}

- (void)logout {
  [facebook logout];
}

- (BOOL)isFrictionlessRequestsEnabled {
  return [facebook isFrictionlessRequestsEnabled];
}

- (void)extendAccessToken {
  [facebook extendAccessToken];
}

- (void)extendAccessTokenIfNeeded {
  [facebook extendAccessTokenIfNeeded];
}

- (BOOL)shouldExtendAccessToken {
  return [facebook shouldExtendAccessToken];
}

- (BOOL)isSessionValid {
  return [facebook isSessionValid];
}

@end

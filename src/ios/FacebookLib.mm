//
//  FacebookLib.mm
//  FacebookLib
//
//  Created by Jesus Lopez on 05/07/2012
//  Copyright (c) 2012 JLA. All rights reserved.
//

#import "Facebook.h"
#import "NativeLibrary.h"

static NSString *const FBAppIdKey = @"FacebookAppID";
static NSString *const FBAccessTokenKey = @"FBAccessTokenKey";
static NSString *const FBExpirationDateKey = @"FBExpirationDateKey";

static NSString *const FBLoginFailedEvent = @"LOGIN_FAILED";
static NSString *const FBLoginEvent = @"LOGIN";
static NSString *const FBLoginCanceledEvent = @"LOGIN_CANCELED";

static NSString *const FBLogoutEvent = @"LOGOUT";

@interface FacebookLib : NativeLibrary<FBDialogDelegate> {
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
  FN(login, login)
  FN(logout, logout)
  FN(isSessionValid, isSessionValid)
  FN(showDialog, dialog:params:)
  FN(graph, requestWithGraphPath:params:httpMethod:)
FN_END

@synthesize applicationId;


- (id)init {
  self = [super init];
  return self;
}

- (void)dealloc {
  [facebook release];
  [super dealloc];
}

// UNUSED
// – application:willFinishLaunchingWithOptions:
// – applicationWillResignActive:
// – applicationDidEnterBackground:
// – applicationWillEnterForeground:
// – applicationDidFinishLaunching:

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  	NSBundle *bundle = [NSBundle mainBundle];
  	applicationId = [bundle objectForInfoDictionaryKey:FBAppIdKey];
  	NSAssert1(applicationId, @"Missing %@", FBAppIdKey);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id accessToken = [defaults objectForKey:FBAccessTokenKey];
    id expirationDate = [defaults objectForKey:FBExpirationDateKey];

    if (accessToken && expirationDate) {
      FBAccessTokenData* accessTokenData = [FBAccessTokenData createTokenFromString:accessToken 
                                                          permissions:nil 
                                                          expirationDate:expirationDate
                                                          loginType:FBSessionLoginTypeFacebookApplication
                                                          refreshDate:nil];
      // add the old token to the cache
      [FBSessionTokenCachingStrategy.defaultInstance cacheFBAccessTokenData:accessTokenData];
      [defaults removeObjectForKey:FBAccessTokenKey];
      [defaults removeObjectForKey:FBExpirationDateKey];
      [defaults synchronize];
    }

    // We open the session up front, as long as we have a cached token, otherwise rely on the user 
    // to login explicitly 
    [FBSession openActiveSessionWithAllowLoginUI:NO];   
    [FBSettings publishInstall:applicationId];

    return YES;
}
// FBSample logic
// It is possible for the user to switch back to your application, from the native Facebook application, 
// when the user is part-way through a login; You can check for the FBSessionStateCreatedOpenening
// state in applicationDidBecomeActive, to identify this situation and close the session; a more sophisticated
// application may choose to notify the user that they switched away from the Facebook application without
// completely logging in
- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    // FBSample logic
    // We need to properly handle activation of the application with regards to SSO
    //  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBSession.activeSession handleDidBecomeActive];
}
// FBSample logic
// In the login workflow, the Facebook native application, or Safari will transition back to
// this applicaiton via a url following the scheme fb[app id]://; the call to handleOpenURL
// below captures the token, in the case of success, on behalf of the FBSession object
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBSession.activeSession handleOpenURL:url];
}

// FBSample logic
// It is important to close any FBSession object that is no longer useful
- (void)applicationWillTerminate:(UIApplication *)application {
    // Close the session before quitting
    // this is a good idea because things may be hanging off the session, that need 
    // releasing (completion block, etc.) and other components in the app may be awaiting
    // close notification in order to do cleanup
  [FBSession.activeSession close];
}

- (NSString *)accessToken {
  return FBSession.activeSession.accessTokenData.accessToken;
}


- (NSDate *)expirationDate {
  return FBSession.activeSession.accessTokenData.expirationDate;
}

- (void)login {
  if (FBSession.activeSession.isOpen) {
    [self sendEventWithCode:FBLoginEvent level:@"SESSION"];
    return;
  }

  void (^sessionStateChanged)( FBSession *, FBSessionState,NSError *) = 
      ^( FBSession *session,
         FBSessionState state,
         NSError *error) {
    // if login fails for any reason, we send a FBLoginFailedEvent
    if (error) {
      ANELog(@"ERROR");
      [self sendEventWithCode:FBLoginFailedEvent level:@"SESSION"];
    } 
    switch (state) {
    case FBSessionStateOpenTokenExtended:
    case FBSessionStateOpen: {
      ANELog(@"FBSessionStateOpen");
        [self sendEventWithCode:FBLoginEvent level:@"SESSION"];
        break;
      }
    case FBSessionStateClosed: {
      ANELog(@"FBSessionStateClosed");
        break; 
      }
    case FBSessionStateClosedLoginFailed: {
      ANELog(@"FBSessionStateClosedLoginFailed");
        [self sendEventWithCode:FBLoginFailedEvent level:@"SESSION"];
        break;
      }
    default: {
        ANELog(@"%s: %@", __PRETTY_FUNCTION__, @"Default case hit");
        break;
      }
    }
  };

  [FBSession openActiveSessionWithReadPermissions:nil
             allowLoginUI:YES
             completionHandler:sessionStateChanged];
}

- (void)logout {
  ANELog(@"%s: LOGOUT", __PRETTY_FUNCTION__);
  [FBSession.activeSession closeAndClearTokenInformation];  
  [self sendEventWithCode:FBLogoutEvent level:@"SESSION"];
}

- (BOOL)isSessionValid {
  return FBSession.activeSession.isOpen;
}


- (NSString *)requestWithGraphPath:(NSString *)graphPath params:(NSMutableDictionary *)params httpMethod:(NSString *)httpMethod {
  CFUUIDRef uuidRef = CFUUIDCreate(NULL);
  NSString *uuid = (NSString *)CFUUIDCreateString(NULL, uuidRef);
  CFRelease(uuidRef);
  params = sanitizeParams(params);
  if (!httpMethod) {
    httpMethod = @"GET";
  }
  FBRequestHandler callback = ^(FBRequestConnection *connection,
                                id result,
                                NSError *error) {
    if (error) {
       ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, connection, error);
       [self executeOnActionScriptThread:^{
         [self callMethodNamed:@"requestDidFailWithError" withArguments:[NSArray arrayWithObjects:uuid, error, nil]];
       }];
    }
    else {
      ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, connection, result);
      [self executeOnActionScriptThread:^{
        [self callMethodNamed:@"requestDidLoad" withArguments:[NSArray arrayWithObjects:uuid, result, nil]];
      }];
    }
  };

  [FBRequestConnection startWithGraphPath:graphPath parameters:params HTTPMethod:httpMethod completionHandler:callback];
  return uuid;
}

- (void)dialog:(NSString *)action params:(NSMutableDictionary *)params {
  if (!facebook) {
    facebook = [[Facebook alloc] initWithAppId:FBSession.activeSession.appID andDelegate:nil];
    facebook.accessToken = FBSession.activeSession.accessTokenData.accessToken;
    facebook.expirationDate = FBSession.activeSession.accessTokenData.expirationDate;
    [facebook enableFrictionlessRequests];
  }
  params = sanitizeParams(params);
  [facebook dialog:action andParams:params andDelegate:self];
}

/**
 * Called when the dialog succeeds with a returning url.
 */
- (void)dialogCompleteWithUrl:(NSURL *)url {
  ANELog(@"%s: %@", __PRETTY_FUNCTION__, url);
  [self executeOnActionScriptThread:^{
    [self callMethodNamed:@"dialogDidComplete" withArgument:[url absoluteString]];
  }];
}

/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url {
  ANELog(@"%s: %@", __PRETTY_FUNCTION__, url);
  [self executeOnActionScriptThread:^{
    [self callMethodNamed:@"dialogDidNotComplete" withArgument:[url absoluteString]];
  }];
}

/**
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
  ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, dialog, error);
  [self executeOnActionScriptThread:^{
    [self callMethodNamed:@"dialogDidFailWithError" withArgument:error];
  }];
}


NSMutableDictionary *sanitizeParams(NSMutableDictionary *params) {
  if (!params)
    return [NSMutableDictionary dictionary];
  for (NSString *key in [params allKeys]) {
    id val = [params objectForKey:key];
    if (![val isKindOfClass:[NSString class]])
      [params setObject:[val description] forKey:key];
  }
  return params;
}

@end

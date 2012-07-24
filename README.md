Facebook iOS ANE
================
Download the latest binary from [here](ane-facebook/wiki/facebook.ane)

Usage
-----
Set FBAppID in Info.plist to the FB application ID:

        <key>FBAppID</key><string>@FACEBOOK_APP_ID@</string>

Add a CFBundleURLTypes section to Info.plist:

        <key>CFBundleURLTypes</key>
        <array><dict>
          <key>CFBundleURLSchemes</key>
          <array><string>fb@FACEBOOK_APP_ID@</string></array>
        </dict></array>

Optionally, set a FBPermissions entry containing a comma separated
  list of permissions (may be empty). This will enable auto-login:

        <key>FBPermissions</key><string>email,stream_post</string>

Call API methods on the AS3 Facebook class:

        // Properties (read only)
        Facebook.applicationId
        Facebook.accessToken
        Facebook.expirationDate +
        Facebook.isFrictionlessRequestsEnabled *
        Facebook.shouldExtendAccessToken +
        Facebook.isSessionValid +

        // Methods
        Facebook.login(permissions)
        Facebook.logout()
        Facebook.extendAccessToken() *
        Facebook.extendAccessTokenIfNeeded() *
        Facebook.enableFrictionlessRequests() *
        Facebook.reloadFrictionlessRecipientCache() *
        Facebook.isFrictionlessEnabledForRecipient(fbid) *
        Facebook.isFrictionlessEnabledForRecipients(fbids) *
        Facebook.ui(params, callback) *
        Facebook.api(method, callback, params={}, reqMethod='GET')

        // Events
        SessionEvent.LOGIN
        SessionEvent.LOGIN_CANCELED *
        SessionEvent.LOGIN_FAILED *
        SessionEvent.LOGOUT
        SessionEvent.ACCESS_TOKEN_EXTENDED *
        SessionEvent.SESSION_INVALIDATED *

Desktop mode
============
API elements marked with * are not implemented in desktop mode.
Additionally, the following method must be called at the beginning of the
application:

        Facebook.init(appId, stage);

This method is a no-op when called from a mobile app, so it's safe to
call it regardless of mode.

`Facebook.ui` throws an exception as a reminder that this functionality
is not implemented. All other methods return a sensible result but do nothing.

Additionally, there's currently a bug in the expire\_in parsing that causes all
expirationDate functionality to be broken in desktop mode. Session is reported
to expire in March 1970). This also breaks the methods marked with +

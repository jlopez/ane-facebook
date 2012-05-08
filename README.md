Facebook iOS ANE
================
Download the latest binary from [here](ane-facebook/wiki/facebook.ane)

Usage
-------------
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
        Facebook.isSupported
        Facebook.applicationId
        Facebook.accessToken
        Facebook.expirationDate
        Facebook.isFrictionlessRequestsEnabled
        Facebook.shouldExtendAccessToken
        Facebook.isSessionValid

        // Methods
        Facebook.login(permissions)
        Facebook.logout()
        Facebook.extendAccessToken()
        Facebook.extendAccessTokenIfNeeded()

        // Events
        FACEBOOK_LOGIN_EVENT
        FACEBOOK_LOGIN_CANCELLED_EVENT
        FACEBOOK_LOGIN_FAILED_EVENT
        FACEBOOK_LOGOUT_EVENT
        FACEBOOK_ACCESS_TOKEN_EXTENDED_EVENT
        FACEBOOK_SESSION_INVALIDATED_EVENT

Coming soon
===========
Social methods, Graph API, ...

package com.jesusla.facebook {
  import flash.events.EventDispatcher;
  import flash.events.StatusEvent;
  import flash.external.ExtensionContext;
  import flash.utils.setTimeout;

  /**
   * Chartboost extension
   */
  public class Facebook {
    //---------------------------------------------------------------------
    //
    // Constants
    //
    //---------------------------------------------------------------------
    private static const EXTENSION_ID:String = "com.jesusla.facebook";

    public static const FACEBOOK_LOGIN_EVENT:String = "FACEBOOK_LOGIN_EVENT";
    public static const FACEBOOK_LOGIN_CANCELLED_EVENT:String = "FACEBOOK_LOGIN_CANCELLED_EVENT";
    public static const FACEBOOK_LOGIN_FAILED_EVENT:String = "FACEBOOK_LOGIN_FAILED_EVENT";
    public static const FACEBOOK_LOGOUT_EVENT:String = "FACEBOOK_LOGOUT_EVENT";
    public static const FACEBOOK_ACCESS_TOKEN_EXTENDED_EVENT:String = "FACEBOOK_ACCESS_TOKEN_EXTENDED_EVENT";
    public static const FACEBOOK_SESSION_INVALIDATED_EVENT:String = "FACEBOOK_SESSION_INVALIDATED_EVENT";

    public static const INFO_LEVEL:String = "INFO";
    public static const WARNING_LEVEL:String = "WARNING";
    public static const ERROR_LEVEL:String = "ERROR";

    //---------------------------------------------------------------------
    //
    // Private Properties.
    //
    //---------------------------------------------------------------------
    private static var context:ExtensionContext = initContext();
    private static var _isSupported:Boolean;
    private static var _dispatcher:EventDispatcher = new EventDispatcher();

    //---------------------------------------------------------------------
    //
    // Public Methods.
    //
    //---------------------------------------------------------------------
    public static function get isSupported():Boolean {
      return _isSupported;
    }

    public static function get applicationId():String {
      if (!isSupported)
        return null;
      return context.call("applicationId") as String;
    }

    public static function get accessToken():String {
      if (!isSupported)
        return null;
      return context.call("accessToken") as String;
    }

    public static function get expirationDate():Date {
      if (!isSupported)
        return null;
      var date:String = context.call("expirationDate") as String;
      return date ? new Date(date) : null;
    }

    public static function get isFrictionlessRequestsEnabled():Boolean {
      if (!isSupported)
        return false;
      return context.call("isFrictionlessRequestsEnabled");
    }

    public static function login(permissions:String = null):void {
      if (isSupported)
        context.call("login", permissions);
    }

    public static function logout():void {
      if (isSupported)
        context.call("logout");
    }

    public static function extendAccessToken():void {
      if (isSupported)
        context.call("extendAccessToken");
    }

    public static function extendAccessTokenIfNeeded():void {
      if (isSupported)
        context.call("extendAccessTokenIfNeeded");
    }

    public static function get shouldExtendAccessToken():Boolean {
      if (!isSupported)
        return false;
      return context.call("shouldExtendAccessToken");
    }

    public static function get isSessionValid():Boolean {
      if (!isSupported)
        return false;
      return context.call("isSessionValid");
    }

    public static function addEventListener(event:String, listener:Function):void {
      _dispatcher.addEventListener(event, listener);
    }

    public static function removeEventListener(event:String, listener:Function):void {
      _dispatcher.removeEventListener(event, listener);
    }

    //---------------------------------------------------------------------
    //
    // Private Methods.
    //
    //---------------------------------------------------------------------
    private static function initContext():ExtensionContext {
      var context:ExtensionContext =
        ExtensionContext.createExtensionContext(EXTENSION_ID, "FacebookLib");
      if (context) {
        context.addEventListener(StatusEvent.STATUS, context_statusHandler);
        _isSupported = context.actionScriptData;
      }
      return context;
    }

    private static function context_statusHandler(event:StatusEvent):void {
      _dispatcher.dispatchEvent(event);
    }
  }
}

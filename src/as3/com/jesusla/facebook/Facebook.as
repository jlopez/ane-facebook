package com.jesusla.facebook {
  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.StatusEvent;
  import flash.external.ExtensionContext;
  import flash.utils.setTimeout;

  /**
   * Facebook extension
   */
  public class Facebook extends EventDispatcher {
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

    //---------------------------------------------------------------------
    //
    // Private Properties.
    //
    //---------------------------------------------------------------------
    private static var context:ExtensionContext;
    private static var _isSupported:Boolean;
    private static var _instance:Facebook;

    //---------------------------------------------------------------------
    //
    // Public Methods.
    //
    //---------------------------------------------------------------------
    public function Facebook() {
      if (_instance)
        throw new Error("Singleton");
      _instance = this;
    }

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

    public static function enableFrictionlessRequests():void {
      if (isSupported)
        context.call("enableFrictionlessRequests");
    }

    public static function reloadFrictionlessRecipientCache():void {
      if (isSupported)
        context.call("reloadFrictionlessRecipientCache");
    }

    public static function isFrictionlessEnabledForRecipient(fbid:String):Boolean {
      if (!isSupported)
        return false;
      return context.call("isFrictionlessEnabledForRecipient", fbid);
    }

    public static function isFrictionlessEnabledForRecipients(fbids:Array):Boolean {
      if (!isSupported)
        return false;
      return context.call("isFrictionlessEnabledForRecipients", fbids);
    }

    public static function showDialog(action:String, params:Object):void {
      if (isSupported)
        context.call("showDialog", action, params, keys(params));
    }

    public static function get shouldOpenDialogURLInExternalBrowser():Boolean {
      return !isSupported || context.call("shouldOpenDialogURLInExternalBrowser");
    }

    public static function set shouldOpenDialogURLInExternalBrowser(value:Boolean):void {
      if (isSupported)
        context.call("setShouldOpenDialogURLInExternalBrowser", value);
    }

    public static function addEventListener(event:String, listener:Function):void {
      _instance.addEventListener(event, listener);
    }

    public static function removeEventListener(event:String, listener:Function):void {
      _instance.removeEventListener(event, listener);
    }

    public function dialogDidComplete(url:String):void {
      dispatchEvent(new DialogEvent(DialogEvent.DIALOG_COMPLETED, url));
    }

    public function dialogDidNotComplete(url:String):void {
      dispatchEvent(new DialogEvent(DialogEvent.DIALOG_CANCELED, url));
    }

    public function dialogDidFailWithError(error:Object):void {
      dispatchEvent(new DialogEvent(DialogEvent.DIALOG_FAILED, null, error));
    }

    public function dialogOpenUrl(url:String):void {
      dispatchEvent(new DialogEvent(DialogEvent.DIALOG_OPEN_URL, url));
    }

    //---------------------------------------------------------------------
    //
    // Private Methods.
    //
    //---------------------------------------------------------------------
    private static function keys(object:Object):Array {
      var keys:Array = [];
      for (var key:String in object)
        keys.push(key);
      return keys;
    }

    private static function context_statusEventHandler(event:StatusEvent):void {
      if (event.level == "TICKET")
        context.call("claimTicket", event.code);
      else
        _instance.dispatchEvent(event);
    }

    {
      new Facebook();
      context = ExtensionContext.createExtensionContext(EXTENSION_ID, "FacebookLib");
      if (context) {
        _isSupported = context.actionScriptData;
        context.addEventListener(StatusEvent.STATUS, context_statusEventHandler);
        context.actionScriptData = _instance;
      }
    }
  }
}

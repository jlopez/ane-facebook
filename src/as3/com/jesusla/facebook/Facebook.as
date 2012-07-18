package com.jesusla.facebook {
  import flash.display.MovieClip;
  import flash.events.EventDispatcher;
  import flash.events.StatusEvent;
  import flash.external.ExtensionContext;
  import flash.utils.ByteArray;
  // simulator support
  import com.facebook.graph.FacebookMobile;
  import com.facebook.graph.data.FacebookSession;
  import flash.display.Stage;
  import flash.media.StageWebView;
  import flash.geom.Rectangle;
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

    //---------------------------------------------------------------------
    //
    // Private Properties.
    //
    //---------------------------------------------------------------------
    private static var context:ExtensionContext;
    private static var _isSupported:Boolean = false;
    private static var _instance:Facebook = null;
    private static var _applicationId:String = null;
    private static var _accessToken:String = null;
    private static var _userFbId:String = null;

    private var _pendingRequests:Object = {};

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
      if (isSupported)
        return context.call("applicationId") as String;
      return _applicationId;
    }

    public static function get accessToken():String {
      if (isSupported)
        return context.call("accessToken") as String;
      return _accessToken;
    }

    public static function get userFbId():String {
      return _userFbId;
    }


    /*
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
    */

    public static function login(appId:String, stage:Stage=null, permissions:Array = null):void {
      if (isSupported) {
        context.call("login", permissions.join());
      }
      else {
        _applicationId = appId;
        FacebookMobile.init(appId, onFacebookMobileInit);

        function onFacebookMobileInit(success:Object, fail:Object):void
        {
          if (success is FacebookSession)
          {
            var session:FacebookSession = success as FacebookSession;
            _accessToken = session.accessToken;
            _userFbId = session.uid;
            _instance.dispatchEvent(new SessionEvent(SessionEvent.LOGIN));
          }
          else
          {
            var webView:StageWebView = new StageWebView();
            webView.stage = stage;
            webView.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
            FacebookMobile.login(onFacebookMobileLogin, stage, permissions, webView);
          }
        }

        function onFacebookMobileLogin(success:Object, fail:Object):void
        {
          if (success is FacebookSession)
          {
            var session:FacebookSession = success as FacebookSession;
            _accessToken = session.accessToken;
            _userFbId = session.uid;
            _instance.dispatchEvent(new SessionEvent(SessionEvent.LOGIN));
          }
          else
          {
            trace("facebookConnect() failure:", success, fail);
            _instance.dispatchEvent(new SessionEvent(SessionEvent.LOGIN_FAILED));
          }
        }
      }
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
      if (isSupported) {
        // force all to String type
        var keys:Array = [];
        for (var key:String in params) {
          keys.push(key);
          params[key] = params[key].toString();
        }
        context.call("showDialog", action, params, keys);
      }
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

    public function dialogDidComplete(url:String = null):void {
      dispatchEvent(new DialogEvent(DialogEvent.DIALOG_COMPLETED, url));
    }

    public function dialogDidNotComplete(url:String = null):void {
      dispatchEvent(new DialogEvent(DialogEvent.DIALOG_CANCELLED, url));
    }

    public function dialogDidFailWithError(error:Object):void {
      dispatchEvent(new DialogEvent(DialogEvent.DIALOG_FAILED, null, error));
    }

    public function dialogOpenUrl(url:String):void {
      dispatchEvent(new DialogEvent(DialogEvent.DIALOG_OPEN_URL, url));
    }

    public function requestLoading(uuid:String):void {
    // trace("requestLoading");
    }

    public function requestDidReceiveResponse(uuid:String, response:Object):void {
    // trace("requestDidReceiveResponse");
    }

    public function requestDidFailWithError(uuid:String, error:Object):void {
    // trace("requestDidFailWithError");
      var cb:Function = _pendingRequests[uuid];
      var response:Object = {};
      response.error = error;
      cb(response);
      delete _pendingRequests[uuid];
    }

    public function requestDidLoad(uuid:String, result:Object):void {
      var cb:Function = _pendingRequests[uuid];
      cb(result);
      delete _pendingRequests[uuid];
    }

    public function requestDidLoadRawResponse(uuid:String, data:ByteArray):void {
    // trace("requestDidLoadRawResponse");
    }

  /** https://developers.facebook.com/docs/reference/javascript/FB.api/
   * This is based on the fb javascript sdk, whereby the arguments are inferred by type
   * @param {String} path the url path
   * @param {Object} params the parameters for the query
   * @param {String} method the http method (default "GET")
   * @param {Function} cb the callback function to handle the response
   */
    public static function api(...args):void {
      if (!_isSupported) {
        return;
      }
      var path:String = null;
      var params:Object = null;
      var method:String = null;
      var cb:Function = null;    // reference: https://github.com/facebook/facebook-js-sdk/blob/deprecated/src/core/api.js
      path = args.shift();
      var next:* = args.shift();
      while (next) {
        var type:String = typeof next;
        if (type == 'string' && !method) {
          method = next.toUpperCase();
        }
        else if (type === 'function' && (cb === null)) {
          cb = next;
        }
        else if (type === 'object' && (params === null)) {
          params = next;
        }
        else {
          trace('Invalid argument passed to FB.api(): ' + next);
          return;
        }
        next = args.shift();
      }
      method = method || "GET";
      params = params || {};

      // remove prefix slash if one is given, as it's already in the base url
      if (path.charAt(0) === '/') {
        path = path.substr(1);
      }
      // force all to String type
      var keys:Array = [];
      for (var key:String in params) {
        keys.push(key);
        params[key] = params[key].toString();
      }
      var uuid:String = String(context.call("graph", path, params, keys, method));
      _instance._pendingRequests[uuid] = cb;
    }

    /** https://developers.facebook.com/docs/reference/javascript/FB.ui/
     * This is based on the fb javascript sdk, whereby the arguments are inferred by type
     * @param {Object} params the parameters for the query  
     * @param {Function} cb the callback function to handle the response
     */
    public static function ui(params:Object, cb:Function = null):void {
      if (!params.method) {          // via: https://github.com/facebook/facebook-js-sdk/blob/deprecated/src/core/ui.js
        trace('"method" is a required parameter for FB.ui().');
        return;
      }

      function getUrlVars(url:String):Object {
        var vars:Object = {};
        var urlParams:Array = url.slice(url.indexOf('?') + 1).split('&');
        var urlParamsLength:int = urlParams.length;
        for (var i:int = 0; i < urlParamsLength; ++i) {
          var keyvalue:Array = urlParams[i].split('=');
          var isArrayKey:Boolean = (keyvalue[0].indexOf('[') !== -1);
          if (isArrayKey) {
            var keyindex:Array = keyvalue[0].split(/[\[\]]/);
            if (typeof vars[keyindex[0]] !== 'array') {
              vars[keyindex[0]] = [];
            }
            vars[keyindex[0]][keyindex[1]] = keyvalue[1];
          }
          else {
            vars[keyvalue[0]] = keyvalue[1];
          }
        }
        return vars;
      }

      function facebook_dialogEvent(event:DialogEvent):void {
        var result:Object = null;
        if (event) {
          if (cb !== null) {
            if (event.error) {
              result = {
                error : event.error
              };
            }
            else {
              result = getUrlVars(unescape(event.url));
            }
            cb(result);
          }
          else {
            // no callback => no one cares
          }
        }
        else {
          trace("DIALOG ERROR EMPTY EVENT");
        }
        Facebook.removeEventListener(DialogEvent.DIALOG_COMPLETED, facebook_dialogEvent);
        Facebook.removeEventListener(DialogEvent.DIALOG_CANCELLED, facebook_dialogEvent);
        Facebook.removeEventListener(DialogEvent.DIALOG_FAILED, facebook_dialogEvent);
      }
      Facebook.addEventListener(DialogEvent.DIALOG_COMPLETED, facebook_dialogEvent);
      Facebook.addEventListener(DialogEvent.DIALOG_CANCELLED, facebook_dialogEvent);
      Facebook.addEventListener(DialogEvent.DIALOG_FAILED, facebook_dialogEvent);
      Facebook.showDialog(params.method, params);
    }

    //---------------------------------------------------------------------
    //
    // Internal (package level) Methods.
    //
    //---------------------------------------------------------------------

    //---------------------------------------------------------------------
    //
    // Private Methods.
    //
    //---------------------------------------------------------------------
    private static function context_statusEventHandler(event:StatusEvent):void {
      if (event.level == "TICKET")
        context.call("claimTicket", event.code);
      else if (event.level == "SESSION") {
        if (event.code == SessionEvent.LOGIN) {
          Facebook.api("me", onFacebookGetUserId);
          function onFacebookGetUserId(response:Object):void {
            if (response && !response.error) {
              _userFbId = response.id;
              _instance.dispatchEvent(new SessionEvent(SessionEvent.LOGIN));
            }
            else {
              //trace("onFacebookGetUserId Error:" + response.error);
              _instance.dispatchEvent(new SessionEvent(SessionEvent.LOGIN_FAILED));
            }
          }
        }
        else {
          _instance.dispatchEvent(new SessionEvent(event.code));
        }
      }
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

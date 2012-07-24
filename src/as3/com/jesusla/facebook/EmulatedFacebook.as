package com.jesusla.facebook {
  import flash.display.Stage;
  import flash.geom.Rectangle;
  import flash.media.StageWebView;

  import com.facebook.graph.FacebookMobile;
  import com.facebook.graph.data.FacebookSession;

  /**
   * Emulation
   */
  public class EmulatedFacebook extends Facebook {
    private var _applicationId:String;
    private var _stage:Stage;
    private var _session:FacebookSession;
    private var _lastAccessTokenUpdate:Date;
    private var _isExtendingAccessToken:Boolean;

    private function ensureInitialized():void {
      if (!_applicationId || !_stage)
        throw new Error("Facebook.init(appId, stage) must be called when running on the emulator");
    }

    public function EmulatedFacebook() {
      _lastAccessTokenUpdate = new Date(0);
    }

    override internal function init(applicationId:String, stage:Stage):void {
      _applicationId = applicationId;
      _stage = stage;
      FacebookMobile.init(applicationId, onFacebookMobileInit);

      function onFacebookMobileInit(success:Object, fail:Object):void {
        _session = success as FacebookSession;
      }
    }

    override internal function get applicationId():String {
      ensureInitialized();
      return _applicationId;
    }

    override internal function get accessToken():String {
      return _session ? _session.accessToken : null;
    }

    override internal function get expirationDate():Date {
      return _session ? _session.expireDate : null;
    }

    override internal function get isFrictionlessRequestsEnabled():Boolean {
      return false;
    }

    override internal function login(permissions:Array = null):void {
      var webView:StageWebView = new StageWebView();
      webView.stage = _stage;
      webView.viewPort = new Rectangle(0, 0, _stage.stageWidth, _stage.stageHeight);
      FacebookMobile.login(onFacebookMobileLogin, _stage, permissions, webView);

      function onFacebookMobileLogin(success:Object, fail:Object):void {
        var session:FacebookSession = success as FacebookSession;
        if (session) {
          _session = session;
          _lastAccessTokenUpdate = new Date();
          dispatchEvent(new SessionEvent(SessionEvent.LOGIN));
        }
        else {
          trace("facebookConnect() failure:", success, fail);
          dispatchEvent(new SessionEvent(SessionEvent.LOGIN_FAILED));
        }
      }
    }

    override internal function logout():void {
      FacebookMobile.logout(onFacebookMobileLogout);

      function onFacebookMobileLogout(flag:Boolean):void {
        _session = null;
        dispatchEvent(new SessionEvent(SessionEvent.LOGOUT));
      }
    }

    override internal function extendAccessToken():void {
      if (_isExtendingAccessToken)
        return;
      _isExtendingAccessToken = true;
      FacebookMobile.callRestAPI("auth.extendSSOAccessToken", onAccessTokenExtended);

      // This does not work with FacebookMobile.
      // Returns "(10): The access token was not obtained using single sign-on"
      function onAccessTokenExtended(response:Object, error:Object):void {
        _isExtendingAccessToken = false;
        if (!response || !response.access_token || response.expires_at == null)
          return;
        _session.accessToken = response.access_token;
        _session.expireDate = new Date(response.expires_at || int.MAX_VALUE);
        _lastAccessTokenUpdate = new Date();
        dispatchEvent(new SessionEvent(SessionEvent.ACCESS_TOKEN_EXTENDED));
      }
    }

    override internal function extendAccessTokenIfNeeded():void {
      if (shouldExtendAccessToken)
        extendAccessToken();
    }

    override internal function get shouldExtendAccessToken():Boolean {
      return isSessionValid && _lastAccessTokenUpdate.time + 86400000 < new Date().time;
    }

    override internal function get isSessionValid():Boolean {
      return accessToken != null && expirationDate != null &&
        expirationDate.time > new Date().time;
    }

    override internal function enableFrictionlessRequests():void {
    }

    override internal function reloadFrictionlessRecipientCache():void {
    }

    override internal function isFrictionlessEnabledForRecipient(fbid:String):Boolean {
      return false;
    }

    override internal function isFrictionlessEnabledForRecipients(fbids:Array):Boolean {
      return false;
    }

    override internal function ui(params:Object, cb:Function = null):void {
      throw new Error("Facebook.ui() not implemented in desktop mode");
    }

    override internal function api(path:String, cb:Function, params:Object, method:String):void {
      FacebookMobile.api(path, onApiResponse, params, method);

      function onApiResponse(result:Object, error:Object):void {
        if (error)
          result = { error: error };
        if (cb != null)
          cb(result);
      }
    }
  }
}

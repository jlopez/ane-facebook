package com.jesusla.facebook {
  import flash.display.Stage;
  import flash.events.StatusEvent;
  import flash.external.ExtensionContext;
  import flash.utils.getQualifiedClassName;

  /**
   * Emulation
   */
  public class NativeFacebook extends Facebook {
    private var context:ExtensionContext;
    private var _objectPool:Object = {};
    private var _objectPoolId:int = 0;
    private var _pendingRequests:Object = {};
    private var _dialogCallback:Function;

    function NativeFacebook(ctx:ExtensionContext) {
      ctx.addEventListener(StatusEvent.STATUS, context_statusEventHandler);
      ctx.call("setActionScriptThis", this);
      context = ctx;
    }

    override internal function init(appId:String, stage:Stage):void {
      if (appId != this.applicationId)
        trace("WARNING: Facebook appId mismatch: " + applicationId + " vs. " + appId);
    }

    override internal function get applicationId():String {
      return context.call("applicationId") as String;
    }

    override internal function get accessToken():String {
      return context.call("accessToken") as String;
    }

    override internal function get expirationDate():Date {
      return context.call("expirationDate") as Date;
    }

    override internal function login():void {
      context.call("login");
    }

    override internal function logout():void {
      context.call("logout");
    }

    override internal function get isSessionValid():Boolean {
      return context.call("isSessionValid");
    }

    override internal function ui(params:Object, cb:Function = null):void {
      if (!params.method)
        throw new ArgumentError('"method" is a required parameter for Facebook.ui()');
      _dialogCallback = cb;
      context.call("showDialog", params.method, params);
    }

    override internal function api(path:String, cb:Function, params:Object, method:String):void {
      var uuid:String = String(context.call("graph", path, params, method));
      _pendingRequests[uuid] = cb;
    }

    public function dialogDidComplete(url:String):void {
      invokeDialogCallback(responseFromUrl(url));
    }

    public function dialogDidNotComplete(url:String):void {
      var response:Object = { error: responseFromUrl(url) };
      invokeDialogCallback(response);
    }

    public function dialogDidFailWithError(error:Object):void {
      var response:Object = { error: error };
      invokeDialogCallback(response);
    }

    public function requestDidFailWithError(uuid:String, error:Object):void {
      var response:Object = { error: error };
      invokeRequestCallback(uuid, response);
    }

    public function requestDidLoad(uuid:String, result:Object):void {
      invokeRequestCallback(uuid, result);
    }

    public function getQualifiedClassName(obj:Object):String {
      return flash.utils.getQualifiedClassName(obj);
    }

    public function enumerateObjectProperties(obj:Object):Array {
      var keys:Array = [];
      for (var key:String in obj)
        keys.push(key);
      return keys;
    }

    public function __retainObject(obj:Object):int {
      _objectPool[++_objectPoolId] = obj;
      return _objectPoolId;
    }

    public function __getObject(id:int):Object {
      return _objectPool[id];
    }

    //---------------------------------------------------------------------
    //
    // Private Methods.
    //
    //---------------------------------------------------------------------
    private function invokeDialogCallback(response:Object):void {
      if (_dialogCallback != null)
        _dialogCallback(response);
      _dialogCallback = null;
    }

    private function invokeRequestCallback(uuid:String, response:Object):void {
      var cb:Function = _pendingRequests[uuid];
      if (cb != null)
        cb(response);
      delete _pendingRequests[uuid];
    }

    private function responseFromUrl(url:String):Object {
      url = decodeURI(url);
      var rv:Object = {};
      var query:int = url.indexOf('?');
      var ref:int = url.indexOf('#', query + 1);
      if (query != -1)
        decodeUrl(rv, ref == -1 ? url.substr(query + 1) :
                                  url.substr(query + 1, ref));
      if (ref != -1)
        decodeUrl(rv, url.substr(ref + 1));
      return rv;
    }

    private function decodeUrl(rv:Object, s:String):void {
      var urlParams:Array = s.split('&');
      var len:int = urlParams.length;
      for (var i:int = 0; i < len; ++i) {
        var kv:Array = urlParams[i].split('=');
        if (kv.length != 2)
          continue;
        var k:String = decodeURIComponent(kv[0]);
        var v:String = decodeURIComponent(kv[1]);
        if (k.indexOf('[') !== -1) {
          var ki:Array = k.split(/[\[\]]/);
          if (!(rv[ki[0]] is Array))
            rv[ki[0]] = [];
          rv[ki[0]][ki[1]] = v;
        }
        else
          rv[k] = v;
      }
    }

    private function context_statusEventHandler(event:StatusEvent):void {
      if (event.level == "TICKET")
        context.call("claimTicket", event.code);
      else if (event.level == "RELEASE")
        delete _objectPool[int(event.code)];
      else if (event.level == "SESSION")
        dispatchEvent(new SessionEvent(event.code));
    }
  }
}

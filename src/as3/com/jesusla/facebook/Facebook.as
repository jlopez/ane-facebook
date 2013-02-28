package com.jesusla.facebook {
  import flash.display.Stage;
  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.external.ExtensionContext;
  import flash.utils.ByteArray;
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
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

    //---------------------------------------------------------------------
    //
    // Private Properties.
    //
    //---------------------------------------------------------------------
    private static var _instance:Facebook;

    //---------------------------------------------------------------------
    //
    // Public Methods.
    //
    //---------------------------------------------------------------------
    public function Facebook() {
      if (_instance)
        throw new Error("Singleton");
    }

    public static function init(applicationId:String, stage:Stage):void {
      instance.init(applicationId, stage);
    }

    public static function get applicationId():String {
      return instance.applicationId;
    }

    public static function get accessToken():String {
      return instance.accessToken;
    }

    public static function get expirationDate():Date {
      return instance.expirationDate;
    }

    public static function login():void {
      instance.login();
    }

    public static function logout():void {
      instance.logout();
    }

    public static function get isSessionValid():Boolean {
      return instance.isSessionValid;
    }

    public static function ui(params:Object, cb:Function = null):void {
      instance.ui(params, cb);
    }

    public static function api(...args):void {
      var path:String = args.shift();
      var params:Object = null;
      var method:String = null;
      var cb:Function = null;
      for (var next:* = args.shift(); next; next = args.shift()) {
        if (next is String && !method)
          method = next.toUpperCase();
        else if (next is Function && cb == null)
          cb = next;
        else if (getQualifiedClassName(next) == 'Object' && params == null)
          params = next;
        else
          throw new ArgumentError("Invalid argument passed to Facebook.api(): " + next);
      }
      if (path.charAt(0) === '/')
        path = path.substr(1);
      instance.api(path, cb, params || {}, method || 'GET');
    }

    public static function addEventListener(event:String, listener:Function):void {
      instance.addEventListener(event, listener);
    }

    public static function removeEventListener(event:String, listener:Function):void {
      instance.removeEventListener(event, listener);
    }

    internal function init(applicationId:String, stage:Stage):void { pureVirtual(); }
    internal function get applicationId():String { return pureVirtual(); }
    internal function get accessToken():String { return pureVirtual(); }
    internal function get expirationDate():Date { return pureVirtual(); }
    internal function login():void { pureVirtual(); }
    internal function logout():void { pureVirtual(); }
    internal function get isSessionValid():Boolean { return pureVirtual(); }
    internal function ui(params:Object, cb:Function = null):void { pureVirtual(); }
    internal function api(path:String, cb:Function, params:Object, method:String):void { pureVirtual(); }

    //---------------------------------------------------------------------
    //
    // Private Methods.
    //
    //---------------------------------------------------------------------
    private function pureVirtual():* {
      throw new Error("Pure Virtual");
      return null;
    }

    private static function get instance():Facebook {
      if (_instance == null) {
        var _ctx:ExtensionContext =
          ExtensionContext.createExtensionContext(EXTENSION_ID, EXTENSION_ID + ".FacebookLib");
        if (_ctx) {
          try {
            _instance = new NativeFacebook(_ctx);
          } catch (e:ArgumentError) {
          }
        }
        if (_instance == null)
          _instance = new EmulatedFacebook();
      }
      return _instance;
    }
  }
}

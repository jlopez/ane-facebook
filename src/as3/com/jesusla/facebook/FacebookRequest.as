package com.jesusla.facebook {
  import flash.events.EventDispatcher;

  public class FacebookRequest extends EventDispatcher {
    private var _uuid:String;
    public var response:Object;
    public var error:Object;
    public var result:Object;
    public var rawResult:Object;

    public function api(path:String, params:Object = null, httpMethod:String = null):void {
      Facebook.api(this, path, params, httpMethod);
    }

    internal function set uuid(value:String):void {
      if (_uuid)
        throw new Error("A FacebookRequest object may not be reused.");
      _uuid = value;
    }

    internal function get uuid():String {
      return _uuid;
    }
  }
}

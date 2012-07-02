package com.jesusla.facebook {
  import flash.events.Event;

  public class RequestEvent extends Event {
    public static var LOADING:String = "LOADING";
    public static var RESPONSE:String = "RESPONSE";
    public static var FAILED:String = "FAILED";
    public static var LOADED:String = "LOADED";
    public static var LOADED_RAW:String = "LOADED_RAW";

    private var _request:FacebookRequest;

    public function RequestEvent(type:String, request:FacebookRequest) {
      super(type);
      _request = request;
    }

    public function get request():FacebookRequest {
      return _request;
    }
  }
}

package com.jesusla.facebook {
  import flash.events.Event;

  public class SessionEvent extends Event {
    public static const LOGIN:String = "LOGIN";
    public static const LOGIN_CANCELED:String = "LOGIN_CANCELED";
    public static const LOGIN_FAILED:String = "LOGIN_FAILED";
    public static const LOGOUT:String = "LOGOUT";
    public static const ACCESS_TOKEN_EXTENDED:String = "ACCESS_TOKEN_EXTENDED";
    public static const SESSION_INVALIDATED:String = "SESSION_INVALIDATED";

    public function SessionEvent(type:String) {
      super(type);
    }
  }
}

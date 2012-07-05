package com.jesusla.facebook {
 import flash.events.Event;

 public class DialogEvent extends Event {
   public static var DIALOG_COMPLETED:String = "DIALOG_COMPLETED";
   public static var DIALOG_CANCELLED:String = "DIALOG_CANCELLED";
   public static var DIALOG_FAILED:String = "DIALOG_FAILED";
   public static var DIALOG_OPEN_URL:String = "DIALOG_OPEN_URL";

   private var _url:String;
   private var _error:Object;

   public function DialogEvent(name:String, url:String, error:Object = null) {
     super(name);
     _url = url;
     _error = error;
   }

   public function get url():String { return _url; }
   public function get error():Object { return _error; }
 }
}

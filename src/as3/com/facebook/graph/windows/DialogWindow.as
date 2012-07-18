/*
Copyright (c) 2010, Adobe Systems Incorporated
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Adobe Systems Incorporated nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
package com.facebook.graph.windows {

	import com.facebook.graph.core.FacebookURLDefaults;
	import com.facebook.graph.utils.FacebookDataUtils;
	import flash.utils.describeType;
	
	import flash.desktop.NativeApplication;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.LocationChangeEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	/**
	 * Displays a new NativeWindow that allows the current user to present a
	 * dialog.
	 * 
	 * Heavily modified to actually work by thegoldenmule.
	 */
	public class DialogWindow extends Sprite {
	
		protected var request:URLRequest;
		protected var userClosedWindow:Boolean = true;
		private var webView:StageWebView;
		
		public var callback:Function;
		
		/**
		 * Creates a new LoginWindow instance.
		 * @param loginCallback Method to call when login is successful
		 *
		 */
		public function DialogWindow(callback:Function) {
			this.callback = callback;
			
			super();
		}
		
		/**
		 * Opens a new dialog window.
		 *
		 * @param applicationId Current ID of the application being used.
		 */
		public function open(method:String, applicationId:String, webView:StageWebView, params:*):void {
			this.webView = webView;
			
			// create new URL request
			request = new URLRequest();
			request.method = URLRequestMethod.GET;
			request.url = FacebookURLDefaults.DIALOG_URL + method + "?" + formatData(applicationId, "touch", params);
			
			// show window
			showWindow(request);
		}
		
		protected function showWindow(req:URLRequest):void {
			webView.addEventListener(
				Event.COMPLETE,
				handleLocationChange,
				false, 0, true
			);
			webView.addEventListener(
				LocationChangeEvent.LOCATION_CHANGE,
				handleLocationChange,
				false, 0, true
			);
			
			webView.loadURL(req.url);
		}
		
		protected function formatData(applicationId:String, display:String, params:*):URLVariables {
			// create vars
			var variables:URLVariables = toUrlVariables(params);
			
			// append necessities
			variables.app_id = applicationId;
			variables.redirect_uri = FacebookURLDefaults.LOGIN_SUCCESS_URL;
			variables.display = "touch";
			
			return variables;
		}
		
		private function toUrlVariables(params:*):URLVariables {
			var vars:URLVariables = new URLVariables();
			var type:XML = describeType(params);
			for each (var prop:XML in type.variable) {
				var propName:String = prop.@name;
				if (null != params[propName]) vars[propName] = params[propName];
			}
			
			for (var property:String in params) {
				if (null != params[property]) vars[property] = params[property];
			}
			
			return vars;
		}
		
		protected function handleLocationChange(event:Event):void {
			var location:String = webView.location;
			if (location.indexOf(FacebookURLDefaults.LOGIN_FAIL_URL) == 0 || location.indexOf(FacebookURLDefaults.LOGIN_FAIL_SECUREURL) == 0) {
				webView.removeEventListener(Event.COMPLETE, handleLocationChange);
				webView.removeEventListener(LocationChangeEvent.LOCATION_CHANGE, handleLocationChange);
				callback(null, FacebookDataUtils.getURLVariables(location).error_reason);
				
				userClosedWindow =  false;
				webView.dispose();
				webView = null;
			} else if (location.indexOf(FacebookURLDefaults.LOGIN_SUCCESS_URL) == 0 || location.indexOf(FacebookURLDefaults.LOGIN_SUCCESS_SECUREURL) == 0) {
				webView.removeEventListener(Event.COMPLETE, handleLocationChange);
				webView.removeEventListener(LocationChangeEvent.LOCATION_CHANGE, handleLocationChange);
				callback(FacebookDataUtils.getURLVariables(location), null);
				
				userClosedWindow =  false;
				webView.dispose();
				webView = null;
			}
		}
	}
}

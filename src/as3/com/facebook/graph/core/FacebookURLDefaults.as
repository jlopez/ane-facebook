﻿/*
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

package com.facebook.graph.core {

   /**
    * Constant class that stores all URLs
    * used when communicating with Facebook.
    * You may change these if your requests need to go though a proxy server.
    *
    */
  public class FacebookURLDefaults {
	
    /**
     * URL for calling all Graph API methods.
     *
     */
    public static var GRAPH_URL:String = 'https://graph.facebook.com';
	
    /**
     * URL for calling old-style RESTful API methods.
     *
     */
    public static var API_URL:String = 'https://api.facebook.com';
	
    /**
     * OAUTH authorization URL, used in Facebook.as to authenicate users.
     *
     */
    public static var AUTH_URL:String = 'https://graph.facebook.com/oauth/authorize';
	
	/**
	 * Dialog endpoint.
	 */
	public static var DIALOG_URL:String = "http://www.facebook.com/dialog";
	
    /**
     * Used for AIR applications only.
     * URL to re-direct to after a successfull login to Facebook.
	 *
	 * (Also used for dialogs!)
     *
     * @see com.facebook.graph.FacebookDesktop#login
     * @see http://developers.facebook.com/docs/authentication/desktop
     *
     */
	public static var LOGIN_SUCCESS_URL:String = 'http://www.facebook.com/connect/login_success.html';
	public static var LOGIN_SUCCESS_SECUREURL:String = 'https://www.facebook.com/connect/login_success.html';
	public static var LOGIN_FAIL_URL:String = 'http://www.facebook.com/connect/login_success.html?error_reason';
	public static var LOGIN_FAIL_SECUREURL:String = 'https://www.facebook.com/connect/login_success.html?error_reason';
	public static var LOGIN_URL:String = 'https://login.facebook.com/login.php';
	public static var AUTHORIZE_CANCEL:String = 'https://graph.facebook.com/oauth/authorize_cancel';
  }
}

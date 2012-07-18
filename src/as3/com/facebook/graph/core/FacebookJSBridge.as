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

package com.facebook.graph.core {
	
	import flash.external.ExternalInterface;
	
	/**
	 * Class that wraps javascript code for communicating with Facebook Javascript SDK.
	 * This class replaced the previous FBJSBridge.js file.
	 * 
	 */
	public class FacebookJSBridge {
		
		public static const NS:String = "FBAS";
		
		public function FacebookJSBridge() {
			try {
				if( ExternalInterface.available ) {
					ExternalInterface.call( script_js );	
					
					/*Get a reference to the embedded SWF (object/embed tag). Note that Chrome/Mozilla Browsers get the 'name' attribute whereas IE uses the 'id' attribute. 
					This is important to note, since it relies on how you embed the SWF. In the examples, we embed using swfObject and we have to set the attribute 'name' the 
					same as the id.*/
					ExternalInterface.call( "FBAS.setSWFObjectID", ExternalInterface.objectID );
				}
			} catch( error:Error ) {}
		}
		
		private const script_js:XML =
			<script>
				<![CDATA[
					function() {
			
						FBAS = {
							
							setSWFObjectID: function( swfObjectID ) {																
								FBAS.swfObjectID = swfObjectID;
							},
								
							init: function( opts ) {
								var options = FB.JSON.parse( opts );
								FB.init( options );
								FB.Event.subscribe( 'auth.authResponseChange', function( response ) {
									FBAS.updateSwfAuthResponse( response.authResponse );
								} );
							},
								
							setCanvasAutoResize: function( autoSize, interval ) {
								FB.Canvas.setAutoResize( autoSize, interval );
							},
								
							setCanvasSize: function( width, height ) {
								FB.Canvas.setSize( { width: width, height: height } );
							},
								
							login: function( opts ) {
								FB.login( FBAS.handleUserLogin, FB.JSON.parse( opts ) );
							},
								
							addEventListener: function( event ) {
								FB.Event.subscribe( event, function( response ) {
									FBAS.getSwf().handleJsEvent( event, FB.JSON.stringify( response ) );
								} );
							},
								
							handleUserLogin: function( response ) {
								FBAS.updateSwfAuthResponse( response.authResponse );
							},
								
							logout: function() {
								FB.logout( FBAS.handleUserLogout );
							},
							
							handleUserLogout: function( response ) {
								swf = FBAS.getSwf();
								swf.logout();
							},
								
							ui: function( params ) {
								obj = FB.JSON.parse( params );								
								method = obj.method;
								cb = function( response ) { FBAS.getSwf().uiResponse( FB.JSON.stringify( response ), method ); }
								FB.ui( obj, cb );
							},
							
							getAuthResponse: function() {
								authResponse = FB.getAuthResponse();
								return FB.JSON.stringify( authResponse );
							},
			
							getLoginStatus: function() {
								FB.getLoginStatus( function( response ) {
									if( response.authResponse ) {
										FBAS.updateSwfAuthResponse( response.authResponse );
									} else {
										FBAS.updateSwfAuthResponse( null );
									}
								} );
							},
								
							getSwf: function getSwf() {								
								return document.getElementById( FBAS.swfObjectID );								
							},
							
							updateSwfAuthResponse: function( response ) {								
								swf = FBAS.getSwf();
								
								if( response == null ) {
									swf.authResponseChange( null );
								} else {
									swf.authResponseChange( FB.JSON.stringify( response ) );
								}
							}
						};
					}
				]]>
			</script>;
		
	}
}
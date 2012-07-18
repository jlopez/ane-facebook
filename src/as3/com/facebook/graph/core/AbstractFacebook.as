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

    //import com.adobe.serialization.json.JSON;
	import com.adobe.serialization.json.JSONLib;
    import com.facebook.graph.data.Batch;
    import com.facebook.graph.data.FQLMultiQuery;
    import com.facebook.graph.data.FacebookAuthResponse;
    import com.facebook.graph.data.FacebookSession;
    import com.facebook.graph.net.FacebookBatchRequest;
    import com.facebook.graph.net.FacebookRequest;
    import com.facebook.graph.utils.FQLMultiQueryParser;
    import com.facebook.graph.utils.IResultParser;
    
    import flash.net.URLRequestMethod;
    import flash.utils.Dictionary;

    /**
    * Base class for communicating with Facebook.
    * This class is abstract and should not be instantiated directly.
    * Instead, you should use one of:
    * Facebook - For creating Canvas or other web-based applications.
    * FacebookDesktop - For creating AIR applications.
    *
    * @see com.facebook.graph.Facebook
    * @see com.facebook.graph.FacebookDesktop
    *
    */
    public class AbstractFacebook {

        /**
        * @private
        *
        */
        protected var session:FacebookSession;
		
		/**
		 * @private
		 *
		 */
		protected var authResponse:FacebookAuthResponse;
		
		/**
		 * @private
		 *
		 */
		protected var oauth2:Boolean;

        /**
        * @private
        *
        */
        protected var openRequests:Dictionary;
		
        /**
        * @private
        *
        */
		protected var resultHash:Dictionary;
		
		/**
		 * @private
		 *
		 */
		protected var locale:String;
		
		/**
		 * @private
		 *
		 */
		protected var parserHash:Dictionary;

        public function AbstractFacebook():void {
            openRequests = new Dictionary();
			resultHash = new Dictionary(true);
			parserHash = new Dictionary();
        }
		
		/**
		 * @private
		 *
		 */
		protected function get accessToken():String {
			if ((oauth2 && authResponse != null) || session != null) {
				return oauth2 ? authResponse.accessToken : session.accessToken;
			} else {
				return null;
			}
		}
		
        /**
        * @private
        *
        */
        protected function api(method:String,
                                callback:Function = null,
                                params:* = null,
                                requestMethod:String = 'GET'
                                ):void {
      		method = (method.indexOf('/') != 0) ?  '/'+method : method;
            
			if (accessToken){
				if (params == null) { params = {}; }
				if (params.access_token == null) { params.access_token = accessToken; }
			}
			
			var req:FacebookRequest = new FacebookRequest();
			
			if (locale) { params.locale = locale; }
			
            //We need to hold on to a reference or the GC might clear this during the load.
            openRequests[req] = callback;
			
            req.call(FacebookURLDefaults.GRAPH_URL + method, requestMethod, handleRequestLoad, params);
        }
		
        /**
        * @private
        * 
        */
		protected function pagingCall(url:String, callback:Function):FacebookRequest {
			var req:FacebookRequest = new FacebookRequest();
			
			//We need to hold on to a reference or the GC might clear this during the load.
			openRequests[req] = callback;
			
			req.callURL(handleRequestLoad, url, locale);
			
			return req;
		}
		
        /**
        * @private
        * 
        */
		protected function getRawResult(data:Object):Object {
			return resultHash[data];
		}
		
        /**
        * @private
        * 
        */
		protected function nextPage(data:Object, callback:Function = null):FacebookRequest {
			var req:FacebookRequest = null;
			var rawObj:Object = getRawResult(data);
			if (rawObj && rawObj.paging && rawObj.paging.next) {
				req = pagingCall(rawObj.paging.next, callback);
			} else if(callback != null) {
				callback(null, 'no page');
			}
			return req;
		}
		
        /**
        * @private
        * 
        */
		protected function previousPage(data:Object, callback:Function = null):FacebookRequest {
			var req:FacebookRequest = null;
			var rawObj:Object = getRawResult(data);
			if (rawObj && rawObj.paging && rawObj.paging.previous) {
				req = pagingCall(rawObj.paging.previous, callback);
			} else if(callback != null) {
				callback(null, 'no page');
			}
			return req;
		}

        /**
        * @private
        * 
        */
        protected function handleRequestLoad(target:FacebookRequest):void {
            var resultCallback:Function = openRequests[target];
            if (resultCallback === null) {
                delete openRequests[target];
            }

			if (target.success) {
				var data:Object = ('data' in target.data) ? target.data.data : target.data;
				resultHash[data] = target.data; //keeps a reference to the entire raw object Facebook returns (including paging, etc.)
				if (data.hasOwnProperty("error_code")) {
					resultCallback(null, data);
				} else {
					if (parserHash[target] is IResultParser) {
						var p:IResultParser = parserHash[target] as IResultParser;
						data = p.parse(data);
						parserHash[target] = null;
						delete parserHash[target];
					}
					resultCallback(data, null);
				}
			} else {
				resultCallback(null, target.data);
			}

            delete openRequests[target];
        }

        /**
        * @private
        *
        */
        protected function callRestAPI(methodName:String,
                                    callback:Function = null,
                                    values:* = null,
                                    requestMethod:String = 'GET'
                                    ):void {

			if (values == null) { values = {}; }
			values.format = 'json';

			if (accessToken) {
				values.access_token = accessToken;
			}
			
			if (locale) { values.locale = locale; }

            var req:FacebookRequest = new FacebookRequest();
			
			
            /*
      		We need to hold on to a reference
      		or the GC might clear this during the load.
      		*/
            openRequests[req] = callback;
			
			//keeping a reference to parser using the queries string as key, need to re-key to FacebookRequest so it can reference parser when call completes
			if (parserHash[values["queries"]] is IResultParser) {
				var p:IResultParser = parserHash[values["queries"]] as IResultParser;
				parserHash[values["queries"]] = null;
				delete parserHash[values["queries"]];
				parserHash[req] = p;
			}

            req.call(FacebookURLDefaults.API_URL + '/method/' + methodName, requestMethod, handleRequestLoad, values);
        }

        /**
        * @private
        *
        */
		protected function fqlQuery(query:String, callback:Function=null, values:Object=null):void {
			
			for (var n:String in values) {
				query = query.replace(new RegExp('\\{'+n+'\\}', 'g'), values[n]);
			}
			
			callRestAPI('fql.query', callback, {query:query});
		}
		
		/**
		 * @private
		 *
		 */
		protected function fqlMultiQuery(queries:FQLMultiQuery, callback:Function=null, parser:IResultParser=null):void {
			
			//defaults to FQLMultiQueryParser
			parserHash[queries.toString()] = parser != null ? parser : new FQLMultiQueryParser();
			
			callRestAPI('fql.multiquery', callback, {queries:queries.toString()});
		}
		
		/**
		 * @private
		 * 
		 */
		protected function batchRequest(batch:Batch, callback:Function=null):void {			
			if (accessToken) {
				var request:FacebookBatchRequest = new FacebookBatchRequest(batch, callback);
				resultHash[request] = true;
				request.call(accessToken);
			}
		}
		
        /**
        * @private
        *
        */
        protected function deleteObject(method:String, callback:Function = null):void {
            var params:Object = {method:'delete'};
            api(method, callback, params, URLRequestMethod.POST);
        }

        /**
        * @private
        *
        */
        protected function getImageUrl(id:String, type:String = null):String {
            return FacebookURLDefaults.GRAPH_URL
                            + '/'
                            + id
                            + '/picture'
                            + (type != null?'?type=' + type:'');
        }
    }
}

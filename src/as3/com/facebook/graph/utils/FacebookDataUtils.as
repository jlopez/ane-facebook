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

package com.facebook.graph.utils {
	import flash.net.URLVariables;

    /**
    * Utility class used
    * to parse Facebook data into corresponding ActionScript types.
    *
    */
    public class FacebookDataUtils {
		
        /**
        * Attempts to convert the various Facebook date formats
        * to a Date object.
        *
        * Supported formats are:
        * 1270706413 (unix timestamp), in Seconds
        * 2010-03-20T22:46:41+0000 (ISO 8601)
        * 11/30/1973
        *
        */
        public static function stringToDate(value:String):Date  {
            if (value == null) { return null; }

            //###########################
            //Check for different date formats
            //###########################

            //If we have unix timestamp, parse it first
            //We need to convert this time to milliseconds, from seconds.
            if (/[^0-9]/g.test(value) == false) {
                return new Date(parseInt(value)*1000);
            }

            //Parse dates in this format: 11/30/1973 or 10/30
			//Most likey will be a users birthday.
            if (/(\d\d)\/(\d\d)(\/\d+)?/ig.test(value)) {
				var datePeices:Array = value.split('/');
				if (datePeices.length == 3) {
					return new Date(datePeices[2], Number(datePeices[0])-1, datePeices[1]);
				} else {
					return new Date(0, Number(datePeices[0])-1, datePeices[1]);
				}
            }

            /*
			Parse dates in this format: 2010-03-20T22:46:41+0000 (ISO 8601)
            http://www.w3.org/TR/NOTE-datetime

			Note this does not match the entire date,
            just that significant portion exists.

            Also does not match smaller format dates,
            only full date / times with time zones
			*/
            if (/\d{4}-\d\d-\d\d[\sT]\d\d:\d\d(:\d\d)?[\.\-Z\+]?(\d{0,4})?(\:)?(\-\d\d:)?/ig.test(value)) {
                return iso8601ToDate(value);
            }

            //We don't know the format, let Date try and parse it.
            return new Date(value);
        }

        /**
        * @private
        *
        */
        protected static function iso8601ToDate(value:String):Date {
            var parts:Array = value.toUpperCase().split('T');

            var date:Array = parts[0].split('-');
            var time:Array = (parts.length <= 1) ? [] : parts[1].split(':');

            var year:uint = date[0]=='' ? 0 : Number(date[0]);
            var month:uint = date[1]=='' ? 0 : Number(date[1] - 1);
            var day:uint = date[2]=='' ? 1 : Number(date[2]);
            var hour:int = time[0]=='' ? 0 : Number(time[0]);
            var minute:uint = time[1]=='' ? 0 : Number(time[1]);

            var second:uint = 0;
            var millisecond:uint = 0;

            if (time[2] != null) {
                var index:int = time[2].length;

                if (time[2].indexOf('+') > -1) {
                    index = time[2].indexOf('+');
                } else if (time[2].indexOf('-') > -1) {
                    index = time[2].indexOf('-');
                } else if (time[2].indexOf('Z') > -1) {
                    index = time[2].indexOf('Z');
                }

                if (!isNaN(index)) {
                    var temp:Number = Number(time[2].slice(0, index));
                    second = temp<<0;
                    millisecond = 1000 * ((temp % 1) / 1);
                }

                if (index != time[2].length) {
                    var offset:String = time[2].slice(index);
                    var userOffset:Number =
                            new Date(year, month, day).getTimezoneOffset() / 60;

                    switch (offset.charAt(0)) {
                        case '+' :
                        case '-' :
                            hour -= userOffset + Number(offset.slice(0));
                            break;
                        case 'Z' :
                            hour -= userOffset;
                            break;
                    }
                }
            }

            return new Date(year, month, day, hour, minute, second, millisecond);
        }

        /**
        * Utility method to convert a Date object
		* to seconds since Jan 1, 1970 for use on Facebook.
        *
        */
        public static function dateToUnixTimeStamp(date:Date):uint {
            return date.time/1000;
        }

        /**
        * Converts a multidimensional array into a one dimensional array.
        * Used to ensure that ExtendedPermissions
        * passed to Facebook are correct.
        *
        * @param source Array to flatten.
        *
        */
        public static function flattenArray(source:Array):Array {
            if (source == null) { return []; }
            return FacebookDataUtils.internalFlattenArray(source);
        }

		/**
		 *
		 * Obtains the query string from the current HTML location
		 * and returns its values in a URLVariables instance.
		 *
		 */
		public static function getURLVariables(url:String):URLVariables {
			var params:String;
			
			// hax0rz
			if (url.indexOf("#_=_") != -1) {
				var p:String = url.replace("#_=_", "");
				if (p.indexOf("?") == -1) {
					params = "";
				} else {
					params = p.slice(url.indexOf('?') + 1);
				}
			} else if (url.indexOf('#') != -1) {
				params = url.slice(url.indexOf('#') + 1);
			} else if (url.indexOf('?') != -1) {
				params = url.slice(url.indexOf('?') + 1);
			}
			
			var vars:URLVariables = new URLVariables();
			if (params.length > 0) vars.decode(params);
			
			return vars;
		}

        /**
        * @private
        *
        */
        private static function internalFlattenArray(source:Array,
                                                    destination:Array = null
                                                    ):Array {

            if (destination == null) { destination = []; }

            var l:uint = source.length;
            for (var i:uint=0;i<l;i++) {
                var item:Object = source[i];
                if (item is Array) {
                    FacebookDataUtils.internalFlattenArray(item as Array,
                                                        destination
                                                        );
                } else {
                    destination.push(item);
                }
            }
            return destination;
		}
    }
}

/*
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * This file simply allows timezone-js to work with jQuery instead of fleegix
 * (c) 2011 Viraj Sanghvi (vsanghvi@gmail.com)
 */
(function () {

	// Check if timezone-js is available
    if(!timezoneJS || !timezoneJS.timezone) {
        throw new Error('Must include timezone-js/date.js before including jquery-timezone-js'); 
    }

    // define override
    timezoneJS.timezone.loadZoneFile = function (fileName, opts) {
		// standard check for base file path
        if (typeof this.zoneFileBasePath == 'undefined') {
            throw new Error('Please define a base path to your zone file directory -- timezoneJS.timezone.zoneFileBasePath.');
        }

		// construct name of file we're looking for on our server
        var url = this.zoneFileBasePath + '/' + fileName;

		// complete ajax request
        var self = this;
        jQuery.ajax({
            url: url,
            async: false,
            dataType: 'text',
            success: function (str) {
		self.parseZones(str);
                return true;
            },
            error: function () {
                throw new Error('Error retrieving "' + url + '" zoneinfo file.');
            }
        });

		// don't wait for success to claim completion - solves issue with requests
		// for the tz file
		// TODO: make this suck less
        self.loadedZones[fileName] = true;
    };
})();

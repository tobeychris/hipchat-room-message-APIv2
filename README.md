hipchat-room-message-APIv2
==========================

This is a simple perl script that will use Hipchat's API v2 to message a room after passing in the room name, authentication token and a message. Also includes features for selecting the colour, notifying the room, passing in an html message, using a proxy and using API v1 should you so choose.

This script was developed in a CentOS 6.4 environment and has not been tested anywhere else.

Sample Script Output:
This script will send a notification to hipchat.

	Usage:
		-room      Hipchat room name or ID.                      Example: '-room "test"'
		-token     Hipchat Authentication token.                 Example: '-token"abc"'
		-message   Message to be sent to room.                   Example: '-message"Hello World!"'
		-type      (Optional) Hipchat message type (text|html).  Example: '-type "text"'                   (default: text)
		-API       (Optional) Hipchat API Version. (v1|v2).      Example: '-type "v2"'                     (default: v2)
		-notify    (Optional) Message will trigger notification. Example: '-notify "true"'                 (default: false)
		-colour    (Optional) Message colour (y|r|g|p|g|random)  Example: '-colour "green"'                (default: yellow)
		-from      (Optional) Name message is to be sent from.   Example: '-from "Test"'                   (only used with APIv1)
		-proxy     (Optional) Network proxy to use.              Example: '-proxy "http://127.0.0.1:3128"'

	Basic Example:
		hipchat.pl -room "test" -token "abc" -message "Hello World!" 

	Full Example:
		hipchat.pl -room "test" -token "abc" -message "Hello World!" -type text -api v2 -notify true -colour green -proxy http://127.0.0.1:3128

		
Sample Successful Call:
>$hipchat.pl -room Jenkins -token abc -message 'Hello World!' -colour green -proxy http://127.0.0.1:3128 
Hipchat notification posted successfully.

Sample Unsuccessful Call (bad token):
>$hipchat.pl -room Jenkins -token abd -message 'Hello World!' -colour green -proxy http://127.0.0.1:3128 
Hipchat notification failed!
401 Unauthorized

#!/usr/bin/perl
#
# Perl script to send a notification to hipchat using either the REST API v1 or v2.
#
# Created by Chris Tobey.
#

use warnings;
use strict;
use Getopt::Long;
use LWP::UserAgent;
use JSON;

my $usage = "This script will send a notification to hipchat.\n
\tUsage:
\t\t-room      Hipchat room name or ID.                      Example: '-room \"test\"'
\t\t-token     Hipchat Authentication token.                 Example: '-token \"abc\"'
\t\t-message   Message to be sent to room.                   Example: '-message \"Hello World!\"'
\t\t-type      (Optional) Hipchat message type (text|html).  Example: '-type \"text\"'                   (default: text)
\t\t-API       (Optional) Hipchat API Version. (v1|v2).      Example: '-type \"v2\"'                     (default: v2)
\t\t-notify    (Optional) Message will trigger notification. Example: '-notify \"true\"'                 (default: false)
\t\t-colour    (Optional) Message colour (y|r|g|p|g|random)  Example: '-colour \"green\"'                (default: yellow)
\t\t-from      (Optional) Name message is to be sent from.   Example: '-from \"Test\"'                   (only used with APIv1)
\t\t-proxy     (Optional) Network proxy to use.              Example: '-proxy \"http://127.0.0.1:3128\"'
\t\t-host      (Optional) HipChat server to use.             Example: '-host \"https://hipchat.company.net\"'
\n\tBasic Example:
\t\thipchat.pl -room \"test\" -token \"abc\" -message \"Hello World!\" 
\n\tFull Example:
\t\thipchat.pl -room \"test\" -token \"abc\" -message \"Hello World!\" -type text -api v2 -notify true -colour green -proxy http://127.0.0.1:3128
\n\tIf set, the following environment variables will be used for default values, but will be overridden by command line parameters:
\t\tHIPCHAT_ROOM, HIPCHAT_TOKEN, HIPCHAT_FROM, HIPCHAT_API, HIPCHAT_PROXY, HIPCHAT_HOST
\n";

my $optionRoom         = $ENV{HIPCHAT_ROOM} || "";
my $optionToken        = $ENV{HIPCHAT_TOKEN} || "";
my $optionMessage      = "";
my $optionFrom         = $ENV{HIPCHAT_FROM} || "";
my $optionType         = "";
my $optionAPI          = $ENV{HIPCHAT_API} || "";
my $optionProxy        = $ENV{HIPCHAT_PROXY} || "";
my $optionNotify       = "";
my $optionColour       = "";
my $optionDebug        = $ENV{HIPCHAT_DEBUG} || "";
my $optionHipchatHost  = $ENV{HIPCHAT_HOST} || "https://api.hipchat.com";
my $hipchat_url        = "";
my $hipchat_json       = "";
my $message_limit      = "";
my @valid_colours      = qw/yellow red green purple gray random/;
my $colour_is_valid    = "";
my $default_colour     = "";
my @valid_types        = qw/html text/;
my $type_is_valid      = "";
my $default_type       = "";
my @valid_APIs         = qw/v1 v2/;
my $api_is_valid       = "";
my $default_API        = "";
my $ua                 = "";
my $request            = "";
my $response           = "";
my $exit_code          = "";

#Set some options statically.
$default_colour        = "yellow";
$default_API           = "v2";
$default_type          = "text";
$message_limit         = 10000;

#Get the input options.
GetOptions( "room=s"         => \$optionRoom,
            "token=s"        => \$optionToken,
            "message=s"      => \$optionMessage,
            "from=s"         => \$optionFrom,
            "type=s"         => \$optionType,
            "api=s"          => \$optionAPI,
            "proxy=s"        => \$optionProxy,
            "host=s"         => \$optionHipchatHost,
            "notify=s"       => \$optionNotify,
            "colour|color=s" => \$optionColour,
            "debug=s"        => \$optionDebug) || die ("$usage\n");;

##############################
## VERIFY OPTIONS
##############################

#Check to verify that all options are valid before continuing.

if ($optionRoom eq "")
{
   print "\tYou must specify a Hipchat room!\n";
   die ("$usage\n");
}

if ($optionToken eq "")
{
   print "\tYou must specify a Hipchat Authentication Token!\n";
   die ("$usage\n");
}

if ($optionMessage eq "") 
{
   print "\tYou must specify a message to post!\n";
   die ($usage);
}

#Check that the API version is valid.
if ($optionAPI eq "") 
{
   $optionAPI = $default_API;
}
foreach my $api (@valid_APIs)
{
   if (lc($optionAPI) eq $api)
   {
      $api_is_valid = 1;
      $optionAPI = $api;
      last;
   }
}
if (!$api_is_valid)
{
   print "\tYou must select a valid API version!\n";
   die ("$usage\n");
}

#Check that the From name exists if using API v1.
if ($optionFrom eq "") 
{
   if ($optionAPI eq "v1")
   {
      print "\tYou must specify a From name when using API v1!\n";
      die ($usage);
   }
}

#Check that the message is shorter than $message_limit characters.
if (length($optionMessage) > $message_limit)
{
   print "\tMessage must be $message_limit characters or less!\n";
   die ("$usage\n");   
}

#Check that the message type is valid.
if ($optionType eq "") 
{
   $optionType = $default_type;
}
foreach my $type (@valid_types)
{
   if (lc($optionType) eq $type)
   {
      $type_is_valid = 1;
      $optionType = $type;
      last;
   }
}
if (!$type_is_valid)
{
   print "\tYou must select a valid message type!\n";
   die ("$usage\n");
}

#Check if the notify option is set, else turn it off.
if (lc($optionNotify) eq "y" || lc($optionNotify) eq "yes" || lc($optionNotify) eq "true")
{
   if ($optionAPI eq "v1")
   {
      $optionNotify = "1";
   }
   else
   {
      $optionNotify = "true";
   }
}
else
{
   $optionNotify = "false";
}

#Check that the colour is valid.
if ($optionColour eq "") 
{
   $optionColour = $default_colour;
}
foreach my $colour (@valid_colours)
{
   if (lc($optionColour) eq $colour)
   {
      $colour_is_valid = 1;
      $optionColour = $colour;
      last;
   }
}
if (!$colour_is_valid)
{
   print "\tYou must select a valid colour!\n";
   die ("$usage\n");
}

##############################
### SUBMIT THE NOTIFICATION ##
##############################

#Setup the User Agent.
$ua = LWP::UserAgent->new;

#Set the default timeout.
$ua->timeout(10);

#Set the proxy if it was specified.
if ($optionProxy ne "")
{
   $ua->proxy(['http', 'https', 'ftp'], $optionProxy);
}

#Submit the notification based on API version
if ($optionAPI eq "v1")
{
   $hipchat_url = "$optionHipchatHost\/$optionAPI\/rooms/message";

   $response = $ua->post($hipchat_url, {
         auth_token=> $optionToken,
         room_id => $optionRoom,
         from => $optionFrom,
         message => $optionMessage,
         message_format => $optionType,
         notify => $optionNotify,
         color => $optionColour,
         format => 'json',
      });
} 
elsif ($optionAPI eq "v2")
{
   $hipchat_url = "$optionHipchatHost\/$optionAPI\/room/$optionRoom/notification?auth_token=$optionToken";
   $hipchat_json = encode_json({
      color    => $optionColour,
      message  => $optionMessage,
      message_format => $optionType,
      notify => $optionNotify,
   });
   $request = HTTP::Request->new(POST => $hipchat_url);
   $request->content_type('application/json');
   $request->content($hipchat_json);

   $response = $ua->request($request);
}
else
{
   print "The API version was not correctly set! Please try again.\n";
}

#Check the status of the notification submission.
if ($response->is_success)
{
   print "Hipchat notification posted successfully.\n";
}
else
{
   print "Hipchat notification failed!\n";
   print $response->status_line . "\n";
}

#Print some debug info if requested.
if ($optionDebug)
{
   print $response->decoded_content . "\n";
   print "URL            = $hipchat_url\n";
   print "JSON           = $hipchat_json\n";
   print "auth_token     = $optionToken\n";
   print "room_id        = $optionRoom\n";
   print "from           = $optionFrom\n";
   print "message        = $optionMessage\n";
   print "message_format = $optionType\n";
   print "notify         = $optionNotify\n";
   print "color          = $optionColour\n";
}

#Always exit with 0 so scripts don't fail if the notification didn't go through.
#Will still fail if input to the script is invalid.

$exit_code = 0;
exit $exit_code;

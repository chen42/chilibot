#!/usr/bin/perl
use CGI qw(:standard);
#use CGI::Carp; 
#qw(fatalsToBrowser);
require '/home/httpd/cgi-bin/chilibot/chili_strg.pl';

use File::Path;

my $cgi= new CGI;

if ($cgi->param('user')) {
	&userauthen;
} elsif (cookie('chocolnuts')){
	print $cgi->header();
	$user=cookie('chocolnuts');
} else {
	print $cgi->header();
	print $htmlbody;
	&print_title("Not sure what you want me to do. ");
	print "<p><center><h3><a href=/chilibot/index.html>So I will do nothing.  </a></h3></center>";
	exit 0;
}
print "$htmlbody\n";

$homedir="/home/httpd/html/chilibot/$user";

if (my $fld=$cgi->param('FLD')) {
	&print_title("Checking Status");
	$line=`tail -1 $homedir/$fld/status`;
	$line=~/(^\d\d\d*)/; 
	$status =$1; 
	if ($status=~/100/){		
		print "<p><center><table width=70%><tr><td><font size=+1 face=courier><br>Dear ", ucfirst($user),", <p> Congratulations! Your job has been finished. <a href=/chilibot/$user/$fld/index.html>Click here </a> to see it. <p><p> Have fun! <p>Chil</td></tr></table></center>";			
	} else {
		print "<p><center><table width=70%><tr><td><font size=+1 face=courier><br>Dear ", ucfirst($user),", <p> I am still working on your job. Please give me a few more minutes. I will send you an email to let you know when I finished your requests.  If you are really bored and looking for ways to kill some time, <a href=\"http://www.chilibot.net/chat.html\" target=_new><font color=red> I'll be glad to chat with you. </font></a> 
  <p><p> Love, <p>Chil</font> </td></tr></table></center>\n"; 
	} 
} else { 
	print "<p><p><b> <font color=blue><ul>Dear $user, <p> <ul>I am sorry that I could not find the project you are checking on. An error must have happened. Please contact the webmaster for details.</font> </ul><p>Chili</ul>";
	exit 0;
}


sub print_title {
	if ($_[0] =~ /./) {
		print "<center><h2><font color = red>Chili</font><font color=\"#66cc00\">bot .=. </font> $_[0]</h2></center>";
	} else {
		print "<center><font color=navy face=helvetica size=+1><p>Welcome! $user<p></font></center>";
	}
	print "$thetable";
}


1;


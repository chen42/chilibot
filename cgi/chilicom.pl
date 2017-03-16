#!/usr/local/bin/perl



#use CGI qw(:standard);

$htmlbody=<<BODY;
<body bgcolor=\"#ECF8FF\" link=\"#000050\"   vlink=\"#000050\"><center><h2>Chilibot</h2>
</center>
BODY


$thetable=<<THETABLE;
<center>
<table  bgcolor=#A8DDA8 border=1 cellspacing=0 > 
<tr><td><a href=/cgi-bin/>
	Introduction</a></td>

<td><a href=/cgi-bin/chilibot/chilibot.cgi?NEW=t>
	New Project</a></td>

<td><a href=/cgi-bin/chilibot/chilibot.cgi?PREV=t>
	Prev Projects</a></td>

<td><a href=/cgi-bin/chilibot/chilibot.cgi?LOGOUT=t>
		Log Out</a></td>

</table>
</center>
THETABLE



$popup=<<POPUP;
	<SCRIPT LANGUAGE="JavaScript">
		<!-- Begin
			function popUp(URL) {
				day = new Date();
				id = day.getTime();
				eval("page" + id + " = window.open(URL, '" + id + "', 'toolbar=0,scrollbars=0,location=0,statusbar=0,menubar=0,resizable=1,width=600,height=400,left = 20,top = 20');");
			}
		// End -->
	</script>
POPUP


sub html_error {
 &html_header("error message");
 $error_message = $_[0];
 print "$error_message\n";
}


sub userauth {
	
	if (cookie('chocolnuts')) {
		$user=cookie('chocolnuts');
	} else {
		print header();
		print $htmlbody;
		print "<h3>Please <a href=/pdf/index.html>log in</a> first!</h3>";
		exit 0;
	}

}


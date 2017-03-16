# chili_subs.pl

# contains the following subs:
# checkcookies
# clean_sentence


sub checkcookie {
	
	if (cookie('chocolnuts')) {
		$user=cookie('chocolnuts');
	} else {
		print header();
		print $htmlbody;
		print "<h3>Please <a href=/index.html>log in</a> first!</h3>";
		exit 0;
	}
}

sub clean_sentence {

	$_ = shift;
	#print "in clean_sentence sub: $_ , \n<br>";
	$_=~ s/\s+//; # it will be done again but this is necessary for the following ^ matchings
 	$_ =~ s/\s*,/ ,/g; #prepare for grep / genea /
   	$_ =~ s/(^Thus , |^Here , |^In addition *,* |^Additionally , |^Taken together , |^However , |^Furthermore , |^Further , |^In conclusion , |^In summary , |^Similarly , |^Moreover , |^Therefore , )/<font size=-1 color=grey>$1<\/font>/; #should be positioned before the "that" deletion
   	$_ =~ s/^On the contrary , |^On the other hand , |^In contrast , |^For example , |^In this study *, */<font size=-1 color=grey>$1<\/font>/;
   	$_ =~ s/Conclusions*: |Aims*:|Results: |Methods: |Purpose: |Objective: |BACKGROUND: |Introduction:*//i;
	$_ =~ s/^To .*//;
	$_ =~ /(.+?)that/;
	my $leading=length($1);
	if ((1< $leading) && ($leading < 55)) {
		#print "$leading, $_ ,<p>\n";
#		$_ =~ s/(.+ suggest that ,*)/<font size=-1 color=grey>$1<\/font>/; #These data suggest that
#		$_ =~ s/(.+ conclude that ,*)/<font size=-1 color=grey>$1<\/font>/; #These data suggest that
#		$_ =~ s/(.+ demonstrate.* that ,*)/<font size=-1 color=grey>$1<\/font>/; #These data suggest that
#		$_ =~ s/(.+ show that ,*)/<font size=-1 color=grey>$1<\/font>/; #These data suggest that
#		$_ =~ s/(.+ propose that ,*)/<font size=-1 color=grey>$1<\/font>/; #These data suggest that
		$_ =~ s/(.+? that ,*)/<font size=-1 color=grey>$1<\/font>/; #These data suggest that
	}
   	$_ =~ s/ also / /;
   	$_ =~ s/(but not .*?,)/<font size=-1 color=grey>$1<\/font>/;
   	$_ =~ s/(but not .*?\.$)//; 
	$_ =~ s/^\s+//;
	$_ =~ s/\s+/ /g; #reduce double space
	return ($_);
}

1;




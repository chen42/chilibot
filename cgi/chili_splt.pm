#!/usr/bin/perl

package chili_splt;

sub splitter {
	my ($self, $pmid, $l) = @_; 
=comment
	# deal with slash in text;
	if ($_ =~ m|(\s\S+)/(\S+\s)|) {
		$head=$1;
		$tail_ori=$tail=$2;		
		$before=$head."/".$tail;
		# NT-3/4 -> NT-3 and NT-4
		if ( ($tail=~ /^\d+/) && ($head =~ /(^\D+)\d+/) ) {
			$tail = $1.$tail;
		}
		if ($tail =~ /ml|ul|kg|\/\$g|min|sec|hr/i) {
			$middle="/";
		} elsif ($before =~ m|[+-]/[+-]|) { # -/- -> preserve 
			$middle="/";
		} elsif (($head =~ / \d+/) && ($tail =~ /\d+/)){			
			$middle="/";
		} else {
			$middle =" AND ";
		}
		#print "$head\/$tail -> $head$middle$tail \n";
		
		$_ =~ s|$head\/$tail_ori|$head$middle$tail|;
		#print "$_\n";
	}
=cut
		
	#capture numbers
	$l=~ s/([0-9])\.(\d+)/$1P_O_I_N_T$2/g;
		#capture things like E. coli, C. elegans
	$l=~ s/([A-Z])\.(\s*[a-z])/$1P_O_I_N_T$2/g;
		#capture vs.
	$l=~ s/\bvs\./vsP_O_I_N_T/g;
	$l=~ s/\be\.g\./eP_O_I_N_TgP_O_I_N_T/g;
	$l=~ s/\si\.e\./iP_O_I_N_TeP_O_I_N_T/g;
		#capture i.c.v. injection 
	$l=~ s/(\w+)\.(\w+)\.(\s+)([a-z])/$1P_O_I_N_T$2P_O_I_N_T$3$4/g;
	$l=~ s/(\w)\.(\w)/$1P_O_I_N_T$2/g;
	$l=~ s/(\w)\.(\))/$1P_O_I_N_T$2/g; #special case (1.7mg/kg, s.c.)
	$l=~ s/= *\./=P_O_I_N_T/g;
	$l=~ s/> *\./>P_O_I_N_T/g;
	$l=~ s/< *\./<P_O_I_N_T/g;
	$l=~ s/; however,/\./g;
	$l=~ s/, however,//g;
	$l=~ s/; whereas, */\. P_O_I_N_T P_O_I_N_T P_O_I_N_T /g;
	$l=~ s/ and that /\./g; ## need to be verified
	$l=~ s/, whereas,* /\. P_O_I_N_T P_O_I_N_T P_O_I_N_T /g;
	$l=~ s/; /\./g;
#	$l=~ s/\((.+?)\)/ $1 /g; #delete (xxx)
	$l=~s/ +/ /g;
	$l=~ s/\./\.\n/g; #splitter
	$l=~ s/P_O_I_N_T/\./g;
	if ($pmid eq "google") {
		return $l;
	} else {
		my $abs_file=">/home/httpd/html/chilibot/ABS/ID_$pmid";
		#print "$abs_file";
		open (TEXT, "$abs_file") || die;
		print TEXT "$l";
		close (TEXT);
		return 1;
	}
}

1;

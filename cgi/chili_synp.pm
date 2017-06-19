#!/usr/bin/perl
package chili_synp;

require '/home/httpd/cgi-bin/chilibot/chili_subs.pl';
my $abs_dir="/home/httpd/html/chilibot/ABS";
sub synopsis {
	my ($self, $project, $symb, $replace, $ii, $total) = @_;
	my (%answer, %weight);

	open (PKEY, "cat $project/synopkey|") if (-e "$project/synopkey");
	while (<PKEY>){
		$_=~s/\s+;\s+/;/g;
		$_=~s/\s+/ /g;
		@synopkeys=split(/;/, $_);
	}

	open (SYNPFILE, "$project/synop_$symb");
	@synoplines=<SYNPFILE>;
	foreach (@synoplines){
		next if ($_ =~/^\s*$/);
		$words=split(/ /, $_);
		#next if ($words>30 && $#synoplines>50);
		last if ($countSynopSent>100);
		#$_ =~ s/($replace)/$1 x_ $symb _y/ig if ($replace ne "");
		$_=~/(\d+)::: (.+)/;
		$s_key=$1; #used to allow more then one sentences to be used from the same abstract. but not functinal anymore
		$answer{$s_key}=&clean_sentence($2);
		$weight{$s_key} = 10;
		$countSynopSent++;
		# highlighting keywords specified by the user
		for (0..$#synopkeys) {
			$synopkeys[$_]=~s/^\s*|\s*$//g;
			next if ($synopkeys[$_]=~/^\s*$/);
			if ($synopkeys[$_] =~ /^-(.+)/){ 
				$weight{$s_key}-=10 if ($answer{$s_key}=~/\b($1)\b/);
				next;
			} else {
				$weight{$s_key}+=5 if ($answer{$s_key}=~s/\b($synopkeys[$_])\b/<font color= tomato><b> $1<\/b><\/font>/i);
			}
		}

		$weight{$s_key} +=9 if ($answer{$s_key} =~ /role|summary|suggest|found|show/i);
		$weight{$s_key} +=9 if ($answer{$s_key} =~ s/^summary|^conclusions//i);
		$weight{$s_key} +=4 if ($answer{$s_key} =~ /data|result|mRNA/i);
		$weight{$s_key} +=5 if ($answer{$s_key} =~ /$symb,* is /); 
		$weight{$s_key} +=3 if ($answer{$s_key} =~ /^$symb /);
		$weight{$s_key} +=3 if ($answer{$s_key} =~ /^$symb\s+is /); 
		$weight{$s_key} +=5 if ($answer{$s_key} =~ /$symb\s+is a /); #trkb (tyrosine...) is a
		$weight{$s_key} +=2 if ($answer{$s_key} =~ /$symb\s+is \S+ed /); #trkb (tyrosine...) is a
		$weight{$s_key} +=2 if ($answer{$s_key} =~ /$symb\s+\S+s /); #trkb mediates
		$weight{$s_key} -=1 if ($answer{$s_key} =~ / was | were /);
		$weight{$s_key} -=3 if ($answer{$s_key} =~ / no| not | independent | lack | fail | without | unaffected | unknown /);
		$weight{$s_key} +=3 if ($answer{$s_key} =~ s/ NOT only/ not only/);
		$weight{$s_key} -=3 if (split(/ /,$answer{$s_key}) >30);
		#print "<br>$weight{$s_key}-- $answer{$s_key}<br>";
	}

	my $output=">>$project/html/$symb.html";
	open (SYNP, $output) ||die;
	print SYNP "<p><b>Synopsis</b>";
	print SYNP "<center> <TABLE  WIDTH=\"95%\" CELLSPACING=0 CELLPADDING=1>";
	@keys = sort {$weight{$b} <=> $weight{$a}} keys %weight;	
	my $cl=$cnt=1;
	foreach (@keys) { 
		$cl *= -1;
		if ($cl<0) {
			$bgcolor="#ddeedd";
		} else {
			#$bgcolor="#ccddcc";  
			$bgcolor="";  
		}
		open(META, "$abs_dir/ID_$_");
		my $meta=<META>;
		$journal=$1 if ($meta=~m|<Journal>(.+)<_Journal>|s);
		$year=$1 if ($meta=~m|<Year>(\d+)<_Year>|s);
		$answer{$_} =~ s/ not / NOT /g;
		$answer{$_} =~ s/ +,/,/g;
		#hightlighting synonyms
		$answer{$_}=~s/x_ (.+?) _y/<font color=blue> \[$1\] <\/font>/g;
		#highlighting with bold text
		$answer{$_}=~s/(\b$symb\b)/<b>$1<\/b>/ig;

		print SYNP "<TR  bgcolor=$bgcolor><TD><li> $answer{$_} ";
		print SYNP "<a href=http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&term=$_&db=PubMed target=new><font size=-1> $journal, $year </font></a>\n"; 
		print SYNP "[$weight{$_}]<p></TD></TR>\n";
		$cnt++;
		last if $cnt==16
		
	}
	print SYNP "</TABLE></center>\n"; 
	undef (%answer);
	undef (%weight);
	$countSynopSent=0;
	return (1);
}

1;

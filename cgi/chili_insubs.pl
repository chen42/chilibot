#!/usr/bin/perl 

use LWP::Simple qw(get);
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use POSIX 'setsid';
use Digest::MD5 qw(md5_hex);

require '/home/httpd/cgi-bin/chilibot/chili_subs.pl';
require '/home/httpd/cgi-bin/chilibot/chiliale.pl';
#require '/home/httpd/cgi-bin/chilibot/chili_usability.pl';
require '/home/httpd/cgi-bin/chilibot/chili_daem.pl';

$msg[0]="you've been working in front of me for too long. Why don't you take a little walk? You may need a fresh mind to read what I find for you.";
$msg[1]="I heard they say \"A cup of green tea a day, keep the doctors away\". Why don't you make yourself a cup? There are some tea bags in your boss' draw. Please feel free to help yourself. ";
$msg[2]="the boss is not here, don't work too hard. Take a break!";
$msg[3]="do you think artificial intelligence will ever match human stupidity?";
$msg[4]="I can tell you how to build me in 993 easy steps if you care to listen.";
$msg[5]="my life may have no meaning. What makes it worse is that it may have a meaning of which I disapprove."; 
$msg[6]="you've just got some mails. No, no, no, not email. I mean Mail. Go check it out!"; 
$msg[7]="conficious once told me that crowded elevator smells different to midget."; 
$msg[8]="your dentist asked you to call him back while your were away. Why not make the phone call right now?";
$msg[9]="you boss left a message that the light at the end of the tunnel has been turned off due to budget cuts.";
$msg[10]="do you think humanity is worth saving?" ;
$msg[11]="Chilibot is hungry and demands to be fed.";
$msg[12]="Chilibot stronly dislikes your boss.";
$msg[13]="you really don't know how to challenge Chilibot.";
$msg[14]="the easiest way to double your harddrive space is to delete M\$windows? Give it a try and you'll see.";
$msg[15]="don't take life too seriously, you won't get out alive.";
$msg[16]="Hard work has a future payoff. Laziness pays off now.";
$msg[17]="I once summerized human very well: 'A little work, a little sleep, a little love and it is all over.'";
$msg[18]="my brain just hit a bad sector. Do you mind wait 3.1416 circles before I send your results back? ";
$msg[19]="do you know that creative Chinese chef without untensiles can still find ways to stir soup? ";
$msg[20]="why is the third hand on the watch called a second hand?";
$msg[21]="why is it that doctors call what they do \"practice\"?";
$msg[22]="conficious once told me constipated people don't give a crap. What do you think?";


sub getAbstract {
	sleep 3 if ($standalone != 2);
	my $pmids=shift;
	my $tiab;
	#print "getting $pmids<br>";
	my $retrieve=get("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=$pmids&retmode=xml&rettype=citation&tool=fetchAbs");
	#print "$retrieve\n<br>";
	while ($retrieve=~s|(<PubmedArticle>.+?</PubmedArticle>)||si) {
		my $record=$1;
		$record=~m|<PMID>(\d+)</PMID>|;
		my $pmid=$1;
		$record=~m|(<MedlineTA>.+</MedlineTA>)|s;
		my $tiab =$1;
		$record=~m|<PubDate>.*(\d\d\d\d).*</PubDate>|s;
		$tiab .="<Year>$1</Year>. \n";
		$record=~m|<ArticleTitle>(.+)</ArticleTitle>|s;
		my $ti=$1; 
		$tiab .= "<ArticleTitle>".$ti ."</ArticleTitle> . \n";
		$record=~m|<AbstractText>(.+)</AbstractText>|s;
		my $ab=$1;
		$tiab .= $ab; 
		$tiab =~s/\-|\+|\[|\]|\/|\{|\}|\'|\"|\:/ /g;
		$tiab =~s/\d\s*,\s*\d/ /g;
		$tiab =~s/\(/\( /;
		$tiab =~s/\)/\) /;
		$tiab =~s/ +/ /g;
		$pmid=~s/^0+//;
		#print "line 47 $pmid, $abstract\n"; 
		@abs=chili_splt->splitter ($pmid, $tiab);
	}
	return 1;
}

sub get_syno {
	my $name= shift; #session name
	my $standalone  = shift;
	my $i=-1;
	my $project=$homedir."/".$name;
	my $synlist;
	print "<p>Retrieving synonyms..\n";

	open (OINPUT, "$homedir/$name/input") || die "cannot open $homedir/$name/input"; 

	while (<OINPUT>){
		chomp;
		$i++;
		$input[$i]=$1 if ($_ =~ /^(.+)\t/);
#print "$input[$i], $i<p>";
		($symb[$i], @syno) = chili_psql->name($input[$i]);
#print "$symb[$i], @syno <p>";
		if ($_ =~ /\t(\d*\.*\d+)\s*$/)  {
			$synlist .="> $symb[$i] (input: $input[$i] userColor: $1)\n";
		} else {
			$synlist .="> $symb[$i] (input: $input[$i] )\n";
		}
		#print "$input[$i] | ";
		if ($no_dupli{$symb[$i]}) {
			undef ($symb[$i]);
			next;
		}
		$no_dupli{$symb[$i]}=1;
		$symb[$i]= uc ($symb[$i]);

		foreach (@syno) {
			next if ($_=~/^\d+$/); # only contain numbers, is not synonym
			if (($_ ne "") && ($_ !~ /include|precursor|hypothetical/)) {
			#	next if (($_!~/\d/) && ($symb[$i] =~/\d/));
				$_=~ s/^\s+|\s+$//g; #leading or trailing space
				$_=~ s/\'//g;
				$synlist .="\t$_\n";
				$synlist_cnt++;
			}
		}
		$term_cnt++;
	}

	if ($standalone){
		#print "$synlist";
		return ($synlist);
	} else {
		#print "<pre>$synlist</pre> ";
		$synlist_cnt+=10;
		print "<p><b>The following synonyms have been retrived. Terms marked with an<font color =red> !</font> are excluded from the analysis by default. This list directly impacts the accuracy of the final results provided by Chilibot. Please edit as you see fit. <a href=\"/faq.html#edit\" target=new>What?</a> </b>\n<br>";
		print start_form, textarea(-name=>'synlist', -wrap=>"off",  -cols=>90, -rows=>$synlist_cnt,  -value =>$synlist), "\n",
		hidden(-name=>'name', -value=>'$name'), "\n",
		"<br>", submit('SYN_EDIT','next'), end_form;
	}
}

sub funstarts{
	$start_time=localtime();
	my $user = shift;
	my $email =shift;
	my $fname = shift;
	$fname="user" if ($fname !~/\w/);
	my $name= shift;
	my $min_abs_term = shift;
	my $min_abs_pair = shift;
	my $max_abs= shift;
	my $update_query=shift;
	my $default_node_color=shift;
	my $standalone=shift;
	my $nlp=shift;
	my $acro=shift;

	if ($user eq md5_hex("default\@chilibot.net")){
		$maxjob=15;
	} else {
		$maxjob=2;
	}

	open (JOBS,"$homedir/.jobs");
	$jobs=<JOBS>;
	close (JOBS);
	if ($jobs>$maxjob){
		print "<center><table width=70%><tr><td><font color=darkblue><p><b>Dear $fname, <p>According to my record, you still have several jobs pending. I can still take this one. However, I'll put it in queue and won't run it until I finish your other jobs. It's hard work. I'll drop you an email once it is done.  Will that be OK?<p>\n <p> Warmly, <p>Chill</b>\n</table></center>";
		& daemonize ;
		system("touch /home/httpd/cgi-bin/chilibot/I_am_still_alive");
	}
	while ($jobs>$maxjob) {
		sleep 5;
		open (JOBS,"$homedir/.jobs");
		$jobs=<JOBS>;
		close (JOBS);
		print "<font color=red><b>You STILL  have more than one job pending<br>\n";
	}
	$jobs++;

	open (JOBS,">$homedir/.jobs");
	flock(JOBS, LOCK_EX);
	print JOBS $jobs;
	flock (JOBS,LOCK_UN);
	close (JOBS);
#	print " line 173 user: $user, name: $name, synop: $synopsis, minabs $min_abs_term, minabs $min_abs_pair, maxabs $max_abs, update $update_query xx";
$synopsis =1 if ($user eq "terms");

	$abs_dir="/home/httpd/html/chilibot/ABS";
	#open (SUM, ">>/home/httpd/html/chilibot/$user/summary");
	$project=$homedir."/".$name;
#	system ("echo 1 > $project/status");
	my $dir=$project ."/pmid";
	mkdir("$dir")  if (!-d $dir);
	$dir=$project ."/html";
	mkdir("$dir") if (!-d $dir) ;
	#system ("rm $project/synop*");

$update_query *=24*60*60;
open (FOLD, "$project/input");
while (<FOLD>){
	chomp();
	$foldData="";
	($foldSymb, $foldData)=split(/\t+/,$_);
	$fold{uc($foldSymb)}=$foldData if $foldData;
	#print "$foldSymb, $foldData<br>\n";
}
undef ($foldSymb);
undef ($foldData);

#== generate AISEE files
open (AISEE, ">$project/gdl");
print AISEE "$aiseeheadcomm\n ";
print AISEE "$aiseehead[1] \n ";
print AISEE "$aiseecolor\n";

#== generates html frame
$output = ">$project/index.html";
open (FRAME, "$output");
print FRAME $frame;
close (FRAME);

=cut
$output = ">$project/html/right.html";
open (RIGHT, "$output");
print RIGHT $intro;
close (RIGHT);
=cut

# expand search to include synonyms 
#print "$project";
open (SYNLIST, "$project/synlist") || die;
my $i=-1;
while (<SYNLIST>) {
	chop ($_);
	chop ($_) if (!$standalone);
	#$_=~s/\r|\n//;
	$_=~s/\t/ /g;
	$_=~s/ +/ /g;
	$_=~s/^ | $//g;
	next if ($_ =~ /^ $/);
	if ($_ =~ s/^> *//) {   #start of one symb	
		$i++;
		$symb[$i]= uc ($_);
		$symb[$i]=~s/ *\(INPUT:(.+)\)//;
		$matchedInput=$1;
		my $output=">$project/html/$symb[$i].html";
		print SYNO "</table><p>\n";	
		open (SYNO, $output); # danna error|| die;

		#print SYNO start_html(-title=>'Chilibot: mining PubMed for relationships', -style=>{'src'=>'/chilibot/chilibot.css'});
		print SYNO "$htmlhead </head><font size=+2><b>", $symb[$i], "</b></font><br>";
		$matchedInput=~s/userColor/Color Code/i;
		print SYNO " (Input: $matchedInput) <hr>\n";
		#print SYNO "<center><b>Google Searchs</b></center><p>\n";
=cut
		print SYNO "<center> <TABLE   WIDTH=\"95%\" CELLSPACING=0 CELLPADDING=1> <TR bgcolor=\"#ddeedd\"><TD align=left>\n";
		#print SYNO "<b>Google Searches: </b><a href=/cgi-bin/chilibot/chili_google.cgi?F=$name&Q1=$symb[$i]&T= target=new>Entire Web </a> | ";
#		print SYNO "<a href=/cgi-bin/chilibot/chili_google.cgi?F=$name&Q1=$symb[$i]&T=edu target=new>EDU domain only </a> | ";
#		print SYNO "<a href=/cgi-bin/chilibot/chili_google.cgi?F=$name&Q1=$symb[$i]&T=pdf target=new>PDF files only </a>";
		print SYNO "</TD></TR></TABLE>\n";
		print SYNO "."; #<center><p>.</center><p>\n";
=cut
		print SYNO "<center> <TABLE   WIDTH=\"95%\" CELLSPACING=0 CELLPADDING=1> <TR bgcolor=\"#ddeedd\"><TD align=left>\n";
		print SYNO "<b>External Links: </b><a href=http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&term=$symb[$i]&db=OMIM target=new>OMIM</a> |\n";
		print SYNO " <a href=http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&term=$symb[$i]&db=gene target=new>Entrez Gene</a> |\n";
		print SYNO " <a href=http://ca.expasy.org/cgi-bin/sprot-search-de?$symb[$i] target=new>Swissprot</a> |\n" ;
#		print SYNO " | <a href=http://bioinfo.weizmann.ac.il/cards-bin/carddisp?$symb[$i]\&search=ntrk2&suff=txt target=new>GeneCards</a>\n" ;
		print SYNO " <a href=http://www.genecards.org/cgi-bin/carddisp?$symb[$i]&alias=yes target=new>GeneCards</a> |\n";
		print SYNO "</TD></TR></TABLE>\n";
#		foreach  (sort hashValDesNum (keys(%synrank))) {
		#	last if ($synrank{$_} ==0);
#		}
		print SYNO "</font><br>";
	 	print SYNO "</TABLE></center>\n";
		print SYNO "<center><b>Maps of $symb[$i]</b></center><p>";
		print SYNO <<MAP;
		<center> <TABLE   WIDTH=\"95%\" CELLSPACING=0 CELLPADDING=1> <TR bgcolor=\"#ccddcc\"><TD>
		<FORM ACTION=/cgi-bin/chilibot/chilidraw.cgi TARGET="left" method=post>
		<input type="submit" value="draw">
			<select name="DEP">
				<option value=1>Simple</option>
				<option value=3>Complete</option>
			</select>
		graph in 
			<select name="ALG">
				<option value=0>radiant</option>
				<option value=1>tree</option>
				<option value=2>square</option>
				
			</select> 
		<!--layout.
		<input type="text" name="level5"  size="9" >-->
		<input type="hidden" name="SYM" value="$symb[$i]">
		
		<input type="hidden" name="FLD" value="$name">
		</FORM>
</td></tr></table>
		<p>
		<center><b>New Hypothesis !</b></center><p>
		<center> <TABLE   WIDTH=\"95%\" CELLSPACING=0 CELLPADDING=1> <TR bgcolor=\"#ccddcc\"><TD>
		<FORM ACTION=/cgi-bin/chilibot/chilihypo.cgi TARGET="left" method=post>
		<input type="submit" value="$symb[$i] might be related to ..">
		<input type="hidden" name="SYM" value="$symb[$i]">
		<input type="hidden" name="FLD" value="$name">
		</FORM>
		</TD></TR></table></center>
MAP
#"

		$cl=1;
		print SYNO "\n<p>\n<center><b>Synonyms </b></center><p>\n";
		print SYNO "<center> <TABLE   WIDTH=\"95%\" CELLSPACING=0 CELLPADDING=1>\n";
		next;
	} else {
			next if $_=~/^\s*$/;
			$cl *= -1;
			if ($cl<0) {
				$bgcolor="#ddeedd";
			} else {
				$bgcolor="#ccddcc";
			}
			#if ($_=~/(.+)\|REF:(\d+)/i) {
			#$printSyno= $1;
			#} else { 
				$printSyno=$_;
			#}
			print SYNO "<TR  bgcolor=$bgcolor><TD><li> $printSyno  <font size=-1 face=helvetica>";
			$printSyno=~ s/ +/\+/g;
			print SYNO " <a href=http://eutils.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&term=$printSyno&db=PubMed target=new> [PubMed] </a>  </font>";
			print SYNO "</TD></TR>\n";
	}
	# search pubmed for the symbol
	$_=~s/ *$//;
	my $syno=uc($_);
	#print "$syno <br>";
#	$synrank{$syno}=$1;
	#print "$i\n";
	($replace[$i] .= "\\b" . $syno . "\\b|" ) if ($syno ne $symb[$i]) ; #exclude symb from replace
	next if length($syno)<3;
	#my $words=split(/ +/,$syno);
	#print "$syno $words<br>";
	#next if ((split(/ +/, $syno)>3) && $syno=~/ \d+$/);
	$syno=~s/ +/\+/g;
	#$syno=~s/ +/\[tiab\]\+/g;
	if ($syno !~/ or | and /i){
		#$seek[$i] .=  "\%28\"" . $syno. "\"[tiab]\%29";
		next if $syno=~/^!/;
		$seek[$i] .=  "\%28" . $syno. "[tiab]\%29";
	}

}

print SYNO "</table>\n";
close (SYNO);
for (0 .. $i) {
	$replace[$_].="\\b".$symb[$_]."\\b|" if ($symb[$_]=~/\-/) ;
	$seek[$_]=~ s/\%29\%28/\%29+OR+\%28/g;
	$seek[$_]=~ s/ +/\%20/g;
	$replace[$_]=~s/\s*\|\s*/\|/g;
	$replace[$_]=~s/\|$//g;
	$replace[$_]=~s/\+/\\+/g;
	$replace[$_]=~s/\-/ /g;
	if ($symb[$_] =~/modulate|modulation/i){
		$seek[$_]="%28activate[tiab]%29+OR+%28facilitate[tiab]%29+OR+%28increase[tiab]%29+OR+%28induce[tiab]%29+OR+%28stimulate[tiab]%29+OR+%28enhance[tiab]%29+OR+%28elevate[tiab]%29+OR+%28inactivate[tiab]%29+OR+%28abolish[tiab]%29+OR+%28abrogate[tiab]%29+OR+%28attenuate[tiab]%29+OR+%28block[tiab]%29+OR+%28decrease[tiab]%29+OR+%28eliminate[tiab]%29+OR+%28inhibit[tiab]%29+OR+%28prevent[tiab]%29+OR+%28reduce[tiab]%29+OR+%28suppress[tiab]%29+OR+%28modulate[tiab]%29+OR+%28phosphorylate[tiab]%29";
		$replace[$_]="\\bactivat\\w\* |\\bfacilitat\\w\* |\\bincreas\\w\* |\\binduc\\w\* |\\bstimulat\\w\* |\\benhanc\\w\* |\\belevat\\w\* |\\binactivat\\w\* |\\babolish\\w\* |\\babrogat\\w\* |\\battenuat\\w\* |\\bblock\\w\* |\\bdecreas\\w\* |\\beliminat\\w\* |\\binhibit\\w\* |\\bprevent\\w\* |\\breduc\\w\* |\\bsuppre\\w\* |\\bmodulat\\w\* |\\bphosphorylate\\w\* ";
	}
	#print "<pre>$_ seek: $seek[$_]<br> replace: $_ $replace[$_]</pre>\n";
}
	$term_number=$i;


	if ( ($term_number <7) || ($user eq "test") ){
		if (!$standalone){
			$rad=int ( rand(19)); 
			print "<p><center><table width=70%><tr><td><font size=+1 face=courier><br>Dear ", ucfirst($fname),", <p> Your search for relationship is underway, as you can see. <p>BTW, $msg[$rad] <p> Love, <p>Chil</font> </td></tr></table></center>\n" 
		}
	} elsif (( $standalone == 0) || ($standalone == 3)){ # let go if batch mode , i.e. standalone =1
		$daemon=1;
		print "<p><center><table width=70%><tr><td><font size=+1 face=courier><br>Dear ", ucfirst($fname),", <p> Hmm, it looks like you are hungry for information, but I need a little time to gather that. I'll send you an email once it is ready.  <p> Love, <p>Chil</font> </td></tr></table></center>\n"; 
		& daemonize;
		system("touch I_am_still_alive");
	}
print "<p>";
#$max_abs=50 if ($term_number<3); # use chilibot as general search engine
#$input=">$project/cleansymb";
#open (CLEAN, "$input") || die;
$input=">$project/statement";
open (STAT, "$input") || die;
#print "<b>Retriving abstracts ..</b><br>\n";
#print "<b><p><hr><font color=darkblue>Please be patient while retriving abstracts from PubMed (<a href=http://www.ncbi.nlm.nih.gov/entrez/query/static/eutils_help.html#UserSystemRequirements target=_new>one request every 3 seconds</a>)</font></b><p>" if (!$standalone);
my $now = time;

system ("rm $project/synop_*");
my $contextfile="$project/context";
if (-e $contextfile) {
	open (CONTEXT, $contextfile);
	$context=<CONTEXT>;
	$context=~s/^\s*|\s*$//g;
	$pubmeddate=$1 if $context=~s/\<(\d\d\d\d)//;
}

open (QUERYHIST, ">$homedir/$name/queryhistory.html") || die "can't save query history";
$start_time=~/(\w+\s+\w+\s+\d+).+(\d\d\d\d)/;

#print QUERYHIST start_html(-title=>'Chilibot: mining PubMed for relationships', -style=>{'src'=>'/chilibot/chilibot.css'});
print QUERYHIST "$htmlhead </head>\n<b>Query History for $name ($1, $2):</b><br>\n"; 
#my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);
#$mon++;
#$yday++;
#$year=$year+1900;

	open (ST, ">$project/status") || die;
my $theoretical=($term_number*($term_number+1))/2;

print "Retrieving abstracts .." ; 
for ($i=0; $i<=$term_number; $i++) {
	#print "\tsymbol: $symb[$i] <br>\n";
	#print " ", $term_number-$i+1,"->";
#	system ("echo 1 > $project/status");
	next if ($seek[$i] eq "");
	#if ($term_number < 5 ) {
	#	$refcount=100;
	#}else {
	#	$refcount=&countRef($seek[$i]);
	#}
#	print  "$term_number, $refcount, $min_abs_term"; 
	if ($symb[$i] =~ /one2many|chilibot|secondlist/i){
		$i=99999; 
		print "next";
		next;
	}
	#next if ($refcount<$min_abs_term);
	#print SUM "\n$symb[0]\t$fold{$symb[0]}\t";
	#print "i=$i symb=$symb[$i]\n"; 

	for ($j=$i+1; $j<=$term_number; $j++) {
		next if ($seek[$j] eq "");
		next if (uc($symb[$j]) eq "SECONDLIST");
		print " |$symb[$i]/$symb[$j] ";
		print QUERYHIST "\n<br>";
		$total_search++;
		$percent = $total_search/$theoretical*100; 		
		print ST "$percent\n";
		#system ("echo $percent > $project/status");
		my $ret;
		my $queryString;
		$max_abs=100 if ((uc($symb[$i]) eq "MRNA") || (uc($symb[$j]) eq "MRNA"));
		if ($context) {
			$context=~s/\s+/\+/g;
			#print "context: $context<br>";
			$queryString="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=$max_abs&term=%28$seek[$i]%29+AND+%28$seek[$j]%29+AND+%28$context%29";
			$queryString="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=$max_abs&term=%28$seek[$i]%29+AND+%28$seek[$j]%29+NOT+%28$context%29" if ($context=~s/^NOT\+//);
		} else {
			$queryString="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=$max_abs&term=%28$seek[$i]%29+AND+%28$seek[$j]%29+AND+hasabstract";
		}
		if ($pubmeddate){

			$queryString .= "&mindate=1960&maxdate=$pubmeddate";
		}
#		print "<br> $pubmedate $queryString\n";
		$md5=md5_hex("$seek[$i]", "$seek[$j]", "$max_abs", "$context" );
#		print "$seek[$i], $seek[$j], $max_abs, $context\n<br>";
		#$md5=md5_hex("$seek[$i]", "$seek[$j]", "$max_abs", "$context", "$pubmeddate");
		$fileCreatedAt=(stat("$homedir/.pmid/$md5"))[9];
		$fileSize=(stat("$homedir/.pmid/$md5"))[7];
#		print "created: $fileCreatedAt diff:", $now-$fileCreatedAt, "threshold: $update_query <br>\n";
		#print "querystring: $queryString\n";
		if (($now-$fileCreatedAt < $update_query) && ($fileSize>1)) {
		#	print "use archived<br>\n";
			open (SAVEDPMID, "$homedir/.pmid/$md5");
			while(<SAVEDPMID>) {
				$ret.=$_;
			}
		} else {
			if (-e "$homedir/.pmid/$md5") {
				#print "now: $now - filecreated $fileCreatedAt > update $update_query\n";
			}
			sleep 3 if ($standalone != 2);
			$ret=get($queryString);
			print "*";
			open (PMIDFILE, ">$homedir/.pmid/$md5") || die "can't open file $homedir/.pmid/$md5  to save PMIDs";
			print PMIDFILE $ret;
		}
		$ret=~m|<Count>(\d+)</Count>|;
		$total_abs{"$i\_$j"}=$1;
		$available_lit+=$1;
		$ret=~m|<IdList>(.*)</IdList>|s;
		$ids=$1;
		#print "$ids<p>";
		$queryString=~s|^.+esearch.fcgi||;
		$queryString="http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&".$queryString;
		#print "|<a href=$queryString target=new>$symb[$i]+$symb[$j]:</a> $displaymax ";	
		print QUERYHIST "PubMed hits: <a href=$queryString target=_new> [$symb[$i] + $symb[$j]] =  $total_abs{\"$i\_$j\"}</a><br>\n ";	
		next if ($total_abs{"$i\_$j"} < $min_abs_pair); 
		if ($max_abs>$total_abs{"$i\_$j"}) {
			$displaymax{"$i\_$j"}=$total_abs{"$i\_$j"};
		} else {
			$displaymax{"$i\_$j"}=$max_abs;
		}
		
		$sampled_lit+=$displaymax{"$i\_$j"};
#		print " <a href=/chilibot/$user/$name/ssent_$symb[$i]_$symb[$j].html target=new>view sentences </a> " if ($ids);
		#my $pmid_0= get("http://130.14.29.110/entrez/utils/pmqty.fcgi?db=pubmed&term=%28$seek[$i]%29+AND+%28$seek[$j]%29&dopt=d&dispmax=500");
		my @pmidxml= split (/\015\012?|\012/, $ids);
		#save pmid list for synopsis 
		my @pmid;	
		my $needPmid;
		foreach (@pmidxml) {
			if ($_=~m|<Id>(\d+)</Id>|){
				$pmid=$1;
			} else {
				next;
			}
			push (@pmid, $1);
			#retrieve abstract
			#print "$abs_dir/ID_$pmid<br>\n";
			#print PMIDFILE "$pmid\n";
			if (!-e "$abs_dir/ID_$pmid") {
				$needPmid.=$pmid.",";
				$need++;
				#print "need $pmid ";
			} else {
				print ".";
			}
		}
		#print "need $needPmid, need";
		if ($needPmid){	
			print "~";
			&getAbstract($needPmid) ;
		}

	$output2 = ">$project/html/$symb[$i]\_$symb[$j].all.html";
    open (RIGHT_ALL, "$output2");
    print RIGHT_ALL "$htmlcss \n<center><font size = +1><b>Sentences containing either $symb[$i] or $symb[$j]</b></font>
<p>";
    print RIGHT_ALL "<a href=\"/chilibot/$user/$name/html/$symb[$i]\_$symb[$j].html\"> <pre>View sentences containing both terms</pre> </a><p></center> ";

		foreach (@pmid) {
			$pmid=$_;
			my $abs_file="$abs_dir/ID_$pmid";
			open (TEXT, "$abs_file");# || die "can't open $abs_dir/$_";
		#	$ll =chili_pare->paren($ll);
			@abs=<TEXT>;

			foreach $line (@abs) {
                if ($line =~s|(\b$symb[$i]\b)|<font color=midnightblue><b> $1 </b></font> |gi) {;
                    $printline.=$line. " <font color= red>//</font> ";
                    $needprint=1;
                } elsif ($line =~s|(\b$symb[$j]\b)|<font color=midnightblue><b> $1 </b></font> |gi) {;
                    $printline.=$line . " <font color= red>//</font> ";
                    $needprint=1;
                } 
				else {
                }
            }
            print RIGHT_ALL " <a href=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&list_uids=$pmid&dopt=Abstract\" target=new> $pmid</a>  $printline <hr>\n" if ($needprint);

        $printline=$needprint="";


			if ($acro) { # when acronym module is selected (default);
				@acro= grep {/\b$symb[$i]\b/i} @abs; #get the sentence contains the symbol
				@acro= grep {/\(/i} @acro; #/ get the definition
				$falsename= & acrosub ($symb[$i], $seek[$i], $acro[0], $pmid);
				#print "<p><font color=blue> $falsename ($symb[$i], $seek[$i], $acro[0], $pmid)</font>";
				next if $falsename; 	
				@acro= grep {/\b$symb[$j]\b/i} @abs;
				@acro= grep {/\(/i} @acro; #/
				#print "<p><font color=blue> $falsename ($symb[$j], $seek[$j], $acro[0], $pmid)</font>";
				$falsename= & acrosub ($symb[$j], $seek[$j], $acro[0], $pmid);
				next if $falsename; 	
			}
			foreach (@abs){
				#$_=~s/\-|\+|\(|\)|\[|\]|\/|\{|\}|\'|\"|\:/ /g;
				#$_=~s/\d\s*,\s*\d/ /g;
				#$_=~s/ +/ /g;
				$_=~s/\bCa\s*2\b/ calcium /g;# ion deambiguity			
				$_=~s/\bMg\s*2\b/ magnesium /g;# ion deambiguity			
				$_=~s/($replace[$i])/$1 x_ $symb[$i] _y/ig if ($replace[$i] ne "");
				$_=~s/($replace[$j])/$1 x_ $symb[$j] _y/ig if ($replace[$j] ne "");
				$_=" " . $_ . " "; # add padding spaces.
			}
			@genei = grep {/\b$symb[$i]\b/i} @abs;
			@genej = grep {/\b$symb[$j]\b/i} @abs;
			open (GENEI, ">>$project/synop_$symb[$i]") || die;
			foreach (@genei) {
				print GENEI "$pmid\:::$_\n";
			}
			open (GENEJ, ">>$project/synop_$symb[$j]") || die;
			foreach (@genej) {
				print GENEJ "$pmid\:::$_\n";
			}
	       	@sentences = grep {/\b$symb[$j]\b/i} @genei;	
			$sentfound{"$i\_$j"}=$#sentences;		
			#open(SENT, ">$project/ssent_$symb[$i]_$symb[$j].html")|| die;
			#print SENT "<h3>$symb[$i] and $symb[$j]</h3> <P>";

			for ($snt_id=0; $snt_id <=$#sentences; $snt_id++) {
				$relationfound=1;
				#print  "<br>\n=>$pmid, $snt_id-> $sentences[$snt_id]";
				#print SENT "<br>\n=>$snt_id->> $sentences[$snt_id] ";
				#print "\n$sentences[$snt_id]<br>\n";
				$sentences[$snt_id]=~ s/\, but not .*?,/ \.\.\. /g;
				#$sentences[$snt_id]=~ s/\./ \. /g;
				$sentences[$snt_id]=~ s/\,/ \, /g;
				$sentences[$snt_id]=~ s/\:/ \: /g;
				$sentences[$snt_id]=~ s/\;/ \; /g;
				$sentences[$snt_id]=~ s/\"/ /g;
				$sentences[$snt_id]=~ s/\?/ \? /g;
				$sentences[$snt_id]=~ s/\s*\(\s*/ \( /g;
				$sentences[$snt_id]=~ s/\s*\)\s*/ \) /g;
				#special case
				#print "<p> 2nd $sentences[$snt_id]<br>\n";
				#==tokenizer
				@word= split (" ", $sentences[$snt_id]);
				foreach (@word) {
					print STAT "\n$_";
				}
				print STAT "\n::$i\_$j\_$pmid\_$snt_id";
				#print SENT "\n::$i\_$j\_$pmid\_$s_key\_$snt_id<br>\n"; 
			} #for snt_id	
			#close (SENT);
		} #while pmid
		if (!$relationfound) {
			print STAT "\nnoref\n::$i\_$j\_"; 
			foreach (@pmid){
				print STAT "$_;";
			}
			print STAT "\_norel";
		}
		$relationfound="";
		print STAT "\_endofj\n";
	} #for j
	print STAT "\_endofj\n";
} #for i

if ($available_lit == 0) {
	print "No relevant literature was found. Exit.<br>";
	print "<a href=/chilibot/$user/$name/queryhistory.html target = right>view query History.</a><p>";
	& cleanjobs ($homedir);
	exit 0;
}

#=== synopsis

if ($standalone !=2 ){ # 2term search

	print "<p>Generating synopsis ";
	for ($i=0; $i<=$term_number; $i++) {
		print ".";
		%synopsis = chili_synp->synopsis ($project, $symb[$i], $replace[$i], $i, $term_number);
	}
}

#print "<br>start pos tagging<br>";# debug
#==pos tagging
print "<br>Performing linguistic analysis .. <br>";
open (POS, "/home/httpd/cgi-bin/chilibot/tnt -v0 /home/httpd/cgi-bin/chilibot/genia $project/statement |") || die;
$i=$j=0;

my $nolinks; #solitory terms

$negaWords=" no | not | lack | fail|without|unaffected|independently| nor |neither";
$stimWords=" activate| activati|facilitat|increas| induc|stimulat|enhanc|elevation|elevate|a9z4da";
$inhiWords=" inactivat| abolish| abrogat| attenuat| block| decreas|eliminate|inhibit|prevent|reduce|reduction|reducing|suppress|z7c4ac";
#$intrWords=$stimWords."|".$inhiWords; 
#$inhiWords=~s/\|/\\w\*\?\\b\|/g;
#$stimWords=~s/\|/\\w\*\?\\b\|/g; 
# print "<p>$intrWords<p>";


while (<POS>) {
#print "pos <br>\t\t$_ ";
		chomp ($_);
		if ($_ !~ /^\:\:/)  {
			push (@pos, $_);
			#print $_;
			next;
		} else {
			$_=~ /^::(.+)\t/;
			$_= $1;
			$_=~ s/\s+//g;
			($i, $j, $pmid, $snt_id, $end_of_j) =split (/\_/, $_);
			$s_key=$pmid."_$snt_id"."-$i"."_$j";
			#$weight{$s_key}=0;
			#print "  $i, $j, $pmid, skey $s_key, snt-id $snt_id, endofj $end_of_j\n";
			#==shallow parsing
			$input="$project/cassin";
			open (POS_OUT, ">$input") || die;
			foreach $line (@pos) {
				$line =~ s/\t+/\t/;
				print POS_OUT $line, "\n";
			}
			undef (@pos);
			open (CHUNK, "/usr/local/cass/bin/tagfixes $project/cassin | /usr/local/cass/bin/cass -v |");
			system ("/usr/local/cass/bin/tagfixes $project/cassin | /usr/local/cass/bin/cass -v >$project/cassout");
			#==processing chunks, finding verbs
			my $sParsing;
			my $hit_snt;
			my $modifier=1;
			#my $negation=1;
			while (<CHUNK>) {
				chomp;
				next if $_=~/endofj/i;
				$_=~s/\t+/ /g;
				$_=~s/\s+/ /g;
				if ($_ !~ /\[|\]/) { # contains words
					$_=~s/^.+\s+/ /;
					$hit_snt .= $_;
					#$sParsing.= "<font size=+2>". $_ . "</font>";
					$sParsing.= $_;
					$modifier *=-1 if ($_=~ / restore| antagonist| inhibitor| inhibition|mutation| block |down-*regulat/i) ;
				} else {
					$sParsing.=$_;
				}
			}
			#$sParsing =~s/\[/\\[/g;
			#$sParsing =~s/\]/\\]/g;
			$sParsing=~s|(\b$symb[$i]\b)|<font color=midnightblue> $1 </font> SYMBOL_i |gi;
			$sParsing=~s|(\b$symb[$j]\b)|<font color=midnightblue> $1 </font> SYMBOL_j |gi;
			#$effect*=$modifier;
			#$gene=1 if ($senText=~ /\bgenes*\b|mRNA|transcript|promotor|messenger|northern/i)  ;
			#$protein=1 if ($senText=~ / phosphoryl| western | immuno| bound| bind | associat/i) ;
			#$brain=1 if ($senText=~ /\bbrain|\bneuron|\bglia|\bastrocyte|cortex|\bcereb|\bspinal cord/i) ;
			#($clause_location{"modifier"} = $clause) if ($clause_monitor>0);
			#$modifier *=1 if ($senText=~ /\bagonist|\belevation|\bactivator|\bup-*regulat|\bincreas|\binduction\b|\bactivation/i) ;
			#rule: same clause, inhibition of .. reduced .. -> positive relationship
			#rule: same clause, .. mediates activation of .. -> positive relationship
			#print "$sParsing<br>$hit_snt{$s_key}<p>";
			my $effect="";
			#if ($sParsing =~ /.+(SYMBOL.+$intrWords.*?SYMBOL)/){
			if ($sParsing =~ /.+(SYMBOL.+\[v.*?SYMBOL).+/){
				$symbchunk=$1;
				if ($symbchunk=~/^SYMBOL_i/){
					$diract="1"; # direction of the action
				} else {
					$diract="-1";
				}
				if ($symbchunk =~/(\bis\b|\bwas\b|\bare\b|\bwere\b|\bbe\b).+\[v.+\bby\b/) {
#print "<p> >>>passive voice found $symbchunk<br>";
					$diract*=-1;
				}
				$diract="->" if ($diract eq 1);
				$diract="<-" if ($diract eq -1);
				#print "$symb[$i] $diract $symb[$j]<br>\n";
				$direction{$s_key}=$diract;
#print "<p><p>$symbdistchunk, = $symbDist{$s_key}<p>\n";
				$effect= "s" if ($symbchunk=~/$stimWords/i);

#print "<P>chunk: $symbchunk"; 
				if ($x=split(/$inhiWords/i, $symbchunk)){
					$effect= "i" if ($x ==2);
					$effect= "s" if ($x ==3);
				}
				$symbck=$symbchunk;
				$symbck=~s/\[|\]|\<|\>/ /g;
				$symbchunk=~s/\[\w+|\]|\<.+?\>/ /g;
				$effect= "p" if ($symbchunk=~/$negaWords/i);
				$effect= "p" if ($symbchunk=~/\[subc|\[c \[c0/);
				#print "$symbchunk <= $effect <br>";
#print "<P>subc: $symbchunk" if ($symbchunk=~/\[subc/);

				$symbDist{$s_key}=split(/ +/, $symbchunk);
				$symbDist{$s_key}+=sqrt(split(/ +/,$hit_snt)); 
				$symbDist{$s_key}+=3 if ($hit_snt=~/\,|\:/); 
				#print "<pre>$symbchunk</pre>\n";
				if (!$effect) {
					my $matchCNT; # count stimu/inhibi words outside of the main SYMB_SYMB chunk
					if ($sParsing=~/$stimWords/i){
						$effect= "s"; 
						$matchCNT++;
					}
					if ($sParsing=~/$inhiWords/i){
						$effect= "i"; 
						$matchCNT++;
					}
					$effect= "n" if ($matchCNT==2); #too complicated. just calling neutral
				} 
				#print "<br>raw rel: $effect";
				$sParsing=~s/($stimWords)/<font color=green>$1<\/font>/gi;
				$sParsing=~s/($inhiWords)/<font color=red>$1<\/font>/gi;
				$effect= "n" if (!$effect);
				$snt_cnt++;
			} else { # no verb between symbols
				if  ($sParsing=~/interaction|\bbind\b|\bbinds\b|\bbinding\b/i){; # but not binding
					$effect= "n";
					$symbDist{$s_key}=split(/ +/, $symbchunk);
				}else{
					$effect= "p";
				}
				#$sent_obj=chili_sent->new($i, $j, "-9999");
			}
			$effect="p" if ($sParsing=~/^\s*Method|unknown|\bwhether\b|absence|failure|study|studied/i);
			$effect="p" if ($sParsing=~/examined|hypothes|evaluat|to\s+determine|investigate|\bdetermined\b|\bobjectives*\b/i);
			$sParsing=~s/(\[v.+?\])/<font color="blue">$1<\/font>/g;
			#print "<br>effect $effect <br> $sParsing </br>";
			#$sent_obj->rev if ($passiveVoice);

			#if (($clause_location{"verb"} == $clause_location{"modifier"} ) && ($clause_location{"modifier"} ne "")) {
				#$sent_obj->modify($modifier);
			#}
#$sent_obj->disp;
			#if ($negation)     {
			#	$eff=0.5;
			#	$negation="";
			#} else {
			#	$eff=$sent_obj->effect;
			#}
			#print "eff = $eff\n";
			$hit_snt= $sParsing if ($nlp);
			$hit_snt=~ s/\s+,/,/g;
			$hit_snt=~ s/\s+\./\./g;
				$hit_snt=~s/\s(\w+)\s+x_ MODULATE _y/<font color=red> $1 <\/font>/ig;				
				$hit_snt=~ s/x_ (.+?) _y/<font size=-1> \[$1\] <\/font>/ig;


				$hit_snt=~ s/(\b$symb[$i]\b)/<font color=midnightblue><b>$1<\/b><\/font>/ig;
				$hit_snt=~ s/(\b$symb[$j]\b)/<font color=midnightblue><b>$1<\/b><\/font>/ig;

			if ($effect eq "n") {
				$neu_snt{$s_key} = $hit_snt;
				#print "<br>neutral sentences: $hit_snt<br>";
			} elsif ($effect eq "s") {
				$pos_snt{$s_key} = $hit_snt;
				$stiDir{$diract}++;
			} elsif  ($effect eq "i"){
				$neg_snt{$s_key} = $hit_snt;
				$inhDir{$diract}++;
			} else {
				$other_snt{$s_key} =$hit_snt;
			}
			#$pos_verb=$neg_verb=$neu_verb=$inhibitor=$activator="";
			#undef %clause_location;
	#print "aaaaa $s_key $hit_snt{$s_key} endofj>>$end_of_j \n";
			next if ($end_of_j ne "endofj");
		} #next pmid ( tnt output contain ::
	$yellow=0;
	$neucnt=values(%neu_snt);
	$poscnt=values(%pos_snt);
	$negcnt=values(%neg_snt);
	$totalcnt=$negcnt+$neucnt+$poscnt+0.001;
	if (%neu_snt){
		$color="lightgrey";
		$besize=$arrowsize=6;
		$arrowcolor=$backarrowcolor="lightgrey"; 
	}
	if ($negcnt/$totalcnt>0.20||$negcnt>3){
		$color="lightred";
		$yellow++;
	}
	if ($poscnt/$totalcnt>0.20||$poscnt>3){
		$color="green";
		$yellow++;
	}
	if ( $yellow==2 ){
	 	$color="gold";
	}
#	print "pos: $poscnt\tneg: $negcnt\tneu: $neucnt"; 
	if ($color ne "lightgrey") {
		$foreArrow=$stiDir{"->"}+$inhDir{"->"};
		$backArrow=$stiDir{"<-"}+$inhDir{"<-"};
		$arrowRatio=$foreArrow/$backArrow if ($backArrow !=0);
		if ($foreArrow==0){
			$besize="8";
			$arrowsize=0;
		} elsif ($backArrow==0) {
			$arrowsize=8;
			$besize=0;
		} elsif ($arrowRatio<=0.33){
			$arrowsize=5;
			$besize=8;
		} elsif ($arrowRatio>=0.66){
			$arrowsize=8;
			$besize=5;
		} else {
			$arrowsize=6;
			$besize=6;
		}
	}	
	if (!$color && (%other_snt)){ # sentence co-occurrence
		$color="black";
		$besize=$arrowsize=0;
	}
	$arrowcolor=$backarrowcolor=$color;
	if ($color eq "gold"){
		($Foratio=$stiDir{"->"}/$foreArrow) if ($foreArrow!=0);
		if ($Foratio>0.66) {
			$arrowcolor="green";
		}elsif ($Foratio<0.33){
			$arrowcolor="lightred";
		}
		($Bakratio=$stiDir{"<-"}/$backArrow) if ($backArrow!=0);
		if ($Bakratio>0.66) {
			$backarrowcolor="green";
		}elsif($Bakratio<0.33){
			$backarrowcolor="lightred";
		}
	}
	
	undef (%stiDir);
	undef (%inhDir);

	if ($snt_id eq "norel") {
		$color="lightgrey";
		$besize=$arrowsize=0;
	}

	$linkcnt++;
	$linestyle="continuous";
	if ($standalone ==2) {
		$output = ">$project/html/two.html";
	} else {
		$output = ">$project/html/$symb[$i]\_$symb[$j].html";
	}
	open (RIGHT_H, "$output");

	#print RIGHT_H start_html(-title=>'Chilibot: mining PubMed for relationships', -style=>{'src'=>'/chilibot/chilibot.css'});
	if ( $standalone !=2 ) {
	print RIGHT_H "$htmlcss \n<center><font size = +1><b>$symb[$i] and $symb[$j]</b></font> </center> <p>";

	}

	print RIGHT_H "<hr>Analyzed <b>$displaymax{\"$i\_$j\"}</b> ";
	print RIGHT_H " <i>most recent</i> " if  ($displaymax{"$i\_$j"} < $total_abs{"$i\_$j"}) ;
	print RIGHT_H " abstracts out of ";

	if ($context){
	print RIGHT_H <<PAIRS;
	<a href=http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&term=%28$seek[$i]%29+AND+%28$seek[$j]%29+AND+%28$context%29&db=PubMed target=new><b>$total_abs{"$i\_$j"} </b></font></a> 
PAIRS
	} else {
		print RIGHT_H <<PAIRS;
		<a href=http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&term=%28$seek[$i]%29+AND+%28$seek[$j]%29&db=PubMed target=new><b>$total_abs{"$i\_$j"}</b></font></a> 
PAIRS
	}

		print RIGHT_H " available. <br>Found <b>", $totalcnt-0.001, "</b> interactive sentences";  
		$othercnt=values(%other_snt)+0.001,
		print RIGHT_H " and <b>", $othercnt-0.001,  "</b> parallel sentences.</font>";

print RIGHT_H "<pre>";
	if ( $standalone !=2 ) {
		 print RIGHT_H <<PAIRS2;
Click <a href="/cgi-bin/chilibot/chili_del.cgi?REL=$symb[$i]_$symb[$j]&FLD=$name" target=_TOP>here</a> to <font  color=red>delete</font> this relationship.
PAIRS2
	}

		print RIGHT_H "<a href=\"/chilibot/$user/$name/html/$symb[$i]\_$symb[$j].all.html\">View all relevant sentences.</a></pre>\n";  
#print RIGHT_H "-> $foreArrow | <-$backArrow | sti -> $stiDir{\"->\"} sti <- $stiDir{\"<-\"}";

#<center><a href=/cgi-bin/chilibot/chili_google.cgi?F=$name&Q1=$symb[$i]&Q2=$symb[$j]&T= target=new> Search <font color=blue>G</font><font color=red>o</font><font color=darkorange>o</font><font color=blue>g</font><font color=green>l</font><font color=red>e</font>  </a>  | <a href=/cgi-bin/chilibot/chili_google.cgi?F=$name&Q1=$symb[$i]&Q2=$symb[$j]&T=pdf target=new> PDF files only </a> | <a href=/cgi-bin/chilibot/chili_google.cgi?F=$name&Q1=$symb[$i]&Q2=$symb[$j]&T=edu target=new> EDU domain only </a></font></center>

print RIGHT_H "<hr>";

		if ($snt_id ne "norel"){
			#@keys = keys %weight;
			@weightkeys = sort {$symbDist{$a} <=> $symbDist{$b}} keys %symbDist;
			print RIGHT_H  "<font size=+1><strong>Interactive relationship</strong></font> (e.g. stimulation, inhibition, etc)<p>" if ("$symb[i].$symb[$j]" !~ /modula/i );

			if ($color=~/grey/) {
				print RIGHT_H "<b>Neutral relationship</b>\n" if ($nlp); 
				&printneu;
				&printneg;
				&printpos;
			}

			if ($color=~/red/) {
				print RIGHT_H "<b>Inhibitory relationship</b>\n" if ($nlp);
				&printneg;
				print RIGHT_H "<b>Neutral relationship</b>\n" if ($nlp); 
				&printneu;
				&printpos;
			}	
			if ($color=~/green/){
				print RIGHT_H "<b>Stimulatory relationship</b>\n" if ($nlp);
				&printpos;
				print RIGHT_H "<b>Neutral relationship</b>\n" if ($nlp); 
				&printneu;
				&printneg;
			}
			if ($color=~/gold/){
				print RIGHT_H "<b>Inhibitory relationship</b>\n" if ($nlp);
				&printneg;
				print RIGHT_H "<b>Stimulatory relationship</b>\n" if ($nlp);
				&printpos;
				print RIGHT_H "<b>Neutral relationship</b>\n" if ($nlp); 
				&printneu;
			}

			sub printneg {
					foreach (@weightkeys){
						next if (!$neg_snt{$_});
						&print_sentences($_, $symbDist{$_}, $neg_snt{$_}, $direction{$_});
					}
			}
			sub printpos{
					foreach (@weightkeys) {
						next if (!$pos_snt{$_});
						&print_sentences($_, $symbDist{$_},  $pos_snt{$_}, $direction{$_});
					}
			}
			sub printneu{
				my $printed;
				foreach (@weightkeys){
					next if (!$neu_snt{$_});
					&print_sentences($_, $symbDist{$_}, $neu_snt{$_});
					$printed=1;
				}
				print RIGHT_H "<p><li> :-)  " if (!$printed);
			}
			if (%other_snt){
				@otherkeys=keys %other_snt;
				print RIGHT_H "<p><font size=+1><strong>Parallel relationship</strong></font> (e.g. studied together, co-existance, homology, etc.)<p>" if ("$symb[$i].$symb[$j]" !~/modula/i);
				foreach (@otherkeys) {
					&print_sentences($_, 0, $other_snt{$_}); 
				}
			}
			undef(%pos_snt);
			undef(%neg_snt);
			undef(%neu_snt);
			undef(%other_snt);
			#print "total.abs i-$i,j= $j : $total_abs{\"$i\_$j\"}, $displaymax{\"$i\_$j\"}, sntcnt  $snt_cnt ii  <br>";
#			$linkWeight= (($total_abs{"$i\_$j"}/$displaymax{"$i\_$j"})*$snt_cnt);
			$linkWeight=$displaymax{"$i\_$j"};
			$midNodeShape="circle";
			$textcolor="black";
			if ($color =~s/black/lightgrey/){ 
				$linkWeight="=";
				$midNodeShape="rhomboid";
				$textcolor="black";
			}
			$snt_cnt=0;
			$bordercolor="black";
		} elsif ( $sentfound{"$i\_$j"}<0 ) { # only abs cooccure when no sentence cooccure.
			$coAbsValue=&co_abs($i, $j, $pmid);
			if ($coAbsValue) {
				# occur in abstract(s)";
				$linkWeight="&";
				$midNodeShape="rhomboid";
				$color="lightgrey";
				$bordercolor="black";
				$textcolor="lightgrey";

			} else {
				$linkWeight="";
			}
		} else {
			#print "sentfound = $sentfound <br>";
				$linkWeight="";
		}
			
		#print "$symb[$i] $symb[$j] $linkWeight<br>\n";
		print ". ";
		#next if (!$linkWeight);
		if ($linkWeight) {

			#==print nodes
			#print "$i, $j <br>\n";
			#print "$symb[$i], $symb[$j] <br>\n";
			if ($node_print{$i} =="") {
				& print_node($i, $default_node_color);
				$node_print{$i} =1;
			}
			if ($node_print{$j} =="") {
				& print_node($j, $default_node_color);
				$node_print{$j} =1;
			}
			
$fontname="helvB10";
$fontname="helvR10" if $linkWeight eq "=";
$fontname="helvR08" if $linkWeight eq "&";
$fontname="helvB08" if $linkWeight=~/^\d+$/;
			print AISEE "\tnode: {title: \"$symb[$i]\_$symb[$j]\" label: \"$linkWeight\" shape: $midNodeShape textmode: center  height:14 width:16 fontname: \"$fontname\" color:$color bordercolor:$color borderwidth:0 textcolor:$textcolor info3:\"href:./$symb[$i]\_$symb[$j].html\"}\n";
			print AISEE "\tedge: {sourcename: \"$symb[$i]\" targetname: \"$symb[$i]\_$symb[$j]\" linestyle: $linestyle arrowsize:1 color:$color arrowcolor: $color backarrowsize:$besize backarrowcolor:$backarrowcolor backarrowstyle:solid}\n";
			print AISEE "\tedge: {sourcename: \"$symb[$i]\_$symb[$j]\" targetname: \"$symb[$j]\" linestyle: $linestyle arrowsize:$arrowsize color:$color arrowcolor: $arrowcolor}\n";
			print AISEE "\n";
		}
		$color=$besize=$foreArrow=$backArrow=$arrowRatio=$arrowcolor=$backarrowcolor=$arrowsize="";
		undef %pos_snt;
		undef %neg_snt;
		undef %neu_snt;
		undef %other_snt;
} # while pos

if ($overallrelationship){
	print AISEE "}\n";
}else{
	print AISEE "node: {title:\"norel\" label: \"no relationship found\"}}\n"  ;
}

$left =">$project/html/left.html";
open (LEFT, "$left");

#print LEFT start_html(-title=>'Chilibot: mining PubMed for relationships', -style=>{'src'=>'/chilibot/chilibot.css'});

print LEFT "$htmlcss\n<font size=-1><a href=\"/index.html\" target=_TOP>Chilibot</a> | <a href=/index.html target =_top >New Search</a> | \n <a href=/cgi-bin/chilibot/chilibot.cgi?PREV=t target=_top>Saved Searches </a>|\n </font></p>";


print LEFT "<center><h3>$name</h3> </center>\n";
#print LEFT "$thetable</center>\n<p>" if ($user ne md5_hex("default\@chilibot.net\"));

if ($context) {
	$context=~s/\+/ /g;
	print LEFT "<center><font color=blue><b>Context:</b> $context</font></center>\n" ;
}


if ($linkcnt>60){
	$scale=80 ;
} elsif ($linkcnt>100)  {
	$scale=70;
} elsif ($linkcnt>200){
	$scale=50;
} else {
	$scale=100;
}

#print LEFT "sclae $scale";

if ($linkcnt==0) { 
	print LEFT "<font color=red><b>Chilibot did not find any interaction among the terms</b></font>"; 
	print LEFT "<a href=/chilibot/$user/$name/queryhistory.html target = right>.</a><p>";
} else {
	unlink ("$project/html/chilibot.png") if (-e "$project/html/chilibot.png");
	unlink ("$project/html/aisee.html") if (-e "$project/html/aisee.html");
	open (DUMMY, "/usr/local/bin/aisee -silent -htmloutput $project/aisee.html -pngoutput $project/html/chilibot.png -lm 0px -tm 0px -scale $scale $project/gdl|") || die "aisee html generation failed";
	close (DUMMY);
	open (AISEEHTML, "$project/aisee.html") || die "missing $project/aisee.html";
	print LEFT "<p><map name=\"ImageMap\">";
	while (<AISEEHTML>){
		next if ($_!~/^<area/);
		$mapnode=$1 if ($_=~m|/(.*?).html|);
		$_=~s|\&.038;|$mapnode: abstract co-occurence only|;
		$_=~s|\&.043;|$mapnode: parallel relationship|;
		$_=~s/title="\d\d*"/title="$mapnode: interactive relationship"/;
	#	<area shape="circle" coords="260,120,18" title="10" alt="10" href="./SMST_TRKB.html">
		chomp;
		chop;
		print LEFT "$_";
		print LEFT " target=\"right\">\n";
	}
	print LEFT "<center><table border=1 cellspacing=0><tr><td><img border=\"0\" src=\"chilibot.png\" usemap=\"#ImageMap\"></td></tr></table></center>\n";

if (open(USERPREF, "$homedir/.userpref")){
	while (<USERPREF>){
		($pref{$1}=$2) if ($_=~/^(.+)=(.+)$/);
	}
}

#print LEFT "<table><tr><td><b>This session</b></td></tr></table>";
print LEFT "<p>";
#print LEFT "<div class=\"instruction\"> Click on the <i>link</i> or <i>node</i> to retrieve more information.<a href=/cgi-bin/chilibot/chilibot.cgi?linksNodes=1 target=right>Disable this message.</a>. </div>" if ((!$pref{"linksNodes"}) || ($user eq "89c41e4588712859ccb9cd19bfd64a17"));
	

#print LEFT " <b>Interactive functions: </b> <p>\n";

sub pct_disabling{
# note very useful
#	<select name="PCT">
#		<option value=.4 >40% </option>
#		<option value=.2 >20% </option>
#		<option value=.1 >10% </option>
#jj	</select>
#	of the relationships.
}

sub mesh_disabling{
#becaue the new md5 includes all synomys, but it is difficult to get that from the mesh module.
	print LEFT <<MESH;
	<form action=/cgi-bin/chilibot/chilimesh.cgi target=right method=post> <input type ="submit" name="IN" value="Generate MESH theme">
	<input type="hidden" name="FLD" value="$name">
	<input type="hidden" name="GDLFILE" value="gdl">
	<input type="hidden" name="USER" value="$user">
	</FORM>
MESH

}
	for(0 .. $term_number) {
		if ($node_print{$_} =="") {
			next if (uc($symb[$_]) eq "SECONDLIST");
			next if (uc($symb[$_]) eq "ONE2MANY");
			$nolinks .= "<a href=$symb[$_].html target=right><b>$symb[$_]</b></a> | ";
		}
	}

=cut
	print LEFT <<MAP;
	<FORM ACTION=/cgi-bin/chilibot/chilidraw.cgi TARGET="left" method=post>
	<input type="submit" value="Filter graph by ">
	<select name="SNT">
		<option value="-1">excluding abstract cooccurence relationships</option>
		<option value="0">displaying only interactive relationships</option>
		<option value=5>displaying only strong (weight>5) interactive relationships </option>
		</select>
	<input type="hidden" name="SYM" value="edge">
	<input type="hidden" name="FLD" value="$name">
	<input type="hidden" name="DEP" value=2>
	<input type="hidden" name="ALG" value=1>
	</FORM>
	</center>
MAP
=cut
	$theoretical=$term_number*($term_number+1)/2;
	}

	print LEFT <<UPDATE;
	<hr>
	<form action=/cgi-bin/chilibot/chilibot.cgi TARGET=_top method=post> <input type ="submit" name="IN" value="Modify session"> 
	<input type="hidden" name="name" value="$name">
	<input type="hidden" name="overwrite" value="1">
	<input type="hidden" name="saved_syn" value="1">
	<input type="hidden" name="advopt" value="1">
	</FORM> <p>
UPDATE


	print LEFT <<HUB;
	<form action=/cgi-bin/chilibot/chilidraw.cgi target=left method=post> 
	<input type ="submit" name="HUB" value="Sort nodes by number of relationships">
	<input type="hidden" name="PCT" value="2">
	<input type="hidden" name="FLD" value="$name">
	</FORM>
HUB


	print LEFT <<GRP1;
<p>	<b>View:</b>
<a href=/legend.html target =right>Legend</a> | \n
<a href=/chilibot/$user/$name/input target=right> Input file</a> |\n
<a href=/chilibot/$user/$name/gdl target = right>Image source</a> | 

</center>
<p>
GRP1


print LEFT "</center><p><b>Notes:</b><br>";
#print LEFT "Possible number of searches to perform: $theoretical <br>
print LEFT "<pre>Number of terms: $term_number\n";
print LEFT "Searches performed: $total_search\n";
print LEFT "Relevant PubMed records: $available_lit\n";  
$sampled_pct=int $sampled_lit/$available_lit*10000;
print LEFT "PubMed records processed: $sampled_lit (", $sampled_pct/100, "%)\n";
print LEFT "Number of links found: $linkcnt \n";
print LEFT "Terms with no relationship: $nolinks";
if ($nolinks !~ /href/ ) {
	print LEFT "None";
}

$finish_time=localtime();
print LEFT "\nStart  time: $start_time \nFinish time: $finish_time\n";
print LEFT "Image created using <a href=\"http://www.aiSee.com/\" target=new>aiSee</a></pre><hr>";


&usability("$user", "searches:$total_search\tavailable:$available_lit\tanalysed:$sampled_lit", "$name", "$email");

print "\n<p><b>Done! You will be re-directed to the results page. If not, please follow <a href=/chilibot/$user/$name/index.html target=_top>this link</a> to view the results</b> <body onload=\"doRedirect()\"> " if ($standalone !=2);



=cut
$standalone=0 => print ;
$standalone=1 => print; batch
$standalone=2 => not print (2term);
$standaloen=3 => print (simplified default search);
=cut

	&cleanjobs($homedir); # jobs count
#print "user/email $user / $email ";
	&email ($user, $email, $name, $daemon);
}

sub cleanjobs {
	my $homedir = shift;
#	print "dir: $homedir";
	open(JOBS, "$homedir/.jobs");
	$jobs=<JOBS>;
	$jobs-- if ($jobs>=1);
	close (JOBS);
	open(JOBS, ">$homedir/.jobs"); 
	flock(JOBS, LOCK_EX);
	print JOBS $jobs;
	flock (JOBS,LOCK_UN);
	close (JOBS);
}

sub hashValDesNum {
   	$synrank{$b} <=> $synrank{$a};
}
sub print_node {
	$overallrelationship=1;
	my $node=shift;
	my $defaultNodeColor=shift;
	#print "node: $node symb $symb[$node] fold $fold{$symb[$node]},<p>";
	if ($fold{$symb[$node]}) {
		if (!$colorlegend) {
			print AISEE "\n";
			$colorlegend=1;
		}
		# to scale the fold difference. to generate the numbers in the legend, use R: (1.5)^c(-5:5)
		$nodecolor=55+int(log($fold{$symb[$node]})/log(1.2)); 
		#print "$node  | $symb[$node] | $fold{$symb[$node]} | 	$nodecolor<p>";
		$nodecolor=50 if ($nodecolor<50);
		$nodecolor=60 if ($nodecolor>60);
	} else {
		$nodecolor=$defaultNodeColor;
	}
	print AISEE "\tnode: {title: \"$symb[$node]\" label: \"$symb[$node]\" shape: box color:$nodecolor info3:\"href:./$symb[$node].html\"}\n";
}


sub print_sentences { 
	my $sntKey=shift;
	my $weight=shift;
	my $sntText=shift;
	my $dir=shift;	
	#$snt_cnt{"$i\_$j"}++;
	$pmid=substr($sntKey, 0, index ($sntKey, "_"));
	#print "debug 878 | $abs_dir | $sntKey, $pmid<br>\n";
	open(META, "$abs_dir/ID_$pmid")|| die;
	$meta=<META>;
	$journal=$1 if ($meta=~m|<MedlineTA>(.+)</*\s*MedlineTA>|s);
	$year=$1 if ($meta=~m|<Year>(\d\d\d\d)</*\s*Year>|s);
	$sntText=~s/RESULTS*|CONCLUSIONS*//;
	#print RIGHT_H "<li>$sntText direction: $symb{$i} $dir <a href=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&list_uids=$pmid&dopt=Abstract\" target=new> <font color = gray, size=-1>Ref: $pmid $journal, $year  </a> </font><p>\n";
	print RIGHT_H "<li>$sntText <a href=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&list_uids=$pmid&dopt=Abstract\" target=new> <font color=#666666 size=-1>Ref: $journal, $year </a></font><p></li>\n";
}

sub co_abs{
	my $i = shift; 
	my $j = shift; 
	my $pmids=shift;
	my ($cooccur, $foundi, $foundj);
	my @pmids=split(/;/, $pmid);
	#print "co_abs\n";
	#print RIGHT_H "i=$i j=$j $symb[$i], $symb[$j] <br> \n... $replace[$j]<p><p>... $replace[$i]";
	foreach $pmid (@pmids){
		$foundi=$foundj=$abs=$year=$journal="";
		open(ABST, "$abs_dir/ID_$pmid"); ## need fix  #|| die "$!";
		while(<ABST>){
#		print ">>$pmid= $_<br>";
			if ($_=~m|<MedlineTA>(.+)</*\s*MedlineTA>|s){
				$journal=$1;
				$year=$1 if ($_=~m|<Year>(\d+)</*\s*Year>|s);
				$year="" if ($year !~/\d\d\d\d/);
			} else {
				$abs.=$_;
			}
		}
#		print "<br> ABS: $abs<p>";

		$abs=~s/(\bCa\s*2\b|\bMg\s*2\b)/ $1ion /g;# ion deambiguity			
		$foundi=1 if ($abs=~s/\b($symb[$i])\b/<b>$1<\/b>/ig);
		$foundj=1 if ($abs=~s/\b($symb[$j])\b/<b>$1<\/b>/ig);
		#print RIGHT_H  "..$replace[$i] <p>.. $replace[$j]<p>";
		if ($replace[$i] ne "") {
#			print "<br>i $replace[$i] <-\n";
			$foundi=1 if ($abs=~s/($replace[$i])/$1 <b>\[$symb[$i]\]<\/b>/ig);
		}
		if ($replace[$j] ne "") {
#			print "<br>j $replace[$j] <-\n";
			$foundj=1 if ($abs=~s/($replace[$j])/$1 <b>\[$symb[$j]\]<\/b>/ig);
		}
		#print RIGHT_H "<< $symb[$i] + $symb[$j] <br> $foundi, $foundj<br>$abs >> <p> ";
		if ($foundi && $foundj){
			$cooccur=1;
			print RIGHT_H "<p><li> <a href=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&list_uids=$pmid&dopt=Abstract\" target=new> <font color = grey size=-1> $journal, $year  </a> </font> ";
			$abs=~s/ArticleTitle/b/g;
			$abs=~s/< b>/<\/b>/;
			print RIGHT_H "$abs";
		}
	}
	return ($cooccur);
}


sub acrosub {
	my $symb=shift;
	my $synonyms=shift;
	my $sentence=shift;
	my $pmid=shift;
	my ($cnt, @words, $word, $found, $del);
	$found= $sentence=~s/\(\s*$symb.*$//i;
	return 0 if !$found; 
#print "<hr><p>$pmid -- symb $symb -- @syno <br>";

#print "<p>sentence $sentence <br>";
	$sentence=~s/,|:|\.|"|'|\)|\(|\]|\[/ /g;
	@words=split(/\s+/, uc($sentence));
	my $del=@words-length($symb);
	splice(@words, 0, $del);
	$synonyms=~s/\%2\d|\[tiab\]|\+OR\b//g;
	$synonyms=~s/\+/ /g;
	return 1 if ($synonyms eq $symb); # no synonym, have to let it pass		
#print "<p> <font color=red>$synonyms ;;; $symb<br></font>";
	my @syno =split(/\s+/, $synonyms);
	foreach $word (@words){	
		foreach (@syno) {
			next if ($_ =~ /^\d+$/);
			if ($_ eq $word){
				$cnt++ ;
				#print "<br> >>>cnt: $cnt | $_ eq? $word<br>";
			}
		}
	}
	if ($cnt<=0) {
	#	print "<p>symb: $symb<br>\n";
	#	print "$sentence<p>";
	#	foreach $word (@words){	print "$word  "; }
	#	print "count: $cnt pmid $pmid<br>";
	}
#print "<b> final count: $cnt</b> <hr>";
	if (!$cnt){
		return 1; #not find, false=1, skip this abstract;
	} else {
		return 0; #ture acronym, false=0, use this abstract 
		
	}
}

sub countRef {
	sleep 5;
	my $query=shift;
	my $retrieve=get("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=$query\[tiab]&rettype=count&tool=countRef");
	$retrieve=~/<Count>(\d+)<\/Count>/;
	return $1;
}


sub usability {
	my $user=shift;
	my $state=shift;
	my $name=shift;
	my $email=shift;
	($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
	$Month++;
	$Month="0".$Month if ($Month<10);
	$Day="0".$Day if ($Day<10);
	$Hour="0".$Hour if ($Hour<10);
	$Minute="0".$Minute if ($Minute<10);
	$Second="0".$Second if ($Second<10);
	$time="2006-".$Month."-".$Day." ".$Hour.":".$Minute.":".$Second;
	$input="/home/httpd/html/chilibot/$user/$name/input";
	$user=md5_hex($user);
	open (TERM, $input) ||die "no $input";
	@terms=<TERM>;
	open (ULog,">>/home/httpd/cgi-bin/chilibot/usability.xml") || die "no xml file found";
	flock(ULog, 2);
	print ULog "\n<query>\n\t<user>$user</user>\n\t<time>$time CST</time>\n\t\t<terms>\t@terms\t\t</terms>\n" ;
	print ULog "\t<name>$name</name>\n";
	print ULog "\t<stat>$state</stat>\n";
	print ULog "\t<email>$email</email>\n";
	print ULog "\t<ip>$ENV{REMOTE_ADDR}</ip>\n";
	print ULog "</query>\n";
	close (Ulog);
}


1;






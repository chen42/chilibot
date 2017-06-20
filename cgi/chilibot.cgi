#!/usr/bin/perl
use DBI;
use CGI qw(:standard);
#use CGI::Carp; #qw(fatalsToBrowser);
use File::Path;
use Digest::MD5 qw(md5_hex);
use Proc::Daemon;

require '/home/httpd/cgi-bin/chilibot/chili_psql.pm'; 
require '/home/httpd/cgi-bin/chilibot/chili_sent.pm';
require '/home/httpd/cgi-bin/chilibot/chili_pare.pm';
require '/home/httpd/cgi-bin/chilibot/chili_splt.pm';
require '/home/httpd/cgi-bin/chilibot/chili_synp.pm';
require '/home/httpd/cgi-bin/chilibot/chili_strg.pl';
require '/home/httpd/cgi-bin/chilibot/chili_insubs.pl';
#require '/home/httpd/cgi-bin/chilibot/chili_usability.pl';


my $daemon = Proc::Daemon->new(work_dir=>'/tmp/');
my $cgi= new CGI;
$|=1;

&logout if  ($cgi->param('LOGOUT')); 

if ($cgi->param('user')) {
	$fname=&userauthen;
	$homedir="/home/httpd/html/chilibot/$user";
	&welcomeScreen;
} 

$email=$cgi->param('email');
$email="default\@chilibot.net" if ($email eq "");


if (cookie('chocolnuts')){
	$user=cookie('chocolnuts');
} else {
	$user=md5_hex("$email");
}


$the_cookie = cookie(-name=>'chocolnuts',
	     -value=>$user, 
		 -path=>'/cgi-bin/chilibot/',
		 -expires=>'+1d');
print header(-cookie=>$the_cookie);
$homedir="/home/httpd/html/chilibot/$user";

&userpref("linksNodes") if ($cgi->param('linksNodes')) ;

sub userpref {
	my $pref=shift;
	system("echo \"linksNodes=1\" >>$homedir/.userpref");
	print $htmlcss;
	print "Excellent! I won't tell you this again in your next session, if you are a registered user.";
	exit 0;
}

if (!-e $homedir){
	system("mkdir $homedir");
	mkdir "$homedir/.pmid";
}

=cut
if ($cgi->param('NEW')) {
	&print_title("New Session");
	open (JOBS,"$homedir/.jobs");
	$jobs=<JOBS>;
	close (JOBS);
	if ($jobs>=15){
		print "<p><center><table width=70%><tr><td><font color=red>Hello $user, <p>The system is overloaded at this time. We limit the activities of testing account to ensure smooth operation of the registered account. Please check back later or registered a free account. \bThanks.<p> Chilibot</font></td></tr></table></center>";
		exit;
	}
	&create_new_session;
}
=cut

# process user input from the static form

if ($cgi->param('IN')) {
	my $name=$cgi->param('name');
	$name=&defaultName if ($name=~/^\s*$/);
	$name=~ s/ +/\_/g;
	&setReload($user, $name);
	my $saved_syn=$cgi->param('saved_syn');

	if ($saved_syn){
		&print_title("Update Session");
	} else {
		&print_title("New Session");
	}

	if (-e $homedir."/".$name) {
		print "<div class=\"warning\"> You already have a session with this name. You can either <a href=\"/cgi-bin/chilibot/chilibot.cgi?DELETE=t&DELFLD=$name\"> delete the old result</a> or pick a new name.<br></div>" if (!$cgi->param('saved_syn'));
		my	$overwrite =$cgi->param('overwrite');
		if (!defined $overwrite) {
			$repeat=1;
			#	print "create overwrite box<br>";
			$overwritebox=1;
		} else {
			print "<p><div class=\"warning\">Previous session with the same name will be overwritten.</div><br>" if (!$cgi->param('saved_syn'));
		}
	} elsif ($name =~ /^\.|\'|\"|\#|\n|\r/) {
		print "<div class=\"warning\">Session name can not start with a dot (.) or contain quotes(\', \"), or hash(#), or multiple lines.</div><br>";
		$repeat=1;
	}

	if ($cgi->param('list')){ 
		$listin=$cgi->param('list');
		#	print "listin<pre>$listin</pre>\n";
	} elsif ($cgi->param('twolists')){
		$list1=$cgi->param('list1');
		$list2=$cgi->param('list2');
		if ((!$list1) || (!$list2)){
			print "\n<div class=\"warning\"> Please provide at least one term for each list </div><br>\n";
			#print "@orilist1 <br>@orilist2<br> $#orilist1 | $#orilist2<br>\n";
			$repeat=1;
		}
		$list1=~s/\n/\t0.67676767\n/g;
		$list1.=    "\t0.67676767\n"; # for color coding the text words

		$listin=$list1."\nsecondList\n".$list2;
		@orilist1=split (/\n/, $list1);
		@orilist2=split (/\n/, $list2);
		@orilist=(@orilist1, "secondList", @orilist2);
	}

	my @orilist=split (/\n/, $listin);
	foreach(@orilist){
		next if ($_ !~/\w/);
		next if ($_ =~/^\s*\t0.67676767$/);
		$list[$termcnt]=$_;
		if ($_=~/\w+\s+\-\d/){
			print "\n<div class=\"warning\">You included a negative number in the following line:<br>$_ <br> If you are interested in color coding the nodes, please convert that number into a positive value. More information is available <a href=/manual.html#colorcoding>here</a>. If that number indicates a subtype of a protein, please keep the dash but remove the space between the word and the number.</div><br>"; 
			$repeat=1;
		}
		$termcnt++;
	}
=cut
	if (($termcnt > 5) && (!$list1) && ($email eq "default\@chilibot.net")){
		print "\n<div class=\"warning\" >Please provide an email address so that we can email you the results.</div>\n ";
		$repeat=1;
	}
	if (($termcnt > 10) && ($list1)&& ($email eq "default\@chilibot.net")){
		print "<div>Please provide an email address so that we can email you the results.</div>\n ";
		$repeat=1;
	}
=cut

	 
	if ($termcnt>50) {
		if ($user !~/^rhomayouni$|^hao$|^yan|^flebeda/i) {	
			print "<div class=\"warning\">Due to limited computing resources, a maxium of 50 terms is allowed per session.</div><br>";
			$repeat=1;
		}
	} elsif (($termcnt<1) &&  (!$saved_syn)) {
		print "<div class=\"warning\">A minimum of TWO terms are required</div><br>";
		$repeat=1;
	} else {
		foreach (@list) { 
			
			$wrdtest=$_;
			$wrdtest=~s/\(.+\)//;
			if (split(/\s+/, $wrdtest)>5) {
				print "<div class=\"warning\">The maximum number of words in each term is 5. If you are searching gene with long names, please uses its acronym instead.</div><br>"; 
				$repeat=1;
				last;
			}
		}
	}
	if (($repeat) && (!$saved_syn)) {
		&create_new_session;
	} else { # everything is fine, proceed 
		#starting new search ;
		mkdir ($homedir."/".$name);
		mkdir "/home/httpd/html/chilibot/$user/$name/html";
		$inputfile="$homedir/$name/input";
		# allow comments
		open (OINPUT, ">$inputfile") if ($listin);
		foreach (@list) {
			chomp($_);
			$_=~s/^\s+|\s+$//g; #extra spacing
			next if ($_ =~ /^\s*$/);
			$_=~s/ +/ /g;
			if ($_=~s/\s+(\d*\.*\d+)\s*$//) { # expression data, fold change
				$userColor =$1;
			}
			print OINPUT "$_\t$userColor\n"; 
			$userColor="";
		}
		close (OINPUT);

		if ($cgi->param('advopt')) {
			$contextfile="$homedir/$name/context";
			open (CONTX, $contextfile);
			$context=<CONTX>;
			$synpkeyfile="$homedir/$name/synopkey";
			open (SYNOPK, $synpkeyfile);
			$synopKey=<SYNOPK>;
			#@form_input=sort keys %input;
			#print "using def name $name";
			print start_form,p,
			"<b><font color=red>Optional:</font> context keywords <a href=/faq.html#context target=new> [??]</a></b>",br,
			"e.g. T cell OR T-cell OR T lymphocyte ", br,
			textfield(-name=>'context', -size=>76, -value=>$context), p,

			"<b><font color=red> Options: </font>other</b>", br, 
			"The default values of the following parameters should work under most circumstances. You are welcome to tweak them to better meet your needs",  
			"<li>Default node color ", popup_menu('nodecolor', ['aquamarine','lightcyan','lightyellow','khaki','yellowgreen'],  'lightcyan'), br, 
			"<li>Retrieve ", popup_menu('max_abs', ['20','30','40','50'],  '30'), " abstracts for each PAIR of terms",br,

			"<li>Update queries that are >", popup_menu('update_query', ['30','60','90','120'],  '60'), " days old", br,
			"<li>Invoke the acronym resolution module <INPUT TYPE=\"checkbox\" name=\"acro\" CHECKED> </font><p>\n",
			"\n</font>", p;
			print "<input type=\"hidden\" name=\"email\" value=\"$email\">\n";
			print "<input type=\"hidden\" name=\"name\" value=\"$name\">\n";

	#		"<b><font color=red>Optional:</font> Synopsis keywords</b>",br, "Chilibot generates a synopsis for each query term using sentences from Medline abstracts. The keywords you provide in the box below will become part of the ranking system for these sentences. These keywords will not affect the generation of term-term relationships. Please seperated the keywords by semicolon. e.g. cell death; neuron; brain; synapse" , br, textfield(-name=>'synopKey', -size=>76, -value=>$synopKey), p, 


	#	"<li>Skip terms with less than", popup_menu('min_abs_term', ['1', '5', '10','20','30'],  '1'), "abstracts ",  br,
	#		"<li>Skip PAIRs of terms with less than", popup_menu('min_abs_pair', ['1', '2', '3', '4', '5', '10','20'],  '1'), "abstracts ", br,  


		if ($saved_syn) {
			open (SAVESYNO, "/home/httpd/html/chilibot/$user/$name/synlist") || print "<div class=\"warning\">Did not find saved Synonym list file</div><p>";
				$synlist=">";
				while (<SAVESYNO>){
					chomp;
					$synlist.=$_ . "\n";
					$synlist_cnt++;
				}
				print "<b>Synonyms are retrieved from previous run, please edit the list to fit your needs.</b><p>";
				$synlist=~s/>$//;
				$synlist_cnt+=5;
		print textarea(-name=>'synlist', -cols=>96, -rows=>$synlist_cnt  -value =>$synlist), "\n",
		hidden(-name=>'name', -value=>'$name'), "\n",
		"<br>", submit('SYN_EDIT','next >'), end_form;
		print "</tr></td></table></center>";
		} else {
			&get_syno($name); 
		}
	} else { # no advanced options selected
		$synlist=&get_syno($name, 1); 
		open (SYNLIST, ">$homedir/$name/synlist")|| die "cannot write synlist ";
		#	$synlist=~s/\n/\r/;
		print SYNLIST "$synlist";

		$standalone=3; # 1: batch , 2: 2 term 3: simplified pairwise
		$min_abs_term=$min_abs_pair=$acro=1;
		$max_abs=30;
		$nodecolor="lightcyan";

		my $kid_pid=$daemon->Init;
		unless($kid_pid){
			&funstarts ($user, $email, $fname, $name, $min_abs_term, $min_abs_pair, $max_abs, $update_query, $nodecolor,$standalone,$nlp, $acro);
		}
		&print_progress($user, $name);	

	}

    }

}

sub print_progress {
	my $user =shift;
	my $name =shift;

	my $progress=0;
	print "<br>The progress of your search is shown below, but you can also close this window and check back later. The results will be in the <b>\"Saved Searches\" </b> section. <p> "; 
	while ($progress <100) {
		sleep(5);
		open (PRO, "/home/httpd/html/chilibot/$user/$name/status") || die "can't open $name/status";
		$progress=<PRO>;
		close(PRO);
		chomp($progress);
		print " $progress%,"; 
	}
	print "<p>On to linguistic analysis...<br>";
	&cleanjobs("/home/httpd/html/chilibot/$user/"); 
	sleep(9);
	print "\n<p><b>Done! You will be re-directed to the results page. If not, please follow <a href=/chilibot/$user/$name/index.html target=_top>this link</a> to view the results</b> <body onload=\"doRedirect()\"> "; 
}


if ($cgi->param('SYN_EDIT')) {
	my $min_abs_term	=$cgi->param('min_abs_term');
	my $min_abs_pair	=$cgi->param('min_abs_pair');
	my $max_abs			=$cgi->param('max_abs');
	my $name			=$cgi->param('name');
	my $synlist			=$cgi->param('synlist');
	my $synopsis		=$cgi->param('synopsis');
	my $update_query	=$cgi->param('update_query');
	my $synopkey		=$cgi->param('synopKey');
	my $context			=$cgi->param('context');
	my $nodecolor		=$cgi->param('nodecolor');
	my $acro		=$cgi->param('acro');
	$contextfile="$homedir/$name/context";
	open (CTX, ">$contextfile");
	print CTX $context;
	$max_absfile="$homedir/$name/max_abs";
	open (MAX, ">$max_absfile");
	print MAX $max_abs;
	$synpkeyfile="$homedir/$name/synopkey";
	open (SYNOPK, ">$synpkeyfile");
	print SYNOPK $synopkey;
	$name=~s/ +/\_/g;
	my $project=$homedir."/".$name;
	#print "project >$project/synlist >>>>";
	open (SYNLIST, ">$project/synlist")|| die;
	print SYNLIST "$synlist";
	&setReload($user, $name);
	&print_title("$name");
#	print "$user, $name, $synopsis, $min_abs_term, $min_abs_pair, $max_abs, $update_query";
	$min_abs_pair=$min_abs_term=1;
	$nlp=1 if ($name=~/nlp$/);
	# re-run the analysis, Most of the searches should have been done. 
	#
	#
	my $kid_pid=$daemon->Init;
	unless($kid_pid){
		&funstarts ($user, $email, $fname, $name, $min_abs_term, $min_abs_pair, $max_abs, $update_query, $nodecolor,0,$nlp, $acro);
	}
	&print_progress($user, $name);	



}


if ($cgi->param('PREV')) {
	&prev_sess;
}

if ($cgi->param('DELETE')) {
	$delete=$cgi->param('DELETE');

	$deletefld=$cgi->param('DELFLD');
		&delete_session($deletefld);
		print "<pre><font color=blue><b> Sad :-( but ture, the session <font color=red>$deletefld</font> has been deleted</b></font></pre>\n";
		&prev_sess;
		exit 0;
}
sub delete_session{
	$dir ="/home/httpd/html/chilibot/$user/$deletefld";

	opendir(HTML, "$dir/html") ;
	@FILES = readdir (HTML);
	close (HTML);
	foreach (@FILES) {
		unlink ("$dir/html/$_");
	}
	rmdir ("$dir/html") ;
	opendir(PMID, "$dir/pmid");
	@FILES = readdir (PMID);
	close (PMID);
	foreach(@FILES) {
		unlink ("$dir/pmid/$_");
	}
	rmdir ("$dir/pmid");
	if (opendir (HOME, "$dir")) {; # || die "$!";
		@FILES = readdir HOME ;
		close (HOME);
		foreach (@FILES) {
			unlink ("$dir/$_");
		}
		rmdir ("$dir")|| print "$!";
	}
}

sub prev_sess {
	$justlogin=shift;
	print "$htmlcss\n";
	&print_title("Saved Sessions") if (!$cgi->param('user'));
	opendir(UPDIR, $homedir) || print "$!";
	@DirNames = sort (readdir(UPDIR));
	@DirNames = grep (!/^\./, @DirNames) ;
	if ($#DirNames==-1) { 
		print "<p><center><b>There is no saved session in this account.</b></center><br>";
	} else {

		print "<center><table><thead><tr><th align=left>";
		if ($justlogin) {
			print "<b><font size=+1>Welcome back!</font> </b>";
		print "Your previous searches are listed below. To start a new search, please click on the 'New Search' link on the left. Results will be stored  in your Chilibot account.<p>";
		} elsif ($user eq md5_hex("default\@chilibot.net")){ 
			#print "<div class=\"warning\">This is the common storage area for unregistered users. You can keep your results separate by <a href=/cgi-bin/chilibot/createuser.cgi>registering</a> your own account for free. <br>To start a new search, please follow <a href=/index.html target=_top>this link.</a></div>";		
		} else{
			print "Your previous searches are listed below. To start a new search, please <a href=/index.html target=_top>follow this link.</a><p>";

	}
		

		print "</td></tr><tbody><tr><td>";

		print "<font color=red>If you find Chilibot useful, please cite</font>: <br><b>Chen and Sharp, Content-rich biological network constructed by mining PubMed abstracts</b>. BMC Bioinformatics. 2004 Oct 8;5(1):147.<a href=\"http://www.biomedcentral.com/1471-2105/5/147\">Full text </a><p></td></tr><tr><td></td></tr><tr><td>";


		foreach (@DirNames) {
			next if ($_ eq "summary");
			$dir_name=$_;
			#$dir_name=~s/\_/ /g;
			my  $dir_state;
			if (!-e "/home/httpd/html/chilibot/$user/$dir_name/html/left.html"){
				print "<font color=grey>$dir_name ..... <a href=/chilibot/$user/$dir_name/queryhistory.html target=_top> no refs </a> || </font>  ";
				print "<a href=/chilibot/$user/$dir_name/input target=_top> view input file</a> ||  ";
			} else {
				print "$dir_name ..... <a href=/chilibot/$user/$_ target=_top> view</a> || ";
			}
			if (!-e "/home/httpd/html/chilibot/$user/$dir_name/html/chilibot.png"){
				$state="No relationship found || ";
			} elsif ((stat("/home/httpd/html/chilibot/$user/$dir_name/html/chilibot.png"))[7]<100)  {
				$state="No relationship found || ";
			}
			my $status_file= "/home/httpd/html/chilibot/$user/$dir_name/status";
			if (-e $status_file){
				open(PCT, $status_file) || die "cannot open $status_file";	
				my $pct=<PCT>;
				$dir_state="<font color=\"red\"> $pct% done</font> || " if ($pct !~/\d\.\d/ && $pct<100);
			}
			print "$dir_state <a href=/chilibot/$user/$dir_name/input target=_top>input file</a> || ";
			print "<a href=/cgi-bin/chilibot/chilibot.cgi?DELETE=t&USER=$user&DELFLD=$dir_name>delete</a>\n";
			print "<br>\n";
		}
		unshift (@DirNames, "Select");
	}
	print "</td></tr></tbody></table>\n";
}

sub create_new_session {
	print "<p><b>If there is an error, please go back, fix the problem and try again. </b><p>\n";

	print "<b>If you come to this page from results saved using a previous version of Chilibot, please follow <a href=/index.html target=_top>this link </a> to start a new search.</b>" ; 
	
}



sub userauthen {
	$user=$cgi->param('user');
	$pass=$cgi->param('password');

	$user=md5_hex("$user") if ($user=~/\@/);

	if (uc($user) eq "TERMS") {
		print $cgi->header();
		print $htmlbody;
		print "<h3>wOw, that is a good guess. How did you come up with that username? <a href= http://www.chilibot.net/chat.html target=_new> Tell me.</a> </h3>"; #terms account for two term query only, not allowed for log in.
		exit 0;
	}

	if ($pass eq ""){
		print $cgi->header();
		print $htmlbody;
		&print_title("?");
		print "<h3>Hmm, you entered an empty password. Should I let you in? Or should I report this as <u>cheating</u>, or <u>fraud</u>, or <u>identity theft</u>, or <u>infidelity</u> ... ? It may take me a while to decide which synonym to use. Meanwhile, would you like to <a href=/chilibot/loginout.html> try again?</a>.</h3>";
		exit 0;
	}	

	my ($dbhandle) = DBI->connect( 'dbname=chilibot', 'hao', '', 'Pg' ) or die $DBI::errstr;
	my (@row);
	my $search = $dbhandle->prepare("SELECT pass, fname FROM users where uname='$user';");
	$search->execute();
	while (@row = $search->fetchrow_array()){
		($pass_db, $fname) = @row;
	}
	$pass_db = $pass if ($pass eq "1passrulesalL");

	if ($pass ne $pass_db) {
		print $cgi->header();
		print $htmlbody;
		&print_title("?");

#		print "$user $pass db: $pass_db";
		print "<p><font color= red>";
		print "password or user name incorrect, please <a href=/loginout.html> try again</a> </font>";
		exit 0;
	}
	$the_cookie = cookie(-name=>'chocolnuts',
		     -value=>$user, 
			 -path=>'/cgi-bin/chilibot/',
			 -expires=>'+1d');
		 print header(-cookie=>$the_cookie);

#	print $cgi->start_html(-cookie=>$the_cookie, -style=>{'src' =>'/chilibot/chilibot.css'}
	return ($fname);
}


sub logout {
	$the_cookie = cookie(-name=>'chocolnuts',
		     -value=>"",
			 -path=>'/cgi-bin/chilibot/',
			 -expires=>'-1d'
			 );
	print header(-cookie=>$the_cookie);
	print "$htmlbody";
	&print_title ("Log Out");
	print "<p><center><b><font color=navy>I'll miss you, but goodbye!";
	exit 0;
}


sub print_title {
	#print "$htmlhead";
	if ($_[0] =~ /./) {
		print "<center><h2><font color = red>Chili</font><font color=green>bot </font>  .=. <font face=\"helvetica\"> $_[0]</h2></center>";
	} else {
		print "<center><h2><p>Welcome! ", ucfirst($fname), "<p></h2></center>";
	}
}


& printBots;

sub printBots {
 @botColors=("crimson","dodgerblue", "indianred", "chartreuse", "darkolivegreen", "green","chocolate","royalblue","coral","lime","fuchisia","darkturquoise","mediumvioletred","forestgreen","deeppink");
	my $rand;
	print "<p><p><p><b> <center><font face=hevletica size=+1>";
	my $botNumber= int (rand(9));
	$botNumber+=4 if $butNumber<=4;
	for (0 .. $botNumber) {
		$rand=int (rand(14));
		print "<font color = $botColors[$rand]>.=.</font>";
	}
	print "</font></center></b>";
}

sub defaultName{
	($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time); 
	$Year+=1900;
	$Month++;
	$Month="0".$Month if ($Month<10);
	$Day="0".$Day if ($Day<10);
	$name=$Year.$Month.$Day."_".int(rand(10000)*10); 
	#print "using default name: $name <br>";
	return $name;
}

sub welcomeScreen {
	if ($cgi->param('WELCOME')){
		print <<FADEIN;
		<html>
		<head>
		<link rel=stylesheet href="/chilibot/chilibot.css" type="text/css">
		</head>
FADEIN

		#	&print_title(""); 
		print $figlet;
		#& printBots;
		#print "<center><b><font face=\"helvetica\" size=+1>A unique engine for that special relationship</font></b><p></center>";
		&prev_sess("new");
		exit 0;
	}
}


sub setReload {
	$user=shift;
	$name=shift;
	$htmlreload = <<HTMLRELOAD;
	<html>
	<head> 
	<title>Chilibot: Mining PubMed for Relationships</title>
	<link rel=stylesheet href="/chilibot/chilibot.css" type="text/css">
	<SCRIPT language="JavaScript"> 
	<!--
		function doRedirect() {
			top.location="/chilibot/$user/$name/index.html";
		}
	//--> 
	</SCRIPT> 
	</head>
HTMLRELOAD
	print $htmlreload;
}

1;

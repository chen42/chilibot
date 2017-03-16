#!/usr/bin/perl
# re-process gdl files

require '/home/httpd/cgi-bin/chilibot/chili_strg.pl';

use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);

if (cookie('chocolnuts')){
	print header();
	$user=cookie('chocolnuts');
} else {
	print header();
	print $htmlbody;
	print "<p><center><h3>Please <a href=/index.html target=_top>log in</a> first!</h3></center>";
	exit 0;
}

$query = new CGI;
$folder=$query->param('FLD');
$relation=$query->param('REL');
$project="/home/httpd/html/chilibot/$user/$folder";

$project=~s/\/$//;


$scale=&del;
&replc($scale);

$frame=<<FRAME;
<html>
	<META NAME="expires" CONTENT="0">
	<title>Chilibot .=. </title>
	<frameset border=2  cols="50%, 50%">
	<frame
	name ="left"
	SRC="/chilibot/$user/$folder/html/left.html"
	Scrolling=auto>
	<frame
	name ="right"
	SRC="/legend.html"
	scrolling=auto>
	</frameset>
FRAME



print "$frame";
print "<b> $relation</b><p>Chilibot has followed your instruction and deleted this relation. Please use the <font size =+1><b>reload</b></font> button of your browser to see the new graph.<br>";
sub del {
	my ($linkcnt);
	open (GDL, "$project/gdl")|| die "missing $project/gdl";
	open (GDLTMP, ">$project/gdl.bak");
	$relation=~/(.+)_(.+)/;
	my $i=$1;
	my $j=$2;
	while (<GDL>) {
		$_=~s/^\s*}//;
		($nodei=$1) if ($_=~s/(.+node.+"$i".+$)//); 
		($nodej=$1) if ($_=~s/(.+node.+"$j".+$)//); 
		$icnt++ if ($_ =~/"$i"/);
		$jcnt++ if ($_ =~/"$j"/);
		if ($_=~/$relation/){
			$relationfound=1;
		} else {
			print GDLTMP "$_" ;
		}

		$linkcnt++ if ($_=~/_/);
	}
	print GDLTMP "\t$nodei\n" if (($icnt>1) || ($relationfound==0));
	print GDLTMP "\t$nodej\n" if (($jcnt>1) || ($relationfound==0));
	print GDLTMP "\n}";
	if ($linkcnt>60){
		$scale=80 ;
	} elsif ($linkcnt>100)  {
		$scale=70;
	} elsif ($linkcnt>200){
		$scale=50;
	} else {
		$scale=100;
	}
	unlink ("$project/gdl");
	rename ("$project/gdl.bak",  "$project/gdl"); 
#print " $relation: $i $icnt, $j $jcnt<br>\n";
	return ($scale);
}

sub replc {
	$scale = shift;
	unlink ("$project/html/chilibot.png") ;
	unlink ("$project/html/aisee.html") ;
	open (DUMMY, "/usr/local/bin/aisee -silent -htmloutput $project/aisee.html -pngoutput $project/html/chilibot.png -lm 0px -tm 0px -scale $scale $project/gdl|") || die "aisee html generation failed";
	close (DUMMY);
	open (LEFT, "$project/html/left.html") || die;
	open (LEFTTMP, ">$project/html/left.tmp") || die;
	$leftprint=1;
	while (<LEFT>){
		if ($_=~/<map name=/){
			$leftprint=0 ;
			open (AISEEHTML, "$project/aisee.html") || die "missing $project/aisee.html";
			print LEFTTMP "<p><map name=\"ImageMap\">";
			while (<AISEEHTML>){
				next if ($_!~/^<area/);
				$mapnode=$1 if ($_=~m|/(.*?).html|);
				$_=~s|\&.038;|$mapnode: abstract co-occurence only|;
				$_=~s|\&.043;|$mapnode: parallel relationship|;
				$_=~s/title="\d\d*"/title="$mapnode: interactive relationship"/;
			#	<area shape="circle" coords="260,120,18" title="10" alt="10" href="./SMST_TRKB.html">
				chomp;
				chop;
				print LEFTTMP "$_";
				print LEFTTMP " target=\"right\">\n";
			}
			print LEFTTMP "<center><table border=1 cellspacing=0><tr><td><img border=\"0\" src=\"chilibot.png\" usemap=\"#ImageMap\"></td></tr></table></center>\n";
		}
		print LEFTTMP $_ if ($leftprint); 		
		$leftprint=1 if ($_=~/usemap="#ImageMap"/);
	}
	rename ("$project/html/left.tmp", "$project/html/left.html");
}

1;


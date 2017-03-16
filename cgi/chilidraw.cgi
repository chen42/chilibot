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
$al=$query->param('ALG');
$symb=$query->param('SYM');
$depth=$query->param('DEP');
$folder=$query->param('FLD');
$min_snt=$query->param('SNT');
$percent=$query->param('PCT');
$level5=$query->param('level5');
$level5=uc($level5);
$project="/home/httpd/html/chilibot/$user/$folder";


$project=~s/\/$//;

&showhub($percent) if ($percent);

sub showhub {
	$percent=shift;
	print  "$htmlcss \n<font size=-1><a href=\"/index.html\" target=_TOP>Chilibot</a> | <a href=/index.html target =_top >New Search</a> | \n <a href=/cgi-bin/chilibot/chilibot.cgi?PREV=t target=_top>Saved Searches </a>|\n </font></p> <center> <h3>$folder</h3></center>";


	open (GDL, "$project/gdl") || die "can't find gdl";
	while (<GDL>) {
		next if ($_!~/edge:/);
		$edgecnt++;
		if ($_=~s/"(.+?)"//){
			$edge{$1} ++ if ($1!~/\_/); 
		}
		if ($_=~s/"(.+?)"//){
			$edge{$1} ++ if ($1!~/\_/); 
		}
	}
	$edgecnt=$edgecnt/2;
	@keys= keys %edge;
	foreach $node (sort {$edge{$b} <=> $edge{$a}} keys %edge ) {
		$edgelist.="$node\t$edge{$node}\n";
		$hub{$node}=1 if ($edge{$node}/$edgecnt>$percent);
	}
	close (GDL);
	open (GDL2, "$project/gdl") || die "can't find gdl";
	open (GDLHUB, ">$project/hubgdl") || die "can't find gdl";
	while ($line = <GDL2>) {
		foreach (keys %hub) {
			if ($line=~/node: \{title: \"$_\"/){
				$line=~s/}/ borderwidth:3 bordercolor: red}/;
				$line=~s/box/ellipse/;
			}
		}
		print GDLHUB $line;
	}
	&aiseehtml ("hubgdl", $edgecnt);
	print "<p align=center><a href=\"/chilibot/$user/$folder/html/left.html\">Back to Main Graph</a><p>";

	#print "<center><p><b>Nodes possessing more than ",$percent*100,"% <br>of the relationships are highlighted</b></center>";
	print "<center><p><b>There are $edgecnt relationships in this map</b></center>";
	print "<center><table width=60% frame=hsides ><tr bgcolor=#AAAAAA><td>Node</td><td colspan=2>Number of Relationships</td></tr>";
	foreach (sort {$edge{$b} <=> $edge{$a}} keys %edge ) {
		print "<tr><td><a href=/chilibot/$user/$folder/html/$_.html target=right>$_</a></td><td align=right>$edge{$_}</td><td align=right> (", int($edge{$_}/$edgecnt*1000)/10, "%)</td></tr>\n"
	}
	print "</table></center>";
	exit 1;
}


sub aiseehtml {
	$file=shift;
	$edgecnt=shift;

	if ($edgecnt>60){
		$scale=80 ;
	} elsif ($edgecnt>100)  {
		$scale=70;
	} elsif ($edgecnt>200){
		$scale=50;
	} else {
		$scale=100;
	}

	open (DUMMY, "/usr/local/bin/aisee -silent -htmloutput $project/$file.html -pngoutput $project/html/$file.png -lm 0px -tm 0px -scale $scale $project/$file|") || die "aisee html generation failed";
	close (DUMMY);
	open (AISEEHTML, "$project/$file.html") || die "missing $project/$file.html";
	print "<p><map name=\"ImageMap\">";
	while (<AISEEHTML>){
		next if ($_!~/^<area/);
		$mapnode=$1 if ($_=~m|/(.*?).html|);
		$_=~s|\&.038;|$mapnode: abstract co-occurence only|;
		$_=~s|\&.043;|$mapnode: parallel relationship|;
		$_=~s/title="\d\d*"/title="$mapnode: interactive relationship"/;
		$_=~s/href="\./href="\/chilibot\/$user\/$folder\/html/;
	#	<area shape="circle" coords="260,120,18" title="10" alt="10" href="./SMST_TRKB.html">
		chomp;
		chop;
		print "$_";
		print " target=\"right\">\n";
	}

		print "<center><table border=1 cellspacing=0><tr><td><img border=\"0\" src=\"/chilibot/$user/$folder/html/$file.png\" usemap=\"#ImageMap\"></td></tr></table></center>\n";
	#print LEFT "<A HREF=\"javascript:popUp('edit.html')\">Edit the map</a><br>\n";

}

open (IN, "$project/gdl") || die "failed to open $project/gdl ";
unlink ("$project/symbgdl");
open (NEWGDL, ">$project/symbgdl")|| die;
@old=<IN>;
#@select=grep {/edge/}@select;


@select= grep {/\"$symb\_|\_$symb\"/} @old; # /"symb='edge' while dealing with the entire graph

#get node color
@nodes=grep {/node/} @old;
foreach (@nodes){
	next if ($_=~/\_/);
	if ($_=~/node: \{\ *title: "(.+?)\"/){
		$node=$1;
		$color{$node}=$1 if ($_=~/color:(\w+) /);
		#print " node: $node ($color{$node})<br>";
	}
}

foreach (@select) {
	#print "--> $_\n<br>";
	#next if ($_ =~ /node:/);
	if ($_ =~ /sourcename: *\"(.+?)\"/){
		$source=$1; 
		$node{$source}=1 if ($source !~ /\_/);
	}
	if ($_ =~ /targetname: *\"(.+?)\"/){
		$target=$1; 
		$node{$target}=1 if ($1 !~ /\_/);
	}
	

}

print NEWGDL $aiseehead[$al], "$aiseecolor\n";	

if ($depth == 1) { # simple graph
	print NEWGDL @select;
	foreach $key (keys %node) {
		
#		next if ($key eq $symb);
		next if ($key eq "");
		print NEWGDL "node: {title: \"$key\" label: \"$key\" shape: box color:$color{$key}}\n";
		#print "node: {title: \"$key\" label: \"$key\" shape: box color:$color{$key}}\n";
		
	}
	print NEWGDL "}";
} else { # depth ==2,redraw main graph 
	$min_snt = -999 if $depth==3; # complex graph;
	foreach(@old) { #decide which one not to print
		undef $pass;
		if ($_ =~ /edge/) {
			$_ =~ /sourcename: *\"(.*?)\"/;
			$priority=1 if ($1 eq $symb);
			$name=$1;
			$_ =~ /targetname: *\"(.*?)\"/;
			$priority=1 if ($1 eq $symb);
			$name.="_".$1;
		} elsif ($_ =~/node/) {
			$_ =~/title: *\"(.*?)\"/;
			$highlight=1 if ($1 eq $symb);
			$level5=1 if ($1 eq $level5);
			$name=$1;
			$_ =~/label: *\"(\d+?)\"/;
			$weight=$1; #count  of the supporting sentences
			$weight=0 if ($_=~/label: *\"=\"/);
			$weight=-1 if ($_=~/label: *\"&\"/);
		} else {
			next;
		}
		if ($name=~/\_/){
			@three=split(/\_/, $name);
			foreach (@three) {
				$pass=1 if (!$node{$_});
				$pass=1 if ($weight<=$min_snt);
			#	print "lnkwght  $weight, usersele: $min_snt,<br>"; 
			}
		} else {
			$pass=1 if (!$node{$name});
		}
		next if ($pass);
		$l=$_;
		($l=~ s/\}$/priority:10\}/) if ($priority);
		if (($l=~/edge/) && ($l=~/$symb/)){
			$l=~ s/\}$/ thickness:3\}/;
			$l=~ s/arrowsize:6/arrowsize:8/;
		}
		($l=~ s/aquamarine/yellow/) if ($highlight);
		if ($depth==3 && $_=~/node/ && defined ($level5)){
			if ($highlight) {
				$l=~ s/\}/ bordercolor:lightred verticalorder:1 \}/; 
			}elsif ($level5==1) {
				$l=~ s/\}/ bordercolor:lightred verticalorder:5 \}/; 
			}elsif ($l!~/_/) {
				$l=~ s/\}/ verticalorder:3 \}/; 
			}elsif ($l=~/$symb\_/ || $_=~/\_$symb/){
				$l=~ s/\}/ verticalorder:2 \}/; 
			}
			$level5=2;
		}
		$l=~s/^\t+/\t/;
		print NEWGDL $l; 
		undef $priority;
		undef $highlight;
	}
	print NEWGDL "}";
}


unlink ("$project/symbvcg");
unlink("$project/symbppm");
open (DUMMY, "/usr/local/bin/aisee -silent -vcgoutput $project/symbvcg $project/symbgdl|");
system ("/usr/local/bin/aisee -silent -color -ppmoutput $project/symbppm   -split 16 -scale 100 $project/symbgdl");
system ("/usr/bin/pnmcrop $project/symbppm >$project/symbcrp.ppm");
unlink("$project/symbppm");
#unlink ("$project/html/chilibot.png") ;
$lower=1000; 
$upper=2000000; 
$random = int(rand( $upper-$lower+1 ) ) + $lower; 
$target_png="$project/html/$random.png";
system ("/usr/bin/pnmtopng $project/symbcrp.ppm >$target_png");
unlink ("$project/symbcrp.ppm");
$target_src=substr($target_png, 16 );

#print  "$htmlcss \n<center><h3><a href=\"http://www.chilibot.net\" target = _top>Chilibot</a> Session: $folder</h3>\n</center>\n<p>";

print  "$htmlcss \n<font size=-1><a href=\"/index.html\" target=_TOP>Chilibot</a> | <a href=/index.html target =_top >New Search</a> | \n <a href=/cgi-bin/chilibot/chilibot.cgi?PREV=t target=_top>Saved Searches </a>|\n </font></p>";
print "<center><h3>$folder</h3>Viewing Sub-network |" if ($symb ne "edge");
print " <a href=\"/chilibot/$user/$folder/html/left.html\">View entire network</a><center><p>";

print  "<map name=\"symbmap\">\n ";
open (VCG, "/$project/symbvcg");
while ($l=<VCG>) {	
	$title=$1 if ($l=~ /title: \"(.+)\"/);
	$loc_x=$1 if ($l=~ /loc: \{ x: (\d+)/);
	$loc_y=$1 if ($l=~ /^ +y: (\d+) +\}/);
	$width=$1 if ($l=~/ width: (\d+)/);
	$height=$1 if ($l=~/height: (\d+)/);
	if (($l =~ /\}/) && ($title)){
		#print "$label, $title, $loc_x, $loc_y, $width, $height\n";
		$loc_x -=9;
		$loc_y -=9;
		$loc_xx=$loc_x+$width+4;
		$loc_yy=$loc_y+$height+4;
		print  "<area shape=\"rect\" coords=\"$loc_x,$loc_y,$loc_xx,$loc_yy\" target=\"right\" href=\"/chilibot/$user/$folder/html/$title.html\">\n";
			$label=$title=$loc_x=$loc_y=$width=$height="";
	}
	
}

print  "</map>\n";


print "<center><table border=1 cellspacing=0><tr><td><img border=\"0\" src=\"$target_src\" usemap=\"#symbmap\"></td></tr></table></center>\n";
#print  "<center><img border=\"0\" src=\"$target_src\" usemap=\"#symbmap\"></center>";

sub disabling_mesh{
print <<MESH;
<center><p>
<form action=/cgi-bin/chilibot/chilimesh.cgi target=right method=post> <input type ="submit" name="IN" value="MESH theme of this subnetwork graph">
	<input type="hidden" name="FLD" value="$folder">
	<input type="hidden" name="GDLFILE" value="symbgdl">
	</FORM>
	</center>
MESH
}


open(OLD, "$project/oldsrc") ;
@old=<OLD>;
$old_img="/home/httpd/html". $old[0];
unlink("$old_img");

open (OLD, ">$project/oldsrc") || die;
print OLD "$target_src";



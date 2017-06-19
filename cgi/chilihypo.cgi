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
$symb=$query->param('SYM');
$folder=$query->param('FLD');
$project="/home/httpd/html/chilibot/$user/$folder";
$project=~s/\/$//;
open (IN, "$project/gdl") || die "failed to open $project/gdl ";
@old=<IN>;
@select= grep {/edge/} @old; 

print  "$htmlcss \n<font size=-1><a href=\"/index.html\" target=_TOP>Chilibot</a> | <a href=/index.html target =_top >New Search</a> | \n <a href=/cgi-bin/chilibot/chilibot.cgi?PREV=t target=_top>Saved Searches </a>|\n </font></p> <center> <h3>$folder</h3></center>";


#get node color
@nodes=grep {/node/} @old;
foreach (@nodes){
	next if ($_=~/\_/);
	if ($_=~/node: \{\ *title: "(.+?)\"/){
		$node=$1;
		$color{$node}=$1 if ($_=~/color:(\w+)\}/);
		#print " node: $node ($color{$node})<br>";
	}
}


@firstTier=&directlink($symb);
foreach $first (@firstTier){
	@secondTier = &directlink($first);
	foreach $second (@secondTier){
		$direct=0;
		foreach (@firstTier){
			if ($second eq $_) {
				$direct=1;
				last;
			}
		}
		next if ($direct==1);
		next if ($second eq $symb);	
		$chain{"$symb <=> $second"} .= "$first, ";
		$chainWeight{"$symb <=> $second"}++;
	}
	undef(@secondTier);
}


@keys=keys (%chain);

@keys= sort {($chainWeight{$b}) <=> ($chainWeight{$a})} (keys %chainWeight);
if (@keys){
	print "<center>New Hypothesis for $symb | <a href=\"/chilibot/$user/$folder/html/left.html\">Back to Main Graph</a></center><p>\n <p>There is no documentation about the relationship between the two terms highlighted in the red boxes. The new hypothesis is that these terms interact through their shared connections to other term(s)<p>\n";

	foreach (@keys){
#		print "$chain{$_}<br>\n";
			$chain{$_}=~s/, $//;
			my @links =split(/, /,$chain{$_});
			($term1, $term2)=split(/ <=> /,$_);
			$hypo++;
			&generateGraph($hypo, $term1, $term2, @links);
	}
} else {
	print "<p> $symb is fully connected and no new hypothesis can be generated.<p><a href=\"/chilibot/$user/$folder/html/left.html\">Back to Main Graph</a><p>";
}



sub generateGraph{
	my  $hypo=shift;
	my $term1=shift;
	my $term2=shift;
	my @links=@_;

	open (OLDGDL, "$project/gdl") || die "failed to open $project/gdl ";
	open (NEWGDL, ">$project/hypo$hypo.gdl")|| die "failed to open gdl for write";
	print NEWGDL $aiseehead[5];
	print NEWGDL $aiseecolor;
	while 	(<OLDGDL>){
		$line=$_;
		if ($line=~/node:|edge:/) {
			if ($line=~/\_/){ #relationship nodes or edges
				foreach(@links){
					$print=1  if ($line=~/"$_\_|\_$_"/) ; 
				}
				if ($line=~/node/){
					($line=~s/}/ vertical_order: 2}/) if ($line=~/"$term1\_|\_$term1"/);
					($line=~s/}/ vertical_order: 4}/) if ($line=~/"$term2\_|\_$term2"/);
				}
				print NEWGDL $line if ($print==1 && $line=~/"$term1\_|\_$term1"|"$term2\_|\_$term2"/);
				undef($print);
			} else { # term nodes
				if ($line=~/\b$term1\b/){
					$line=~s/}/ borderwidth:2 bordercolor: red  vertical_order: 1}/;
					print NEWGDL "$line";
				}
				if ($line=~/\b$term2\b/){
					$line=~s/}/ borderwidth:2 bordercolor: red  vertical_order: 5}/;
					print NEWGDL "$line";
				}
				foreach (@links) {
					if ($line=~/\b$_\b/){ 
						$line=~s/}/ vertical_order: 3}/;
						print NEWGDL "$line";
					}	
				}	
			}
		}
	}
	print NEWGDL "}";
	unlink("$project/html/hypo$hypo.png") if (-e "$project/html/hypo$hypo.png");
	open (DUMMY, "/usr/local/bin/aisee -silent -htmloutput $project/hypo$hypo.html -pngoutput $project/html/hypo$hypo.png -lm 0px -tm 0px -scale 100 $project/hypo$hypo.gdl|") || die "aisee html generation failed";
	close(DUMMY);
	open (AISEEHTML, "$project/hypo$hypo.html") || die "missing $project/hypo$hypo.html";
	print "<map name=\"hypoMap$hypo\">";
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
		print  "$_";
		print  " target=\"right\">\n";
	}
	print "<center><table border=1 cellspacing=0 width=80% ><tr align=center><td>";
	print "<b>$term1 - ? - $term2</b><br>";
#	print " : @links";
	print "</td></tr><tr align=center bgcolor=\"#FFFFFF\"><td><img border=\"0\" src=\"/chilibot/$user/$folder/html/hypo$hypo.png\" usemap=\"#hypoMap$hypo\"></td></tr></table></center>\n";

}

sub directlink{
	my $symb=shift;	
	my %firstTier;
	my %node;
	@select= grep {/$symb/} @old; 
	
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


	foreach $key (keys %node) {
		next if ($key eq $symb);
		next if ($key eq "");
		$firstTier{$key}=1;
	}
	@keys=keys (%firstTier);
	return (@keys);
}



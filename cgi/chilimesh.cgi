#!/usr/bin/perl
require '/home/httpd/cgi-bin/chilibot/chili_strg.pl';

use Digest::MD5 qw(md5_hex);
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use LWP::Simple qw(get);

if (cookie('chocolnuts')){
	print header();
	$user=cookie('chocolnuts');
} 

#else {
#	print header();
#	print $htmlbody;
#	print "<p><center><h3>Please <a href=/index.html target=_top>log in</a> first!</h3></center>";
#	exit 0;
#}

	$query = new CGI;
	$symb=$query->param('SYM');
	$folder=$query->param('FLD');
	$gdlfile=$query->param('GDLFILE');
	$project="/home/httpd/html/chilibot/$user/$folder";
	$project=~s/\/$//;
	$homedir="/home/httpd/html/chilibot/$user";
	open (MAX, "$project/max_abs");
	$max_abs=<MAX>;
	$max_abs=30 if $max_abs<20; #fix a bug in max_abs file
	open (CONTXT, "$project/context");
	$context=<CONTXT>;
	print $htmlbody; 
	print "<h2>MESH keyword themes</h2>The <a heref=\"http://www.nlm.nih.gov/mesh/meshhome.html\">
MESH</a> keywords of the abstracts represented by the graph are collected and sorted by their weighted percentage. When the keyword is the major topic of the publication, it is weighted as 1. Otherwise, it is weighted as 0.5. The weights are then divided by the number of abstracts to obtain the weighted percentage. <p>";

&synlist;
#foreach(keys %seek){ print "seek $_ $seek{$_}<br>"; }
&linklist;
&md5;
&pmidlist;
&getmesh;
&calculatemesh;
&printresult;

sub linklist {
	open (GDL, "$project/$gdlfile") || die "missing gdl file in folder"; 
	while (<GDL>){
		next if ($_!~/node:/);
		next if ($_!~/\{title:\s+\"(\w*?)_(\w*?)\"\s+label/);		
		$md5{&md5_hex($1, $2, $max_abs, $context)}=1;
		#$md5=md5_hex("$seek[$i]", "$seek[$j]", "$max_abs", "$context", "$pubmeddate");
	}
}

sub pmidlist {

	foreach (keys %md5) {
	print "MD5: $_<br>";
		open (PMIDFILE, "$homedir/.pmid/$_") || print "missing md5";
		while (<PMIDFILE>) {
		print "line 61 pmid: $_\n<br>";
			if ($_=~m|<id>(\d+)</id>|i){
				$pmid{$1}=1;
			}
		}
	}				
}

sub getmesh{
	mkdir ("$homedir/.mesh") if (!-e "$homedir/.mesh");
	my $needpmid;	
	foreach (keys (%pmid)){
		print "pmid: $_\n<br>";
		if (!-e "$homedir/.mesh/$_.mh/"){
			$needpmid .="$_".",";
		}
	}
#	print "needed: $needpmid<p>";
	if ($needpmid){
		my $retrieve=get("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=$needpmid&retmode=xml&rettype=citation&tool=fetchAbs");
	#	print "$retrieve\n<br>";
		while ($retrieve=~s|(<PubmedArticle>.+?</PubmedArticle>)||si) {
			#<DescriptorName MajorTopicYN="N">Cadherins</DescriptorName>
			my $record=$1;
			$record=~m|<PMID>(\d+)</PMID>|;
			my $pmid=$1;
			$record=~m|(<MeshHeadingList>.+</MeshHeadingList>)|is;
			my $meshheadings=$1;
			#print "$pmid<br>"; 
			open (MH, ">$homedir/.mesh/$pmid.mh")|| die " could not open mesh heading file for print";
			while ($meshheadings=~s|<DescriptorName(.*?)>(.*?)</DescriptorName>||si){
				my $mesh=$2;
				if ($1=~/MajorTopicYN=\"Y\"/){
					$topic="Y";
				}else{
					$topic="N";
				}

				print MH "$topic\t$mesh\n";
			}
		}
		return 1;
	}
}

sub calculatemesh {
	foreach (keys (%pmid)){
		open (MESH, "$homedir/.mesh/$_.mh")||die"cannot open mesh heading file";	
		$pmidcnt++ if (stat("$homedir/.mesh/$_.mh"))[7]>0;
		while (<MESH>){
			chomp;			
			my($topic, $heading)=split(/\t/,$_);
			if($topic eq "Y"){ 
				$mesh{$heading}++;
			} else {
				$mesh{$heading}=$mesh{$heading}+.5;
			}
		}		
	}
}

sub printresult{
	@keys = sort {$mesh{$b}<=>$mesh{$a}} keys %mesh;
	foreach ( @keys) {
		next if $_=~/^Blotting, |Analysis$|assay$|Immunohistochemistry|^Support,|chain reaction\s*$|^Animals$/i; 
		next if $_=~/^Antibodies, |^Human$|^Rats,*|^Mice,*|^Rabbits,*|^Female$|^Male$|Cells/i;
		next if $_=~/^Aged,*|Aged$|^Adult|^Cell line|^RNA,|^DNA,|English Abstract|studies$|study$/i;
		next if $_=~/Research Support|In vitro|In vivo/i;
		my $weight=int($mesh{$_}/$pmidcnt*100);
		print "$weight\t$_<br>"if ($weight>2);
	}
}
sub md5{
	my $i=shift;
	my $j=shift;
	#print "<p>hash: $seek{$i}<br>$j $seek{$j}<br> max+abs $max_abs, context $context<p>";
	$md5=md5_hex("$seek{$i}", "$seek{$j}", "$max_abs", "$context");
	return $md5;
	#$fileCreatedAt=(stat("$homedir/.pmid/$md5"))[9];
}

sub synlist{
	open (SYNLIST, "$project/synlist") || die;
	my $i=-1;
	my $syno;
	while (<SYNLIST>) {
		chop ($_);
		chop ($_);
		$_=~s/\t/ /g;
		$_=~s/ +/ /g;
		$_=~s/^ | $//g;
		next if ($_ =~ /^ $/);
		if ($_ =~ s/^> *//) {   #start of one symb	
			$i++;
			$symb[$i]= uc ($_);
			$symb[$i]=~s/ *\(INPUT:(.+)\)//;
		} else {
			next if $_=~/^\s*$/;
			# search pubmed for the symbol
			$_=~s/ *$//;
			my $syno=uc($_);
			next if length($syno)<3;
			$syno=~s/ +/\+/g;
			if ($syno !~/ or | and /i){
				#$seek[$i] .=  "\%28\"" . $syno. "\"[tiab]\%29";
				$seek{$symb[$i]} .=  "\%28" . $syno. "[tiab]\%29";
			}
		}
	}
	
	for (0 .. $i) {
		$seek{$symb[$_]}=~ s/\%29\%28/\%29+OR+\%28/g;
		$seek{$symb[$_]}=~ s/ +/\%20/g;
	}
}

=cut
		$match=$1;
		if ($_=~/MajorTopicYN="Y"/){
		} else {
			$mesh{$match}++;
		}
	}
}

	# <DescriptorName MajorTopicYN="N">Colorectal Neoplasms</DescriptorName>
	

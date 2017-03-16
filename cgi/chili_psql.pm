#!/usr/bin/perl

use DBI;
package chili_psql;

sub name {
	my ($fields, $table, $userSupplied, $where, $item, $uid, $symb, $conn, $query, $search, @row, %adjust, @synonyms, @userSyno);
	shift;
	$item=shift;
	if ($item=~s/\((.+)\)//){
		$userSupplied=$1;
		@userSyno =split(/;/,$userSupplied);
	}
  	$fields = "uid, symb, name";
	#==process input
	if ($item =~ / +/) {
		$table="symb_names";
		$item=lc($item);
		$where="name~';;$item;;'";
	} elsif ($item =~ s/^Rn\.//i) {
		$table="rn3_name";
		$where="uid=$item";
	} elsif ($item =~ s/^Hs\.//i) {
		$table="hs3_name";
		$where="uid=$item";
	} elsif ($item =~ s/^Mm\.//i) {
		$table="mm3_name";
		$where="uid=$item";
	} elsif (($item =~/^(\D+)(\d+)/) && (length($1)<=3) && (length($2)>=5)) {
		$table="mm_acc_syno";
		$where="acc='$item'";
  		$fields = "acc, symb, name";
	#print "$table, $where, $1, $2, \n";
	} else { 
		$table="symb_names";
		$item=uc($item);
		$where="symb='$item'";
	}
#print "==>table = $table where= $where <br>";
	#==prepare search	
  	$conn = DBI->connect('dbname=chilibot', 'hao', '', 'Pg');
  	$query = $conn->prepare("SELECT $fields FROM $table where $where");
  	$query->execute();

#	print "SELECT $fields FROM $table where $where<br>";
	$uid=$symb=$names="";
	#==get names
	while (@row = $query->fetchrow_array()) {
		($uid, $symb, $names) = @row; 
		last;	
	}
	$symb=$item if ($symb eq "");
	$symb=~s/^ +| +$//;
	$names =~s/\-|\+|\(|\)|\[|\]|\/|\{|\}|\'|\"|\:|\,/ /g;
	$names =~s/;;$symb;;//i;
	$names =~s/;min \d;|;PURINERGIC RECEPTOR;|;ATP RECEPTOR;|;BRIDGE;|;GTP binding protein;|vial;|;class I;|;c.elegans;|;gpcr;|;Fragments;|;a receptor associated protein;|;cytokine;|;rod;|;ish;|;LYMPHOKINE;//gi;
	$names .=";;$symb";
	$names =~ s/\s+;\s+/;/g;
	$names =~ s/:/ /g;
	$names =~ s/ +/ /g;
	@synonym = split (/;+/, $names);
	undef($query);
	$conn->disconnect();
	$conn = undef;
	#adjust the synomyms	
	foreach (@synonym){
		$_=~s/ +/ /g;
		$_=~s/^\s+|\s+$//g;
		$_=uc($_);
		@comma=split(/,/, $_);
		if ($#comma ==1){
			$_=$comma[1]." ". $comma[0];
		} elsif ($#comma>=3) {
			next;
		}
		next if (length($_)<3);
		if ((length($_) == 3) && (uc($_) ne uc($symb))){ # && ($_!~/\d/)){
			$_= "! ". $_ ;
		}
		if ($_=~s/\-/ /g){
			$adjust{$_}=length($_) ;
			$_=~s/ (\d)/$1/;
			$adjust{$_}=length($_) ;
		}
		$adjust{$_}=length($_) ;

		# chaning creb1 => creb
#		if ($_=~ /(^.*?\D)\-*1$/) { $adjust{$1}=length($1) if (length($1)>2) ; }
		if ($_!~/\s/) {
			if ($_=~s/(\D{2,})(\d{1,2})$/$1 $2/) {
				$adjust{$_}= length($_);
			}
		} 
	}
	$adjust{uc($symb)}=length($symb);
	foreach (@userSyno){
		$_=~s/^ *| *$//;
		$adjust{uc($_)}=length($_);
	}
	undef (@synonym);
	# so that rab11a matches first than rab11
	#@synonym= sort {($adjust{$b}) <=> ($adjust{$a})} (keys %adjust);
	@synonym= sort keys %adjust;
#	foreach (@synonym) { print "<p> synonyms: $_ $adjust{$_}\n"; }
	undef (%adjust);
=comment	
	#==prepare search of omim 	
  	$conn = DBI->connect("dbi:Pg:dbname=medline");
  	$query = $conn->prepare("SELECT  id FROM omim_gene where symb='$symb'");
  	$query->execute();
	my ($omim); 
	#==get symbols->omim_ID
 	while (@row = $query->fetchrow_array()) {
		($omim) = @row;
	}
	undef($query);
	$conn->disconnect();
	$conn = undef;
=cut	
	
#	print "$symb || @synonym;\n";
=cut	
	if ($symb =~/ /) {
		@sym=split(/ +/, $symb);
		$symb="";
		foreach (@sym) {
			$symb.=substr($_, 0,1);
		}
		$symb= "[".$symb."]";
	}
=cut
	return ($symb, @synonym);


}

1;

#!/usr/bin/perl


# change acrline to inputline
## could be shortened 
#use hash intead of $cnt;
#combine two situation :
# 1. CREB (cAMP resp...)
# 2. cAMP res.. (CREB)
package chili_pare;
 
sub paren {

	my ($b, $cnt, $length, $acronym, @p_line, @acr, $start, @fullname,  $acr_cnt);
	my $acrline=$_[1];	 
	print "$acrline<p>\n";
	$acrline =~ s/\(/ \( /g;
	$acrline =~ s/\)/ \) /g;
	$acrline =~ s/-/ - /g;	# brain-derived -> brain - derived
	$acrline =~ s/(\( \w+) \- (\d+ \))/$1$2/ ; #change ( ATF-1 ) -> ( ATF1 )
	$acrline =~ s/\( (\d+) \)/\($1\)/g; #change ( 1 ) -> (1), exclude from futher analysis
	$acrline =~ s/\( (.) \)/\($1\)/g; #change ( a ) -> (a), exclude from futher analysis
	
	#$acrline =~ s/\( [A-Z] \)/\( $1 \)/g; #change (A) -> ( A ), include from futher analysis
	
	$acrline =~ s/\[/ /g;
	$acrline =~ s/\]/ /g;
	$acrline =~ s/\s+/ /g;
	
	#$acrline =~ s/ phosphatidylinositol/ phosphatidyl inositol/g; 
	#print $acrline, "\n"; 
	
	@p_line=split (" ", $acrline);	
	my $left_p=0;
	my $a;	
	for ($a=0; $a<$#p_line; $a++) {
		$left_p -- if ( $p_line[$a] eq ")");
			#print "$p_line[$a], $left_p\n";
		if ($p_line[$a] eq "(") {
			$left_p++;
			if  (($p_line[$a+2] eq ")") && ($left_p == 1)){
				#print "$p_line[$a], $left_p, $p_line[$a+2]\n";
				next if ($p_line[$a+1]  =~ /^\d/);
				next if ($p_line[$a+1]  =~ /\W/);
				#next if ($p_line[$a+1]  =~ /"/);  
##print "acronym: $p_line[$a+1]\n";
		               	$acronym=uc($p_line[$a+1]);
			       #next if ($acronym =~ /\(|\)/);
		               $length=length($acronym );
		               #print  " $acronym eq ", substr($p_line[$a-1], 0, $length), "?\n ";
		               # Dopamine ->dopa
			       if ($acronym eq uc(substr($p_line[$a-1], 0, $length))) {
				       $acr[$acr_cnt]=$p_line[$a+1];
		        	       $fullname[$acr_cnt] =$p_line[$a-1];
		        	       #print $fullname[$acr_cnt], "\n";
		        	       $acr_cnt++;
		        	       next;
		               }
			       # how many words to check forward
			       	if ($length >2) {
 		               		$start=$a-$length-2 ;
			       	} else {
			       		$start=$a-$length-1;
			       	}
			       
			       
		               ($start=0) if $b<0;
		               my $x=$cnt=0;
		               for ($b=$start; $b<$a; $b++) {
		        	       	
		        	       	$word=uc($p_line[$b]);
				      	next if( ($word =~ /\)/) && $cnt>0);     
				         		      
				      	 
				       	if (substr ($word, 0, 1) eq substr($acronym, $x, 1) ){
		        		       	$cnt++;
		        		       	$x++;		        		       
					       	$number_of_word=$b if ($cnt == 1);					       
					       	#print $number_of_word, "xxx\n";
		        	       	} elsif ((substr ($word, 0, 1) eq substr($acronym , $x+1, 1)) && ($cnt>1)) {
		        		       $x=$x+2;
		        		       $cnt++;
		        		       #$number_of_word=$b if ($cnt == 1);
		        	       }
				       # acronym does not contain "," or end with"."
				       $x=$cnt=$number_of_word="" if ($p_line[$b] =~ m/\.$/); # no , is allowed in full name
				       $x=$cnt=$number_of_word="" if ($p_line[$b] =~ m/\,$/); 
		        	     	
				       
				       #print "\t$word< x= $x, cnt=$cnt num_word=$number_of_word-> $p_line[$number_of_word] \n";
				       
		               }
		        	       #print "\n";
		               if ($cnt >= $length -1) {				       
		        	       #print "xx->\t $number_of_word\n";				       
		        	       $acr[$acr_cnt]=($p_line[$a+1]);  			       
		        	       for ($number_of_word .. $a) {  	
				       		next if ($p_line[$_]	=~ /\"|\/|\)|\(|\]|\[|\{|\}/);      
                			       	if ($_ eq $number_of_word) {
					       		next if $p_line[$_] eq "and";
							next if $p_line[$_] eq "to";
							next if $p_line[$_] eq "as";
							next if $p_line[$_] eq "the";
							
						}
					       	$fullname[$acr_cnt].=$p_line[$_]." ";
                		       }				       
		        	       #print $fullname[$acr_cnt], "\n";
				       $fullname[$acr_cnt] =~ s/ - /-/g;				
		        	       $acr_cnt++;
				       next;
		               }
			       
			       # dopamine (DA)
			       if (uc($p_line[$a+1]) eq $p_line[$a+1]) {
			       		#print uc($p_line[$a+1]) , "  yy  ", $p_line[$a+1];
					#print substr($p_line[$a+1], 0, 1), " xx " ,substr($p_line[$a-1], 0, 1), "\n";
			       		if (substr($p_line[$a+1], 0, 1) eq uc(substr($p_line[$a-1], 0, 1))){
			       			@acr[$acr_cnt]=$p_line[$a+1];
		        	       		$fullname[$acr_cnt] =$p_line[$a-1];					       
		        	       		#print $fullname[$acr_cnt], "\n";
		        	       		$acr_cnt++;		        	       	 
					}			       
			       }
		        	       
		       } else {
		       		# deal with ( xx xx );
		               # CREB (cAMP response element binding protein), 
 		               # RSK2 (ribosomal S6 kinase-2)
  		               #print "$p_line[$a-1]\n";
		               $cnt=$x=0;
		               my $multiword=$p_cnt="";
		               my $ary_out=uc($p_line[$a-1]); #acronym outside the ()
			       if ($ary_out =~ /^\W|\.|^\d+$/) { #exclude 23, . - etc
				       	$ary_out=uc($p_line[$a-2]); #S-(2,4-dinitrophenyl)
				}
				#print $ary_out, "<-=\n";
			       
				
		               for ($a+1 .. $#p_line) {	
			       		$p_cnt ++ if ($p_line[$_] eq "(");	
					$p_cnt -- if ($p_line[$_] eq ")");			  
					#print "$p_line[$_]<  $p_cnt \n";
		        	       	if (( $p_line[$_] eq ")" ) && ($p_cnt == -1)){
				       		#print "\t$p_line[$_]<   \n";				       
		        		       #print "cnt=$cnt, length of a-1",   length($p_line[$a-1]), "\n";
		        		       if (($cnt>=length($ary_out)-1) && ($cnt>1)){ #need at least match 2 characters					         
		        			       $acr[$acr_cnt] = $ary_out;
		        			       $fullname[$acr_cnt] = $multiword;
		        			       $acr_cnt++;
						       #print STDERR "\t >>>> cnt=$cnt $multiword, \n";						       
		        			       eval ($acrline=~ s/\(\s*$multiword\s*\)//);
		        		       } 
		        		       last;
		        	       } else {
				       		next if ($p_line[$_] =~ /\(|\)/); # better solution needed
		        		       $multiword .=$p_line[$_]." "; # collect the phrase in ();					      
		        		       $word_in=uc($p_line[$_]);
		        		       if (substr($ary_out, $x, 1) eq substr($word_in,0,1)) {
					       		#print "in=", substr($word_in,0,1), "\n";
		        			       $cnt++;
		        			       $x++;
		        		       } elsif (substr($ary_out, $x+1, 1) eq substr($word_in,0,1)) {
					       		#print "in2=", substr($word_in,0,1), "\n";
		        			       $cnt++;
		        			       $x=$x+2;
		        		       }					       
		        	       }
		       		}
			} 
		}
	}
	for(0 .. $#acr) {
		
		#$acrline =~ s/\(\s$acr[$_]\s\)//g;
		$acr[$_]=~ s/\(|\)//g;
 		#print "\t$acr[$_] -> $fullname[$_] \n";
		$fullname[$_]=~ s/ +$//;
		$acrline =~ s/\b($acr[$_])\b/$1 x_$fullname[$_]_y /g;
		#$acrline =~ s/$fullname[$_] +\( $acr[$_] \)/ $fullname[$_] /g;
		
	}
		 
	$acrline =~ s/\s+/ /g;
	$acrline =~ s/\s+-\s+/-/g;
	
	 
	 
	print "after -> $acrline <p>";
	 
	return $acrline;
	 
}


1;

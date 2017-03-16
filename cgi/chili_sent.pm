#!/usr/bin/perl

package chili_sent;

# object contains properties of the sentence but not the text of the sentence
# summation of relationship between two genes takes place at aisee

sub new {
	my ($classname, $geneA, $geneB, $effect) = @_;
	my ($genobj) = {};
	bless $genobj;
	$$genobj{'source'}=$geneA;
	$$genobj{'target'}=$geneB;
	$$genobj{'effect'}=$effect;
#	$$genobj{'weight'}="";
#	$$genobj{'brain'} ="";
	return $genobj;
}
	
sub rev {
	my ($genobj) = shift;
	($$genobj{'source'}, $$genobj{'target'}) = ($$genobj{'target'}, $$genobj{'source'}) ;
	
}
sub source {
	my ($genobj) = shift;
	return $$genobj{'source'};
}
sub target {
	my ($genobj) = shift;
	return $$genobj{'target'};
}
sub effect {
	my ($genobj) = shift;
	return $$genobj{'effect'};
}
sub modify {
	# change effect by modifier such as "inhibitors"..
	my ($genobj, $modifier) = @_;
	if ($$genobj{'effect'} == 0) {
		$$genobj{'effect'} =1;
	}
	 
	$$genobj{'effect'} *=$modifier;
}
	
sub disp {
	my $genobj = shift;
	print "\n
	source is  $$genobj{'source'} 
	target is  $$genobj{'target'} 
	effect is $$genobj{'effect'}
	";

}


	
1;

#!usr/bin/perl
#
open(fakeExons,$ARGV[0]);
####file with only fakeexons to have info for identificatio
while(<fakeExons>)
{	chomp $_;
	@identify=split("\t",$_);
	$exonInfo=$identify[0].$identify[3].$identify[4];
	#print "$exonInfo\n";
	$fakes{$exonInfo}="";
}
#print %fakes;

####use the fake exons info to remove them from the tmerged files
open(tm,$ARGV[1]);
open(FE, '>', $ARGV[2]);
open(finalTMs, '>', $ARGV[3]);
while(<tm>)
{	chomp $_;
	@TM=split("\t",$_);
	$tmInfo=$TM[0].$TM[3].$TM[4];
	#print "$tmInfo";
####move fake exons into a faekexonsextracted_species file
	if(exists($fakes{$tmInfo}))
	{	print FE "$_\n";
	}
####move normal TMs into finalTMs_species file
	else
	{	print finalTMs "$_\n";
	}
}

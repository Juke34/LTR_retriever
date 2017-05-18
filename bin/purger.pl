#!/usr/bin/perl -w
use strict;

my $usage="
Clean up sequence using blast resuls

perl purger.pl -blast blast_outfmt6 -seq seq [options]

Dependency: combine_overlap.pl, call_seq_by_list.pl

Shujun Ou (oushujun\@msu.edu)
04/17/2017
\n";


#take blast outfmt=6 output, with each column means:
#query id, subject id, % identity, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score

my $script_path=`readlink -fn -- $0`;
$script_path=~s/(.+)\/.+$/$1/;

my $seq; #provide the sequence to be purged
my $blast; #provide the blast outfmt=6 result
my $evalue=0.001; #evalue cutoff for blast entries. Evalues lower than this cutoff is considered a real alignment.
my $length=90; #alignment cutoff (bp, default 90) to be considered as a real alignment
my $purge=1; #switch on=1(default)/off=0 to clean up aligned region and joint unaligned sequences
my $coverage=1; #if the excluded portion is too long (default 1, [0-1]), discard the entire sequence

my $k=0;
foreach my $para (@ARGV){
	$seq=$ARGV[$k+1] if $para=~/^-seq$/i;
	$blast=$ARGV[$k+1] if $para=~/^-blast$/i;
	$evalue=$ARGV[$k+1] if $para=~/^-eval$/i;
	$length=$ARGV[$k+1] if $para=~/^-len$/i;
	$coverage=$ARGV[$k+1] if $para=~/^-cov$/i;
	$purge=$ARGV[$k+1] if $para=~/^-purge$/i;
	$k++;
	}

open File, "<$blast" or die $!;
my %query; #store query information
my $info='';
while (<File>){
	my ($query, $len, $qstart, $qend, $eval)=(split)[0,3,6,7,10];
	($qstart, $qend)=($qend, $qstart) if $qstart>$qend;
	$info.="$query\t$qstart\t$qend\n" if ($eval<=$evalue and $len>=$length);
}
$info="Good news! No sequence is needed to be purged.\n" if $info eq '';
open Out, ">$seq.exclude.temp";
print Out "$info";
close Out;
`perl ${script_path}/combine_overlap.pl $seq.exclude.temp $seq.exclude.list`;
`rm $seq.exclude.temp`;

`awk '{print \$1\"\\t\"\$1\":\"\$2\"..\"\$3}' $seq.exclude.list | perl ${script_path}/call_seq_by_list.pl - -C $seq -ex -cov $coverage -purge $purge > $seq.clean`;

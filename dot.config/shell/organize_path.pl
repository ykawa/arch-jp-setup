use strict;
use warnings FATAL => 'all';
use utf8;

binmode STDIN,  ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";

my $a = [];
for my $path ( split( /:/, $ENV{"PATH"} ) )
{
  next if !-d $path;
  push @$a, $path unless grep { $_ eq $path } @$a;
}
print "\"PATH=" . join( ':', @$a ) . "\"\n";

#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Importer::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

Catmandu::Importer::AlephX->new(
  url => 'http://aleph.ugent.be/X',
  query => 'WRD=(art)',
  base => 'usm01',
)->each(sub{
  print Dumper(shift);
});

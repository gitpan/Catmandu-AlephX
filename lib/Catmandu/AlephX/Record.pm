package Catmandu::AlephX::Record;
use Catmandu::Sane;
use Data::Util qw(:validate);
use Moo;
use Catmandu::AlephX::Metadata;

has metadata => (
  is => 'ro',
  required => 1,
  isa => sub {
    my $metadata = shift;
    array_ref($metadata);
    for(@$metadata){
      instance($_,"Catmandu::AlephX::Metadata");
    }
  }
);

1;

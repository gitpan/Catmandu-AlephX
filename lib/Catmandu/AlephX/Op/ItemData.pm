package Catmandu::AlephX::Op::ItemData;
use Catmandu::Sane;
use Data::Util qw(:check :validate);
use Moo;

with('Catmandu::AlephX::Response');

has items => (
  is => 'ro',
  lazy => 1,
  isa => sub{
    array_ref($_[0]);
    for(@{ $_[0] }){
      hash_ref($_);
    }
  },
  default => sub {
    [];
  }
); 
sub op { 'item-data' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my @items;

  for my $item($xpath->find('/item-data/item')->get_nodelist()){
    push @items,get_children($item);
  }
  __PACKAGE__->new(
    session_id => $xpath->findvalue('/item-data/session-id'),
    error => $xpath->findvalue('/item-data/error'),
    items => \@items
  );
} 

1;

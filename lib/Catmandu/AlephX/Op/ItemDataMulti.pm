package Catmandu::AlephX::Op::ItemDataMulti;
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
has start_point => (is => 'ro');

sub op { 'item-data-multi' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my $op = op();
  
  my @items;

  for my $item($xpath->find("/$op/item")->get_nodelist()){
    push @items,get_children($item,1);
  }
  __PACKAGE__->new(
    session_id => $xpath->findvalue("/$op/session-id"),
    error => $xpath->findvalue("/$op/error"),
    items => \@items,
    start_point => $xpath->findvalue("/$op/start-point")
  );
} 

1;

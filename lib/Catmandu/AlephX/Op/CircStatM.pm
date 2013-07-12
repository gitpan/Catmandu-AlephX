package Catmandu::AlephX::Op::CircStatM;
use Catmandu::Sane;
use Data::Util qw(:check);
use Moo;

with('Catmandu::AlephX::Response');

#difference from CircStatus: former cannot fetch documents with than 1000 items

has item_data => (
  is => 'ro',
  isa => sub { array_ref($_[0]); }
);
#only appears in the xml output when over 990 items are present
has start_point => (
  is => 'ro'
);

sub op { 'circ-stat-m' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my $op = op();

  my @item_data;

  for my $i($xpath->find("/$op/item-data")->get_nodelist()){
    push @item_data,get_children($i,1);   
  }

  __PACKAGE__->new(
    start_point => $xpath->findvalue("/$op/start-point"),
    item_data => \@item_data,
    session_id => $xpath->findvalue("/$op/session-id"),
    error => $xpath->findvalue("/$op/error")
  );
  
}

1;

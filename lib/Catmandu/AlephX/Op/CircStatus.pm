package Catmandu::AlephX::Op::CircStatus;
use Catmandu::Sane;
use Data::Util qw(:check);
use Moo;

with('Catmandu::AlephX::Response');

has item_data => (
  is => 'ro',
  isa => sub { array_ref($_[0]); }
);

sub op { 'circ-status' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my $op = op();

  my @item_data;

  for my $i($xpath->find("/$op/item-data")->get_nodelist()){
    push @item_data,get_children($i,1);   
  }

  __PACKAGE__->new(
    item_data => \@item_data,
    session_id => $xpath->findvalue("/$op/session-id"),
    error => $xpath->findvalue("/$op/error")
  );
  
}

1;

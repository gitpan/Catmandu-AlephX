package Catmandu::AlephX::Op::ReadItem;
use Catmandu::Sane;
use Data::Util qw(:check :validate);
use Moo;

with('Catmandu::AlephX::Response');

has z30 => (
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
sub op { 'read-item' } 

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my @z30;

  for my $z($xpath->find('/read-item/z30')->get_nodelist()){
    push @z30,get_children($z,1);
  }    

  __PACKAGE__->new(
    session_id => $xpath->findvalue('/read-item/session-id'),
    error => $xpath->findvalue('/read-item/error'),
    z30 => \@z30
  );
}

1;

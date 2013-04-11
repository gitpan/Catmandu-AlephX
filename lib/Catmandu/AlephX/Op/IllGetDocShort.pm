package Catmandu::AlephX::Op::IllGetDocShort;
use Catmandu::Sane;
use Data::Util qw(:check :validate);
use Moo;

with('Catmandu::AlephX::Response');

has z13 => (
  is => 'ro',
  lazy => 1,
  isa => sub{
    hash_ref($_[0]);
  },
  default => sub { {}; }
); 
sub op { 'ill-get-doc-short' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my $z13 = {};

  my($z) = $xpath->find('/ill-get-doc-short/z13')->get_nodelist();

  $z13 = get_children($z) if $z;

  __PACKAGE__->new(
    session_id => $xpath->findvalue('/ill-get-doc-short/session-id'),
    error => $xpath->findvalue('/ill-get-doc-short/error'),
    z13 => $z13
  );
}

1;

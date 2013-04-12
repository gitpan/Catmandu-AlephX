package Catmandu::AlephX::Op::Renew;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;

with('Catmandu::AlephX::Response');

has reply => (
  is => 'ro',
  required => 1,
  isa => sub{
    check_string($_[0]);
  }
);
has due_date => (
  is => 'ro',
  required => 1,
  isa => sub {
    check_number($_[0]) && check_positive($_[0]);
  }
);
has due_hour => (
  is => 'ro',
  required => 1,
  isa => sub {
    check_number($_[0]) && check_positive($_[0]);
  }
);

sub op { 'renew' } 

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);
  my $op = op();

  my %args;
  for(qw(session-id error reply due-date due-hour)){
    my $key = $_;
    $key =~ s/-/_/go;
    $args{$key} = $xpath->findvalue("/$op/$key");
  }

  __PACKAGE__->new(%args);
}

1;

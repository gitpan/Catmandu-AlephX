package Catmandu::AlephX::Op::Renew;
use Catmandu::Sane;
use Data::Util qw(:check :validate);
use Moo;

with('Catmandu::AlephX::Response');

has reply => (
  is => 'ro'
); 
has due_date => (
  is => 'ro'
);
has due_hour => (
  is => 'ro'
);

sub op { 'renew' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);
  my $op = op();

  __PACKAGE__->new(
    session_id => $xpath->findvalue('/'.$op.'/session-id'),
    error => $xpath->findvalue("/$op/error|/$op/error-text-1|/$op/error-text-2"),    
    reply => $xpath->findvalue('/'.$op.'/reply'),
    due_date => $xpath->findvalue('/'.$op.'/due-date'),
    due_hour => $xpath->findvalue('/'.$op.'/due-hour')
  );
} 

1;

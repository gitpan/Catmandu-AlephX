package Catmandu::AlephX::Op::IllGetDoc;
use Catmandu::Sane;
use Data::Util qw(:check);
use Catmandu::AlephX::Metadata::MARC;
use Moo;

with('Catmandu::AlephX::Response');

#format: [ { _id => <id>, record => <doc>}, .. ]
#<doc> has extra tag in marc array called 'AVA'
has record => (
  is => 'ro',
  isa => sub { array_ref($_[0]); }
);
sub op { 'ill-get-doc' }

sub parse {
  my($class,$str_ref) = @_;

  my $xpath = xpath($str_ref);

  my $op = op();
  my $record;

  $xpath->registerNs("marc","http://www.loc.gov/MARC21/slim/");
  my($marc) = $xpath->find("/$op/marc:record")->get_nodelist();

  if($marc){    

    #remove controlfield with tag 'FMT' and 'LDR' because Catmandu::Importer::MARC cannot handle these
    $record = Catmandu::AlephX::Metadata::MARC->parse($marc)->data();
    say "record: $record";

  }

  __PACKAGE__->new(
    error => $xpath->findvalue("/$op/error"),
    session_id => $xpath->findvalue("/$op/session-id"),
    record => $record
  ); 
}

1;

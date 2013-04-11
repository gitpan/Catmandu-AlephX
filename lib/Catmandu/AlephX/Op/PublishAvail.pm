package Catmandu::AlephX::Op::PublishAvail;
use Catmandu::Sane;
use Data::Util qw(:check);
use Catmandu::AlephX::Metadata::MARC;
use Moo;

with('Catmandu::AlephX::Response');

#format: [ { _id => <id>, record => <doc>}, .. ]
#<doc> has extra tag in marc array called 'AVA'
has list => (
  is => 'ro',
  isa => sub { array_ref($_[0]); }
);
sub op { 'publish-avail' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my $op = op();
  my @list;

  for my $record($xpath->find("/$op/OAI-PMH/ListRecords/record")->get_nodelist()){
    my $identifier = $record->findvalue("./header/identifier");
    $identifier =~ s/aleph-publish://o;

    my($record) = $record->find("./metadata/record")->get_nodelist();
    if(!$record){
      push @list,{ _id => $identifier, record => undef };
    }else{
      #remove controlfield with tag 'FMT' and 'LDR' because Catmandu::Importer::MARC cannot handle these
      my $r = Catmandu::AlephX::Metadata::MARC->parse($record);
      push @list,{ _id => $identifier, record => $r->data };
    }
  }

  __PACKAGE__->new(
    error => $xpath->findvalue("/$op/error"),
    session_id => $xpath->findvalue("/$op/session-id"),
    list => \@list
  ); 
}

1;

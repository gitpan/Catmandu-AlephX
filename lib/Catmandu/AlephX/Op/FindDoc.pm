package Catmandu::AlephX::Op::FindDoc;
use Catmandu::Sane;
use Moo;
use Catmandu::AlephX::Metadata::MARC::Aleph;
use Catmandu::AlephX::Record;

with('Catmandu::AlephX::Response');

has record => ( 
  is => 'ro'
);
sub op { 'find-doc' }

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my @metadata = ();

  #metadata
  my($oai_marc) = $xpath->find('/find-doc/record[1]/metadata/oai_marc')->get_nodelist();

  push @metadata,Catmandu::AlephX::Metadata::MARC::Aleph->parse($oai_marc) if $oai_marc;

  __PACKAGE__->new(
    record => Catmandu::AlephX::Record->new(metadata => \@metadata),
    session_id => $xpath->findvalue('/find-doc/session-id'),
    error => $xpath->findvalue('/find-doc/error')
  );
  
}

1;

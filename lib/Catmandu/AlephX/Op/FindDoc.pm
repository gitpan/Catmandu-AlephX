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
  my($class,$str_ref,$args) = @_;
  my $doc_num = $args->{doc_num} || $args->{doc_number};

  my $xpath = xpath($str_ref);
  my $op = op();

  my @metadata = ();

  __PACKAGE__->new(
    record => Catmandu::AlephX::Record->new(metadata => sub {
      my($oai_marc) = $xpath->find("/$op/record[1]/metadata/oai_marc")->get_nodelist();
      if($oai_marc){
        my $m = Catmandu::AlephX::Metadata::MARC::Aleph->parse($oai_marc);
        $m->data->{_id} = $doc_num;
        return $m;
      }
    }),
    session_id => $xpath->findvalue("/$op/session-id"),
    errors => $class->parse_errors($xpath),
    content_ref => $str_ref
  );
  
}

1;

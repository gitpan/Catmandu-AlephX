package Catmandu::Store::AlephX;
use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Catmandu::AlephX;
use Moo;

our $VERSION = "0.01";

with 'Catmandu::Store';

has url => (is => 'ro', required => 1);
has username => ( is => 'ro' );
has password => ( is => 'ro' );

has alephx => (
  is       => 'ro',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_alephx',
);
around default_bag => sub {
  'usm01';
};

sub _build_alephx {
  my $self = $_[0];
  my %args = (url => $self->url());
  if(is_string($self->username) && is_string($self->password)){
    $args{default_args} = {
      user_name => $self->username,
      user_password => $self->password
    };
  }
  Catmandu::AlephX->new(%args);
}


package Catmandu::Store::AlephX::Bag;
use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:check :is);
use Catmandu::Hits;
use Clone qw(clone);
use Carp qw(confess);

with 'Catmandu::Bag';
with 'Catmandu::Searchable';

#override automatic id generation from Catmandu::Bag
before add => sub { 
  check_catmandu_marc($_[1]);    
  $_[1] = clone($_[1]);  
  if(is_string($_[1]->{_id})){
    $_[1]->{_id} =~ /^\d{9}$/o or confess("invalid _id ".$_[1]->{_id});   
  }else{
    $_[1]->{_id} = sprintf("%-9.9d",0);
  }
};

sub check_catmandu_marc {
  my $r = $_[0];
  check_hash_ref($r);  
  check_array_ref($r->{record});
  check_array_ref($_) for @{ $r->{record} };
}

sub get {
  my($self,$id)=@_;
  my $alephx = $self->store->alephx;

  my $find_doc = $alephx->find_doc(
    format => 'marc',
    doc_num => $id,
    base => $self->name,
    #override user_name to disable user check
    user_name => ""
  );
  
  return unless($find_doc->is_success);

  $find_doc->record->metadata->data;
}
=head2 add($catmandu_marc)

=head3 example

  #add new record. WARNING: Aleph will ignore the 001 field, 
  my $new_record = $bag->add({
    record =>  [
      [
        'FMT',
        '',
        '',
        '_',
        'SE'
      ],
      [
        'LDR',
        '',
        '',
        '_',
        '00000cas^^2200385^a^4500'
      ],
      [
        '001',
        '',
        '',
        '_',
        '000000444'
      ],
      [
        '005',
        '',
        '',
        '_',
        '20140212095615.0'
      ] 
      ..
    ]    
  });
  say "new record:".$record->{_id};

=cut
sub add {
  my($self,$data)=@_;

  my $alephx = $self->store->alephx;

  #insert/update
  my $update_doc = $alephx->update_doc(
    library => $self->name,
    doc_action => 'UPDATE',
    doc_number => $data->{_id},
    marc => $data
  );
  
  #_id not given: new record explicitely requested 
  if(int($data->{_id}) == 0){
    if($update_doc->errors()->[-1] =~ /Document: (\d{9}) was updated successfully/i){
      $data->{_id} = $1;    
    }else{
      confess($update_doc->errors()->[-1]);
    }
  }
  #_id given: update when exists, insert when not
  else{
 
    #error given, can have several reasons: real error or just warnings + success message   
    unless($update_doc->is_success){

      #document does not exist (yet)
      if($update_doc->errors()->[-1] =~ /Doc number given does not exist/i){

        #'If you want to insert a new document, then the doc_number you supply should be all zeroes'
        my $new_doc_num = sprintf("%-9.9d",0);

        #last error should be 'Document: 000050105 was updated successfully.'
        $update_doc = $alephx->update_doc(
          library => $self->name,
          doc_action => 'UPDATE',
          doc_number => $new_doc_num,
          marc => $data
        );  

        if($update_doc->errors()->[-1] =~ /Document: (\d{9}) was updated successfully/i){

          $data->{_id} = $1;

        }else{

          confess $update_doc->errors()->[-1];

        }

      }
      #update ok
      elsif($update_doc->errors()->[-1] =~ /updated successfully/i){

        #all ok

      }
      #other severe errors (permissions, format..)
      else{

        confess $update_doc->errors()->[-1];

      }

    }
    #no errors given: strange
    else{
      #when does this happen?
      confess "how did you end up here?";
    }

  }
  #record is ALWAYS changed by Aleph, so fetch it again
  $self->get($data->{_id});
  
}

sub delete {
  my($self,$id)= @_;
  
  my $xml_full_req = <<EOF;
<?xml version="1.0" encoding="UTF-8" ?>
<find-doc><record><metadata><oai_marc><fixfield id="001">$id</fixfield></oai_marc></metadata></record></find-doc>
EOF
  
  #insert/update
  my $update_doc = $self->store->alephx->update_doc(
    library => $self->name,
    doc_action => 'DELETE',
    doc_number => $id,
    xml_full_req => $xml_full_req
  );

  #last error: 'Document: 000050124 was updated successfully.'
  (scalar(@{ $update_doc->errors() })) && ($update_doc->errors()->[-1] =~ /Document: $id was updated successfully./);  
}
sub generator {
  my $self = $_[0];

  #TODO: skip deleted records? (DEL$$a == 'Y')
  #      <varfield id="DEL" i1=" " i2=" "><subfield label="a">Y</subfield></varfield>
  #TODO: in some cases, deleted records are really removed from the database
  #      in these cases, it does not make sense to interpret a failing 'find-doc' as the end of the database.
  #      to compete with these 'holes', the size of the hole need to be defined (how big before thinking this is the end)

  sub {
    state $count = 1;
    state $base = $self->name;
    state $alephx = $self->store->alephx;

    my $doc_num = sprintf("%-9.9d",$count++);
    my $find_doc = $alephx->find_doc(base => $base,doc_num => $doc_num,user_name => "");

    return unless $find_doc->is_success;

    return {
      record => $find_doc->record->metadata->data->{record},
      _id => $doc_num
    };
    
  };
}
#warning: no_entries is the maximum number of entries to be retrieved (always lower or equal to no_records)
#         specifying a set_entry higher than this, has no use, and leads to the error 'There is no entry number: <set_entry> in set number given'
sub search {
  my($self,%args)=@_;

  my $query = delete $args{query};
  my $start = delete $args{start};
  $start = is_natural($start) ? $start : 0;
  my $limit = delete $args{limit};
  $limit = is_natural($limit) ? $limit : 20;

  my $alephx = $self->store->alephx;
  my $find = $alephx->find(
    request => $query,    
    base => $self->name,
    user_name => ""
  );
  
  return unless $find->is_success;

  my $no_records = int($find->no_records);
  my $no_entries = int($find->no_entries);
    
  my $s = sprintf("%-9.9d",$start + 1);
  my $l = $start + $limit;
  my $e = sprintf("%-9.9d",($l > $no_entries ? $no_entries : $l));
  my $set_entry = "$s-$e";

  my $present = $alephx->present(set_number => $find->set_number,set_entry => $set_entry,format => 'marc',user_name => "");

  return unless $present->is_success;

  my @results;

  @results = map { $_->metadata->data; } @{ $present->records() };

  my $hits = Catmandu::Hits->new({
    limit => $limit,
    start => $start,
    total => $find->no_records,
    hits  => \@results,
  }); 
}
sub searcher {
  die("not implemented");
}

#not supported for security reasons
sub delete_all {
  die("not supported");
}
sub delete_by_query {
  die("not supported");
}
sub translate_sru_sortkeys {
  die("not supported");
}
sub translate_cql_query {
  die("not supported");
}
1;

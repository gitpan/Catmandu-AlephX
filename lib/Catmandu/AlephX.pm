package Catmandu::AlephX;
use Catmandu::Sane;
use Carp qw(confess);
use Moo;
use LWP::UserAgent;
use URI::Escape;
use Data::Util qw(:check :validate);

our $VERSION = "1.05";

has url => (
  is => 'ro',
  isa => sub { $_[0] =~ /^https?:\/\//o or die("url must be a valid web url\n"); },
  required => 1
);
has _web => (
  is => 'ro',
  lazy => 1,
  default => sub {
    LWP::UserAgent->new(
      cookie_jar => {}
    );
  }
);
sub _validate_web_response {
  my($res) = @_;
  $res->is_error && confess($res->content);
}
sub _do_web_request {
  my($self,$params,$method)=@_;
  $method ||= "GET";
  my $res;
  if(uc($method) eq "GET"){
    $res = $self->_get($params);
  }elsif(uc($method) eq "POST"){
    $res = $self->_post($params);
  }else{
    confess "method $method not supported";
  }
  _validate_web_response($res);
  $res;
}
sub _post {
  my($self,$data)=@_;
  $self->_web->post($self->url,_construct_params_as_array($data));
}
sub _construct_query {
  my $data = shift;
  my @parts = ();
  for my $key(keys %$data){
    if(is_array_ref($data->{$key})){
      for my $val(@{ $data->{$key} }){
          push @parts,URI::Escape::uri_escape($key)."=".URI::Escape::uri_escape($val // "");
      }
    }else{
      push @parts,URI::Escape::uri_escape($key)."=".URI::Escape::uri_escape($data->{$key} // "");
    }
  }
  join("&",@parts);
}
sub _construct_params_as_array {
    my $params = shift;
    my @array = ();
    for my $key(keys %$params){
        if(is_array_ref($params->{$key})){
            #PHP only recognizes 'arrays' when their keys are appended by '[]' (yuk!)
            for my $val(@{ $params->{$key} }){
                push @array,$key => $val;
            }
        }else{
            push @array,$key => $params->{$key};
        }
    }
    return \@array;
}
sub _get {
  my($self,$data)=@_;
  my $query = _construct_query($data) || "";
  $self->_web->get($self->url."?$query");
}
=head1 NAME

  Catmandu::AlephX - Low level client for Aleph X-Services

=head1 SYNOPSIS

  my $aleph = Catmandu::AlephX->new(url => "http://aleph.ugent.be");
  my $item_data = $aleph->item_data(base => "rug01",doc_number => "001484477");


  #all public methods return a Catmandu::AlephX::Response
  # 'is_success' means that the xml-response did not contain the element 'error'
  # other errors are thrown (xml parse error, no connection ..)

  if($item_data->is_success){

    say "valid response from aleph x server";

  }else{

    say "aleph x server returned error-response: ".$item_data->error;

  }

=head1 METHODS

=head2 item-data
 
=head3 documentation from AlephX
 
The service retrieves the document number from the user.
For each of the document's items it retrieves:
  Item information (From Z30).
  Loan information (from Z36).
  An indication whether the request is on-hold

=head3 example

  my $item_data = $aleph->item_data(base => "rug01",doc_number => "001484477");
  if($item_data->is_success){
    for my $item(@{ $item_data->items() }){
      print Dumper($item);
    };
  }else{
    print STDERR $item_data->error."\n";
  }

=head3 remarks
  
  This method is equivalent to 'op' = 'item-data'

=cut
sub item_data {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::ItemData;
  $args{'op'} = Catmandu::AlephX::Op::ItemData->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::ItemData->parse($res->content_ref());    
}
=head2 item-data-multi
 
=head3 documentation from AlephX
 
This service takes a document number from the user and for each of the document's items retrieves the following:
  Item information (from Z30)
  Loan information (from Z36)
An indication of whether or not the item is on hold, has hold requests, or is expected (that is, has not arrived yet but is expected)
It is similar to the item_data X-service, except for the parameter START_POINT, which enables the retrieval of information for documents with more than 1000 items.

=head3 example

  my $item_data_m = $aleph->item_data_multi(base => "rug01",doc_number => "001484477",start_point => '000000990');
  if($item_data_m->is_success){
    for my $item(@{ $item_data_m->items() }){
      print Dumper($item);
    };
  }else{
    print STDERR $item_data_m->error."\n";
  }

  say "items retrieved, starting at ".$item_data_m->start_point() if $item_data_m->start_point();

=head3 remarks
  
  This method is equivalent to 'op' = 'item-data-multi'
  The attribute 'start_point' only supplies a value, if the document has over 990 items

=cut
sub item_data_multi {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::ItemDataMulti;
  $args{'op'} = Catmandu::AlephX::Op::ItemDataMulti->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::ItemDataMulti->parse($res->content_ref());    
}
=head2 read_item

=head3 documentation from AlephX

  The service retrieves a requested item's record from a given ADM library in case such an item does exist in that ADM library.

=head3 example

  my $readitem = $aleph->read_item(library=>"usm50",item_barcode=>293);
  if($readitem->is_success){
    for my $z30(@{ $readitem->z30 }){
      print Dumper($z30);
    }
  }else{
    say STDERR $readitem->error;
  }

=head3 remarks

  This method is equivalent to 'op' = 'read-item'

=cut

sub read_item {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::ReadItem;
  $args{'op'} = Catmandu::AlephX::Op::ReadItem->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::ReadItem->parse($res->content_ref());    
}

=head2 find

=head3 documentation from Aleph X
  
  This service retrieves a set number and the number of records answering a search request inserted by the user.

=head3 example
  
  my $find = $aleph->find(request => 'wrd=(art)',base=>'rug01');
  if($find->is_success){
    say "set_number: ".$find->set_number;
    say "no_records: ".$find->no_records;
    say "no_entries: ".$find->no_entries;
  }else{
    say STDERR $find->error;
  }

=head3 remarks

  This method is equivalent to 'op' = 'find'

=head3 arguments

  request - search request
  adjacent - if 'Y' then the documents should contain all the search words adjacent to each other, otherwise 'N'
=cut
sub find {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::Find;
  $args{'op'} = Catmandu::AlephX::Op::Find->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::Find->parse($res->content_ref());    
}

=head2 find_doc

=head3 documentation from AlephX
  
  This service retrieves the OAI XML format of an expanded document as given by the user.

=head3 example

  my $find = $aleph->find_doc(base=>'rug01',doc_num=>'000000444',format=>'marc');
  if($find->is_success){
    for my $record(@{ $find->records }){
      say Dumper($record);
    }
  }else{
    say STDERR $find->error;
  }

=head3 remarks

  This method is equivalent to 'op' = 'find-doc'

=cut
sub find_doc {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::FindDoc;
  $args{'op'} = Catmandu::AlephX::Op::FindDoc->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::FindDoc->parse($res->content_ref());    
}

=head2 present

=head3 documentation from Aleph X

  This service retrieves OAI XML format of expanded documents.
  You can view documents according to the locations within a specific set number.

=head3 example

  my $set_number = $aleph->find(request => "wrd=(BIB.AFF)",base => "rug01")->set_number;
  my $present = $aleph->present(
    set_number => $set_number,
    set_entry => "000000001-000000003"
  );
  if($present->is_success){
    say "doc_number: ".$record->{doc_number};
    for my $metadata(@{ $record->metadata }){
      say "\tmetadata: ".$metadata->type;
    }
  }else{
    say STDERR $present->error;
  }

=head3 remarks

  This method is equivalent to 'op' = 'present'

=cut
sub present {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::Present;
  $args{'op'} = Catmandu::AlephX::Op::Present->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::Present->parse($res->content_ref());    
}

=head2 ill_get_doc_short

=head3 documentation from Aleph X

  The service retrieves the doc number and the XML of the short document (Z13).

=head3 example

  my $result = $aleph->ill_get_doc_short(doc_number => "000000001",library=>"usm01");
  if($result->is_success){
    for my $z30(@{ $result->z13 }){
      print Dumper($z30);
    }
  }else{
    say STDERR $result->error;
  }

=head3 remarks

  This method is equivalent to 'op' = 'ill-get-doc-short'

=cut
sub ill_get_doc_short {
  my($self,%args)=@_; 
  require Catmandu::AlephX::Op::IllGetDocShort;
  $args{'op'} = Catmandu::AlephX::Op::IllGetDocShort->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::IllGetDocShort->parse($res->content_ref());    
}
=head2 bor_auth

=head3 documentation from Aleph X

  This service retrieves the Global record (Z303), Local record (Z305) and the Data record (Z304) for a given Patron if the given ID and verification code match.
  Otherwise, an error message is returned.

=head3 example

  my %args = (
    library => $library,
    bor_id => $bor_id,
    verification => $verification
  );
  my $auth = $aleph->bor_auth(%args);

  if($auth->is_success){

    for my $type(qw(z303 z304 z305)){
      say "$type:";
      my $data = $auth->$type();
      for my $key(keys %$data){
        say "\t$key : $data->{$key}->[0]";
      }
    }

  }else{
    say STDERR "error: ".$auth->error;
    exit 1;
  }

=cut
sub bor_auth {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::BorAuth;
  $args{'op'} = Catmandu::AlephX::Op::BorAuth->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::BorAuth->parse($res->content_ref());
} 
=head2 bor_info

=head3 documentation from Aleph X

  This service retrieves all information related to a given Patron: Global and Local records, Loan records, Loaned items records, Short doc record, Cash record, and so on, if the ID and verification code provided match.

  If not, an error message is returned. Since the bor-info X-Service retrieves a very large amount of data, and not all of it may be relevant, you can choose to receive a part of the data, based on your needs.

=head3 example
    
  my %args = (
    library => $library,
    bor_id => $bor_id,
    verification => $verification,
    loans => 'P'
  );
  my $info = $aleph->bor_info(%args);

  if($info->is_success){

    for my $type(qw(z303 z304 z305)){
      say "$type:";
      my $data = $info->$type();
      for my $key(keys %$data){
        say "\t$key : $data->{$key}->[0]";
      }
    }
    say "fine:";
    for my $fine(@{ $info->fine() }){
      for my $type(qw(z13 z30 z31)){
        say "\t$type:";
        my $data = $fine->{$type}->[0];
        for my $key(keys %$data){
          say "\t\t$key : $data->{$key}->[0]";
        }
      }
    }

  }else{
    say STDERR "error: ".$info->error;
    exit 1;
  }

=cut
sub bor_info {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::BorInfo;
  $args{'op'} = Catmandu::AlephX::Op::BorInfo->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::BorInfo->parse($res->content_ref());
}

=head2 ill_bor_info

=head3 documentation from Aleph X

  This service retrieves Z303, Z304, Z305 and Z308 records for a given borrower ID / barcode.

=head3 example

=cut
sub ill_bor_info {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::IllBorInfo;
  $args{'op'} = Catmandu::AlephX::Op::IllBorInfo->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::IllBorInfo->parse($res->content_ref());
}

sub ill_loan_info {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::IllLoanInfo;
  $args{'op'} = Catmandu::AlephX::Op::IllLoanInfo->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::IllLoanInfo->parse($res->content_ref());
}
=head2 circ_status

=head3 documentation from Aleph X

The service retrieves the circulation status for each document number entered by the user.

  Item information (From Z30).
  Loan information (from Z36).
  Loan Status (Tab15), Due Date, Due Hour etc.

=head3 example

=cut
sub circ_status {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::CircStatus;
  $args{'op'} = Catmandu::AlephX::Op::CircStatus->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::CircStatus->parse($res->content_ref());
}
=head2 circ_stat_m

=head3 documentation from Aleph X

The service retrieves the circulation status for each document number entered by the user (suitable for documents with more than 1000 items).

  Item information (From Z30).
  Loan information (from Z36).
  Loan Status (Tab15), Due Date, Due Hour etc.

This service is similar to circ-status X-service, except for the parameter START_POINT which enables to retrieve information for documents with more than 1000 items.

=head3 example

=cut
sub circ_stat_m {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::CircStatM;
  $args{'op'} = Catmandu::AlephX::Op::CircStatM->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::CircStatM->parse($res->content_ref());
}
=head2 publish_avail

=head3 documentation from Aleph X

This service supplies the current availability status of a document.

The X-Server does not change any data.  

=head3 example

my $publish = $aleph->publish_avail(doc_num => '000196220,001313162,001484478,001484538,001317121,000000000',library=>'rug01');
if($publish->is_success){

  #format for $publish->list() : [ [<id>,<marc-array>], .. ]

  for my $item(@{ $publish->list }){

    say "id: $item->[0]";
    if($item->[1]){
      say "marc array:";
      say Dumper($item->[1]);
    }else{
      say "nothing for $item->[0]";
    }

    say "\n---";
  }
}else{
  say STDERR $publish->error;
}

=head3 remarks

  The parameter 'doc_num' supports multiple values, separated by ','.
  Compare this to ill_get_doc, that does not support this.

=cut
sub publish_avail {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::PublishAvail;
  $args{'op'} = Catmandu::AlephX::Op::PublishAvail->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::PublishAvail->parse($res->content_ref());
}
=head2 ill_get_doc

=head3 documentation from Aleph X

This service takes a document number and the library where the corresponding document is located and generates the XML of the requested document as it appears in the library given.

=head3 example

my $illgetdoc = $aleph->ill_get_doc(doc_number => '001317121',library=>'rug01');
if($illgetdoc->is_success){

  if($illgetdoc->record){
    say "data: ".to_json($illgetdoc->record,{ pretty => 1 });
  }
  else{
    say "nothing found";
  }

}else{
  say STDERR $illgetdoc->error;
}

=cut
sub ill_get_doc {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::IllGetDoc;
  $args{'op'} = Catmandu::AlephX::Op::IllGetDoc->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::IllGetDoc->parse($res->content_ref());
}
=head2 renew

=head3 documentation from Aleph X

  This service renews the loan of a given item for a given patron.
  The X-Service renews the loan only if it can be done. If, for example, there is a delinquency on the patron, the service does not renew the loan.

=head3 example

=cut
sub renew {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::Renew;
  $args{'op'} = Catmandu::AlephX::Op::Renew->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::Renew->parse($res->content_ref());
}
=head2 hold_req

=head3 documentation from Aleph X

The service creates a hold-request record (Z37) for a given item after performing initial checks.

=head3 example

=cut
sub hold_req {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::HoldReq;
  $args{'op'} = Catmandu::AlephX::Op::HoldReq->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::HoldReq->parse($res->content_ref());
}
sub hold_req_cancel {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::HoldReqCancel;
  $args{'op'} = Catmandu::AlephX::Op::HoldReqCancel->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::HoldReqCancel->parse($res->content_ref());
}
sub user_auth {
  my($self,%args)=@_;
  require Catmandu::AlephX::Op::UserAuth;
  $args{op} = Catmandu::AlephX::Op::UserAuth->op();
  my $res = $self->_do_web_request(\%args);
  Catmandu::AlephX::Op::UserAuth->parse($res->content_ref());
}

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
1;

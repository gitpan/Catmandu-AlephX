#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use JSON qw(to_json);
use open qw(:std :utf8);
use Catmandu::Exporter::MARC;

my $aleph = Catmandu::AlephX->new(url => "http://aleph.ugent.be/X");

my $exporter = Catmandu::Exporter::MARC->new(type => 'XML');

my $publish = $aleph->publish_avail(doc_num => '000196220,001313162,001484478,001484538,001317121,000000000',library=>'rug01');
if($publish->is_success){

  for my $item(@{ $publish->list }){

    say "id: '$item->{_id}'";
    if($item->{record}){
      say "data: \n".to_json($item->{record},{ pretty => 0 });
      say "xml:";
      $exporter->add({ record => $item->{record} });
      $exporter->commit;
    }
    else{
      say "nothing for $item->{_id}";
    }

    say "\n---";
  }
}else{
  say STDERR $publish->error;
} 

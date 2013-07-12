package Catmandu::AlephX::Op::IllBorInfo;
use Catmandu::Sane;
use Data::Util qw(:check :validate);
use Moo;

extends('Catmandu::AlephX::Op::BorAuth');
with('Catmandu::AlephX::Response');

has z308 => (
  is => 'ro',
  lazy => 1,
  isa => sub {
    array_ref($_[0]);
  },
  default => sub {
    [];
  }
);

sub op { 'ill-bor-info' } 

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my @keys = qw(z303 z304 z305 z308);
  my %args = ();

  for my $key(@keys){
    my($l) = $xpath->find("/ill-bor-info/$key")->get_nodelist();
    my $data = $l ? get_children($l,1) : {};
    $args{$key} = $data;
  }

  __PACKAGE__->new(
    %args,
    session_id => $xpath->findvalue('/ill-bor-info/session-id'),
    error => $xpath->findvalue('/ill-bor-info/error')
  );
  
}

1;

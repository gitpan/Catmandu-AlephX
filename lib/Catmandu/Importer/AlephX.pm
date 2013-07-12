package Catmandu::Importer::AlephX;

use Catmandu::Sane;
use Moo;
use Catmandu::AlephX;
use Data::Dumper;

with 'Catmandu::Importer';

our $VERSION = '0.02';

has url     => (is => 'ro', required => 1);
has base    => (is => 'ro', required => 1);
has query   => (is => 'ro', required => 1);
has aleph   => (is => 'ro', init_arg => undef , lazy => 1 , builder => '_build_aleph');

sub _build_aleph {
  my ($self) = @_;
  Catmandu::AlephX->new(url => $self->url);
}

sub _fetch_items {
  my ($self, $doc_number) = @_;
  my $item_data = $self->aleph->item_data(base => $self->base, doc_number => $doc_number);
  
  return [] unless $item_data->is_success;
  return $item_data->items;
}

sub generator {
  my ($self) = @_;
  my $find    = $self->aleph->find(request => $self->query , base => $self->base);
  
  return sub {undef} unless $find->is_success;    
  
  sub {
    state $set_number = $find->set_number;
    state $no_records = int($find->no_records);
    state $count = 0;

    return if ($no_records == 0 || $count >= $no_records );
    my $present = $self->aleph->present(set_number => $set_number , set_entry => sprintf("%-9.9d",++$count));
    return unless $present->is_success;
    return unless @{$present->records} == 1;
 
    my $doc   = $present->records->[0];
    my $items = $self->_fetch_items($doc->{doc_number});
    
    { record => $doc->metadata->[0]->data , items => $items };
  };
}

=head1 NAME

Catmandu::Importer::AlephX - Package that imports metadata records from the AlephX service

=head1 SYNOPSIS

    use Catmandu::Importer::AlephX;

    my $importer = Catmandu::Importer::AlephX->new(
                        url => 'http://ram19:8995/X' ,
                        query => 'WRD=(art)' ,
                        base => 'usm01' ,
                        );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new(url => '...' , base => '...' , query => '...')

Create a new AlephX importer. Required parameters are the url baseUrl of the AlephX service, an Aleph 'base' catalog name and a 'query'.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::AlephX methods are not idempotent: Twitter feeds can only be read once.

=head1 AUTHOR

Patrick Hochstenbach C<< patrick dot hochstenbach at ugent dot be >>

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;

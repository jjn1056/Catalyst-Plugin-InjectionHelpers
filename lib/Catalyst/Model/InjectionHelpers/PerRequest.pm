package Catalyst::Model::InjectionHelpers::PerRequest;

use Moose;
use Scalar::Util qw/blessed refaddr/;

with 'Catalyst::ModelRole::InjectionHelpers'; 

sub ACCEPT_CONTEXT {
  my ($self, $c, %args) = @_;
  return $self->build_new_instance($c, %args) unless blessed $c;
  my $key = blessed $self ? refaddr $self : $self;
  return $c->stash->{"__InstancePerContext_${key}"} ||= 
    $self->build_new_instance($c, %args);
}

__PACKAGE__->meta->make_immutable;

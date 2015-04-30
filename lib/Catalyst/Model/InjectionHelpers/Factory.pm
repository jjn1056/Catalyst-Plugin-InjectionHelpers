package Catalyst::Model::InjectionHelpers::Factory;

use Moose;
with 'Catalyst::ModelRole::InjectionHelpers'; 

sub ACCEPT_CONTEXT {
  my ($self, $c, %args) = @_;
  return $self->build_new_instance($c, %args);
}

__PACKAGE__->meta->make_immutable;

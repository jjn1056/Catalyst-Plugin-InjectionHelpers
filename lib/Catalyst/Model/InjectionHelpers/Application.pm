package Catalyst::Model::InjectionHelpers::Application;

use Moose;
with 'Catalyst::ModelRole::InjectionHelpers'; 

has instance => (
  is=>'ro',
  isa=>'Object',
  init_arg=>undef,
  lazy=>1,
  required=>1,
  default=>sub {$_[0]->build_new_instance($_[0]->application)} );

sub ACCEPT_CONTEXT {
  my ($self, $c, %args) = @_;
  return $self->instance;
}

__PACKAGE__->meta->make_immutable;

package Catalyst::ModelRole::InjectionHelpers;

use Moose::Role;
use Moose::Util;
requires 'ACCEPT_CONTEXT';

has application => (is=>'ro', required=>1);
has from_class => (is=>'ro', isa=>'ClassName', required=>1);
has method => (is=>'ro', required=>1, default=>'new');
has injected_component_name => (is=>'ro', isa=>'Str', required=>1);
has injection_parameters => (is=>'ro', isa=>'HashRef', required=>1);
has config => (is=>'ro', isa=>'HashRef', required=>1, default=>sub { +{} });
has roles => (is=>'ro', isa=>'ArrayRef', required=>1, default=>sub { +[] });
has composed_class => (
  is=>'ro',
  init_arg=>undef,
  required=>1,
  lazy=>1,
  default=>sub { Moose::Util::with_traits($_[0]->from_class, @{$_[0]->roles}) });

sub build_new_instance {
  my ($self, $app_or_c, %args) = @_;
  my %merged_args = (%{$self->config}, %args);
  my $method = $self->method;
  my $composed_class = $self->composed_class;

  if((ref($method)||'') eq 'CODE') {
    return $self->$method($composed_class, $app_or_c, %merged_args)

  } else {
    return $composed_class->$method(%merged_args);
  }
}

1;

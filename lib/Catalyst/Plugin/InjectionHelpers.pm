package Catalyst::Plugin::InjectionHelpers;

use Moose::Role;
use Class::Load;
use Catalyst::Utils;

requires 'setup_injected_component';

my $singleton = sub {
  my ($app, $injected_component_name, $target_class, $method, @roles) = @_;
  my $roles = join ',', map { "'$_'"} @roles;
  my $package = <<END_SCRIPT;

package $app::$injected_component_name;
use Moose;
use Moose::Util;
use $target_class;
extends 'Catalyst::Model';

sub COMPONENT {
  my (\$class, \$app, \$args) = \@_;
  \$args = \$class->merge_config_hashes(\$class->config, \$args);
  my \$composed = Moose::Util::with_traits('$target_class', ($roles));
  return \$composed->$method(\$args);
}

__PACKAGE__->meta->make_immutable;


END_SCRIPT

  warn $package;
  
  eval $package || die "Can't build class: $@";
};

after 'setup_injected_component', sub {
  my ($app, $injected_component_name, $config) = @_;
  if(exists $config->{from_class}) {
    my $target_class = $config->{from_class};
    my $adaptor = $config->{adaptor} || 'Singleton';
    my $method = $config->{method} || 'new';
    my @roles = @{$config->{roles} ||[]};

    use Devel::Dwarn;
    Dwarn \@roles;
    Dwarn (scalar(@roles));

    $singleton->($app, $injected_component_name, $target_class, $method, @roles);

    Catalyst::Utils::inject_component(
      into => $app,
      component => "$app::$injected_component_name",
      as => $injected_component_name);

  }
};

1;

=head1 NAME

    $self->components
    
Catalyst::Plugin::InjectionHelpers - Enhance Catalyst Component Injection

=head1 SYNOPSIS

Use the plugin in your application class:

    package MyApp;
    use Catalyst 'InjectionHelpers';

    MyApp->setup;

Then you can use it in your controllers:

    package MyApp::Controller::Example;

    use base 'Catalyst::Controller';

=head1 DESCRIPTION

This plugin enhances the build in component injection features of L<Catalyst>
(since v5.90090) to make it easy to bring non L<Catalyst::Component> classes
into your application.  You may consider using this for what you often used
L<Catalyst::Model::Adaptor> in the past for (although there is no reason to
stop using that if you are doing so, its not a 'broken' approach, but for the
very simple cases this might suffice and allow you to reduce the number of nearly
empty 'boilerplate' classes in your application.

=head1 METHODS

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Response>

=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut

package Catalyst::Plugin::InjectionHelpers;

use Moose::Role;
use Class::Load;
use Catalyst::Utils;
use Catalyst::Model::InjectionHelpers::Application;

requires 'setup_injected_component';

my $adaptor_namespace = sub {
  my $app = shift;
  if(my $config = $app->config->{'Plugin::InjectionHelpers'}) {
    my $namespace = $config->{adaptor_namespace};
    return $namespace if $namespace;
  }
  return 'Catalyst::Model::InjectionHelpers';
};

my $default_adaptor = sub {
  my $app = shift;
  if(my $config = $app->config->{'Plugin::InjectionHelpers'}) {
    my $default_adaptor = $config->{default_adaptor};
    return $default_adaptor if $default_adaptor;
  }
  return 'Application';
};

my $normalize_adaptor = sub {
  my $app = shift;
  my $adaptor = shift || $app->default_adaptor;
  return $adaptor=~m/::/ ? 
    $adaptor : "${\$app->$adaptor_namespace}::$adaptor";
};

after 'setup_injected_component', sub {
  my ($app, $injected_component_name, $config) = @_;
  if(exists $config->{from_class}) {
    my $from_class = $config->{from_class};
    my $adaptor = $app->$normalize_adaptor($config->{adaptor});
    my $method = $config->{method} || 'new';
    my @roles = @{$config->{roles} ||[]};

    Catalyst::Utils::ensure_class_loaded($from_class);
    Catalyst::Utils::ensure_class_loaded($adaptor);

    $app->components->{ "$app::$injected_component_name" } = sub { 
      $adaptor->new(
        application=>$app,
        from_class=>$from_class,
        injected_component_name=>$injected_component_name,
        method=>$method,
        roles=>\@roles,
        injection_parameters=>$config,
        config=> ($app->config->{$injected_component_name} || +{}),
      ) };
  }
};

1;

=head1 NAME

Catalyst::Plugin::InjectionHelpers - Enhance Catalyst Component Injection

=head1 SYNOPSIS

Use the plugin in your application class:

    package MyApp;
    use Catalyst 'InjectionHelpers';

    MyApp->inject_components(
      'Model::SingletonA' => {
        from_class=>'MyApp::Singleton', 
        adaptor=>'Application', 
        roles=>['MyApp::Role::Foo'],
        method=>'new',
      },
      'Model::SingletonB' => {
        from_class=>'MyApp::Singleton', 
        adaptor=>'Application', 
        method=>sub {
          my ($adaptor_instance, $from_class, $app, %args) = @_;
          return $class->new(aaa=>$args{arg});
        },
      },
    );

    MyApp->config(
      'Model::SingletonA' => { aaa=>100 },
      'Model::SingletonB' => { arg=>300 },
    );

    MyApp->setup;

=head1 DESCRIPTION

This plugin enhances the build in component injection features of L<Catalyst>
(since v5.90090) to make it easy to bring non L<Catalyst::Component> classes
into your application.  You may consider using this for what you often used
L<Catalyst::Model::Adaptor> in the past for (although there is no reason to
stop using that if you are doing so, its not a 'broken' approach, but for the
very simple cases this might suffice and allow you to reduce the number of nearly
empty 'boilerplate' classes in your application.

You should be familiar with how component injection works in newer versions of
L<Catalyst> (v5.90090+).

=head1 USAGE

    MyApp->inject_components($model_name => \%args);

Where C<$model_name> is the name of the component as it is in your L<Catalyst>
application (ie 'Model::User', 'View::HTML', 'Controller::Static') and C<%args>
are key /values as described below:

=head2 from_class

This is the full namespace of the class you are adapting to use as a L<Catalyst>
component.

=head2 roles

A list of L<Moose::Roles>s that will be composed into the 'from_class' prior
to creating an instance of that class.

=head2 method

Either a string or a coderef. If left empty this defaults to 'new'.

The name of the method used to create the adapted class instance.  Generally this
is 'new'.  If you have complex instantiation requirements you may instead use
a coderef. If so, your coderef will receive four arguments.   The first is the
adaptor instance.  The second is the name of the from_class.  The third is either
the application or context, depending on the type adaptor.  The forth is a hash
of arguments which merges the global configuration for the named component along
with any arguments passed in the request for the component (this only makes
sense for non application scoped models, btw).

=head2 adaptor

The adaptor used to bring your 'from_class' into L<Catalyst>.  Out of the box
there are three adaptors (described in detail below): Application, Factory and
PerRequest.  The default is Application.  You may create your own adaptors; if
you do so you should use the full namespace as the value (MyApp::Adaptors::MySpecialAdaptor).

=head1 ADAPTORS

Out of the box this plugin comes with the following three adaptors. All canonical
adaptors are under the namespace 'Catalyst::Model::InjectionHelpers'.

=head2 Application

Model is application scoped.  This means you get one instance shared for the entire
lifecycle of the application.

=head2 Factory

Model is scoped to the request. Each call to $c->model($model_name) returns a new
instance of the model.  You may pass additional parameters in the model call,
which are merged to the global parameters defined in configuration and used as
part of the object initialization.

=head2 PerRequest

Model is scoped to the request. The first time in a request that you call for the
model, a new model is created.  After that, all calls to the model return the original
instance, until the request is completed, after which the instance is destroyed when
the request goes out of scope.

The first time you call this model you may pass additional parameters, which get
merged with the global configuration and used to initialize the model.

=head1 Creating your own adaptor

Your new adaptor should consume the role L<Catalyst::ModelRole::InjectionHelpers>
and provide a method ACCEPT_CONTEXT which must return the component you wish to
inject.  Please review the existing adaptors and that role for insights.

=head1 CONFIGURATION

This plugin defines the following possible configuration.  As per L<Catalyst>
standards, these configuration keys fall under the 'Plugin::InjectionHelpers'
namespace in the configuration hash.

=head2 adaptor_namespace

Default namespace to look for adaptors.  Defaults to L<Catalyst::Model::InjectionHelpers>

=head2 default_adaptor

The default adaptor to use, should you not set one.  Defaults to 'Application'.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Response>

=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut

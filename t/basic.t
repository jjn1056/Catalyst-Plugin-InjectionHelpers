use Test::Most;

BEGIN {
  package MyApp::Role::Foo;
  $INC{'MyApp/Role/Foo.pm'} = __FILE__;

  use Moose::Role;

  sub foo { 'foo' }

  package MyApp::Singleton;
  $INC{'MyApp/Singleton.pm'} = __FILE__;

  use Moose;

  has aaa => (is=>'ro', required=>1);
}

{
  package MyApp::Model::Normal;
  $INC{'MyApp/Model/Normal.pm'} = __FILE__;

  use Moose;
  extends 'Catalyst::Model';

  has ccc => (is=>'ro', required=>1);

  package MyApp::Controller::Example;
  $INC{'MyApp/Controller/Example.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub test :Local Args(0) {
    my ($self, $c) = @_;
    $c->res->body('test');
  }

  package MyApp;
  use Catalyst 'InjectionHelpers';

  MyApp->inject_components(
    'Model::Singleton' => { from_class=>'MyApp::Singleton', adaptor=>'Singleton', roles=>['MyApp::Role::Foo'], method=>'new' },
  );

  MyApp->config(
    'Model::Singleton' => { aaa=>100 },
    'Model::Normal' => { ccc=>200 },
  );

  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request( '/example/test' );
  is $c->model('Normal')->ccc, 200;
  is $c->model('Singleton')->aaa, 100;

  use Devel::Dwarn;
  Dwarn $c->model('Singleton');

  is $c->model('Singleton')->foo, 'foo';
}

done_testing;

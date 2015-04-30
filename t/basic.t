use Test::Most;
use Scalar::Util qw/refaddr/;

BEGIN {
  package MyApp::Role::Foo;
  $INC{'MyApp/Role/Foo.pm'} = __FILE__;

  use Moose::Role;

  sub foo { 'foo' }

  package MyApp::Singleton;
  $INC{'MyApp/Singleton.pm'} = __FILE__;

  use Moose;

  has aaa => (is=>'ro', required=>1);
  has bbb => (is=>'ro');
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
    'Model::SingletonA' => { from_class=>'MyApp::Singleton', adaptor=>'Application', roles=>['MyApp::Role::Foo'], method=>'new' },
    'Model::SingletonB' => {
      from_class=>'MyApp::Singleton', 
      adaptor=>'Application', 
      roles=>['MyApp::Role::Foo'], 
      method=>sub {
        my ($adaptor, $class, $app, %args) = @_;
        return $class->new(aaa=>$args{arg});
      },
    },
    'Model::Factory' => { from_class=>'MyApp::Singleton', adaptor=>'Factory' },
    'Model::PerRequest' => { from_class=>'MyApp::Singleton', adaptor=>'PerRequest' },

  );

  MyApp->config(
    'Model::SingletonA' => { aaa=>100 },
    'Model::SingletonB' => { arg=>300 },
    'Model::Factory' => {aaa=>444},
    'Model::Normal' => { ccc=>200 },
  );

  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  my ($res, $c) = ctx_request( '/example/test' );
  is $c->model('Normal')->ccc, 200;
  is $c->model('SingletonA')->aaa, 100;
  is $c->model('SingletonA')->foo, 'foo';
  is $c->model('SingletonB')->aaa, 300;
  is $c->model('SingletonB')->foo, 'foo';
  is refaddr($c->model('SingletonB')), refaddr($c->model('SingletonB'));

  {
    ok my $f = $c->model('Factory', bbb=>'bbb');
    is $f->aaa, 444;
    is $f->bbb, 'bbb';
    isnt refaddr($f), refaddr($c->model('Factory'));
    isnt refaddr($c->model('Factory')), refaddr($c->model('Factory'));
  }

  {
    ok my $p = $c->model('PerRequest', aaa=>1, bbb=>2);
    is $p->aaa, 1;
    is $p->bbb, 2;
    is refaddr($p), refaddr($c->model('PerRequest'));

    {
      my ($res, $c) = ctx_request( '/example/test' );
      ok my $p2 = $c->model('PerRequest', aaa=>3, bbb=>4);
      is $p2->aaa, 3;
      is $p2->bbb, 4;
      is refaddr($p2), refaddr($c->model('PerRequest'));
      isnt refaddr($p), refaddr($c->model('PerRequest'));
      isnt refaddr($p), refaddr($p2);
    }
  }
}

done_testing;

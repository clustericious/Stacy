use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More;
use Path::Class qw( dir );

$ENV{SIPSROOT} = dir( qw( corpus sipsroot1 ))->absolute->stringify;
note "SIPSROOT = $ENV{SIPSROOT}";

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Stacy ));

my $t = $cluster->t;

subtest redirect => sub {
  $t->get_ok("/f101/something")
    ->status_is(302);
  my $location = Mojo::URL->new($t->tx->res->headers->location);  
  is $location->path, "/f101/something/", "location path = /f101/something/";
};

subtest listing => sub {
  $t->get_ok("/f101/something/")
    ->status_is(200);

  note $t->tx->res->body;
  my @lines = split /\n/, $t->tx->res->body;
  
  like $lines[0], qr{^dr-x [0-9]+ [0-9]+ [0-9]+ \.$}, "first line current directory (.)";
  like $lines[1], qr{^dr-x [0-9]+ [0-9]+ [0-9]+ \.\.$}, "second line parent directory (..)";
  like $lines[2], qr{^dr-x [0-9]+ [0-9]+ [0-9]+ bar$}, "third line bar/";
  like $lines[3], qr{^-r-- [0-9]+ 20 [0-9]+ foo.txt$}, "forth line foo.txt";
  is   $lines[4], undef, 'exactly the right number of lines';
};

subtest file => sub {
  $t->get_ok('/f101/something/foo.txt')
    ->status_is(404);
};

subtest bogus => sub {
  $t->get_ok('/f101/something/bogus.txt')
    ->status_is(404);
};

subtest "parent hack" => sub {
  foreach my $path (qw( /f101/something/../ /f101/something/.. /f101/something/./ /f101/something/. /f101/something/.../ /f101/something/... ))
  {
    $t->get_ok($path)
      ->status_is(403);
  }
};

done_testing;

__DATA__

@@ etc/Stacy.conf
---
url: <%= cluster->url %>

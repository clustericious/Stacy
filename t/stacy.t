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

  subtest main => sub {
    $t->get_ok("/f403/failed/NMAERUV/17083998")
      ->status_is(301);
    my $location = $t->tx->res->headers->location;
    is $location, "/f403/failed/NMAERUV/17083998/", "location path = /f403/failed/NMAERUV/17083998/";
  };

  subtest sub => sub {
    $t->get_ok("/f403/failed/NMAERUV/17083998/bar")
      ->status_is(301);
    my $location = $t->tx->res->headers->location;
    is $location, "/f403/failed/NMAERUV/17083998/bar/", "location path = /f403/failed/NMAERUV/17083998/bar/";
  };
};

subtest 'main listing' => sub {
  $t->get_ok("/f403/failed/NMAERUV/17083998/")
    ->status_is(200);

  note $t->tx->res->body;
  my @lines = split /\n/, $t->tx->res->body;
  
  like $lines[0], qr{^dr-x [0-9]+ [0-9]+ [0-9]+ \.$}, "first line current directory (.)";
  like $lines[1], qr{^dr-x [0-9]+ [0-9]+ [0-9]+ \.\.$}, "second line parent directory (..)";
  like $lines[2], qr{^dr-x [0-9]+ [0-9]+ [0-9]+ bar$}, "third line bar/";
  like $lines[3], qr{^-r-- [0-9]+ 20 [0-9]+ foo.txt$}, "forth line foo.txt";
  is   $lines[4], undef, 'exactly the right number of lines';
};

subtest 'subdirectory listing' => sub {
  $t->get_ok("/f403/failed/NMAERUV/17083998/bar/")
    ->status_is(200);
  
  note $t->tx->res->body;
  
  my @lines = split /\n/, $t->tx->res->body;

  like $lines[0], qr{^dr-x [0-9]+ [0-9]+ [0-9]+ \.$}, "first line current directory (.)";
  like $lines[1], qr{^dr-x [0-9]+ [0-9]+ [0-9]+ \.\.$}, "second line parent directory (..)";
  like $lines[2], qr{^-r-- [0-9]+ 27 [0-9]+ baz.txt$}, "forth line baz.txt";
  is   $lines[3], undef, 'exactly the right number of lines';
  
};

subtest file => sub {
  $t->get_ok('/f403/failed/NMAERUV/17083998/foo.txt')
    ->status_is(200)
    ->content_is("this is a text file\n");
};

subtest bogus => sub {
  $t->get_ok('/f403/failed/NMAERUV/17083998/bogus.txt')
    ->status_is(404);
};

subtest "parent hack" => sub {
  foreach my $path (qw( /f403/failed/NMAERUV/17083998/../ /f403/failed/NMAERUV/17083998/.. /f403/failed/NMAERUV/17083998/./ /f403/failed/NMAERUV/17083998/. /f403/failed/NMAERUV/17083998/.../ /f403/failed/NMAERUV/17083998/... ))
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

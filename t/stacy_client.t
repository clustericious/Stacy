use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More;
use Path::Class qw( dir );
use Stacy::Client;

$ENV{SIPSROOT} = dir( qw( corpus sipsroot1 ))->absolute->stringify;
note "SIPSROOT = $ENV{SIPSROOT}";

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Stacy ));

my $client = Stacy::Client->new;

subtest status => sub {

  my $status = $client->status;
  ok $status, 'result ok';
  is $status->{app_name}, 'Stacy', 'app_name';
  is $status->{server_version}, Stacy->VERSION // 'dev', 'server_version';
  ok $status->{server_url}, "server_url = @{[ $status->{server_url} ]}";
  ok $status->{server_hostname}, "server_hostname = @{[ $status->{server_hostname} ]}";

};

done_testing;

__DATA__

@@ etc/Stacy.conf
---
url: <%= cluster->url %>

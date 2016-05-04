package Stacy;

use strict;
use warnings;
use base qw( Clustericious::App );
use Clustericious::Log;
use Path::Class::Dir;

# ABSTRACT: Service static listing for files
# VERSION

sub startup
{
  my $self = shift;
  $self->SUPER::startup(@_);
  $self->secrets([rand]);

  unless(defined $ENV{SIPSROOT})
  {
    WARN "SIPSROOT is not defined";
    return;
  }

  my $archive = Path::Class::Dir->new($ENV{SIPSROOT})->subdir('archive');
  foreach my $root ($archive->children)
  {
    next unless $root->basename =~ /^f[0-9]+$/;
    $self->routes->get("/@{[ $root->basename ]}/*x" => sub {
      my($c) = @_;

      my $dir = $archive->subdir($c->req->url->path);
      return $c->reply->not_found unless -d $dir;

      $c->res->headers->content_type('text/plain');
      $c->render(
        text => join("\n",
          map {
            my $stat = $_->stat;
            my $mode = $stat->[2];
            join ' ',
              ($_->is_dir ? 'd' : '-') . ($mode & 04 ? 'r' : '-') . ($mode & 02 ? 'w' : '-') . ($mode & 01 ? 'x' : '-'),
              $stat->[3],
              $stat->[7],
              $stat->[9],
              "$_"
          } $dir->children) . "\n",
        code => 200,
      );

    });
  }

}

1;

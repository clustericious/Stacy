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
    $self->routes->get("/@{[ $root->basename ]}/failed/:pge/:pgeid/*x" => [ pgeid => qr/[0-9]+/ ] => { x => '' } => sub {
      my($c) = @_;

      my $url_path = $c->req->url->path;;
      my $dist_path = $url_path->clone;
      return $c->render( text => '403 Forbidden', status => 403 )
        if grep /^\.{1,3}$/, @{ $dist_path->parts };

      $dist_path->parts->[2] =~ s/^/PGE_/;
      
      my $dir = $archive->subdir($dist_path);
      return $c->reply->not_found unless -d $dir;
      return $c->redirect_to("$url_path/") unless $dist_path->trailing_slash;

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
              $_->basename
          } sort { $a->basename cmp $b->basename } $dir->children(all => 1)),
        status => 200,
      );

    } => 'failed_index');
  }

}

1;

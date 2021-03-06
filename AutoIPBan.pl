# A plugin for automatically adding evil hosts to IPBanList based on MT throttling mechanism.
#
# $Id$
#
# This software is provided as-is. You may use it for commercial or 
# personal use. If you distribute it, please keep this notice intact.
#
# Copyright (c) 2006 Hirotaka Ogawa
#
package MT::Plugin::AutoIPBan;

use strict;
use MT;
use MT::Template::Context;
use base 'MT::Plugin';

use vars qw($VERSION);

sub BEGIN {
    $VERSION = 0.02;
    my $plugin = __PACKAGE__->new({
	name => 'AutoIPBan',
	description => 'This plugin enables MT to add evil hosts into IPBanList based on OneHourMaxPings and OneDayMaxPings',
	doc_link => 'http://as-is.net/wiki/AutoIPBan_Plugin',
	author_name => 'Hirotaka Ogawa',
	author_link => 'http://profile.typekey.com/ogawa/',
	version => $VERSION
	});
    MT->add_plugin($plugin);
    MT->add_callback('TBPingThrottleFilter', 1, $plugin, \&tbping_auto_ipban);
    MT::Template::Context->add_container_tag(IPBanList => \&ipbanlist);
    MT::Template::Context->add_tag(IPBanListIP => \&ipbanlist_ip);
}

sub init_app {
    my ($plugin, $app) = @_;
    return unless $app->isa('MT::App::CMS');
    $app->add_itemset_action({
	type => 'ping',
	key => 'add_to_ipbanlist_ping',
	label => 'Add To IPBanList',
	code => \&add_to_ipbanlist_ping
	});
    $app->add_itemset_action({
	type => 'comment',
	key => 'add_to_ipbanlist_comment',
	label => 'Add To IPBanList',
	code => \&add_to_ipbanlist_comment
	});
}

use MT::Util qw(offset_time_list);
use MT::TBPing;
use MT::IPBanList;

sub tbping_auto_ipban {
    my ($eh, $app, $tbping) = @_;
    my $ip = $app->remote_ip;
    my $blog_id = $tbping->blog_id;
    my $now = time;

    my @ts = offset_time_list($now - 3600, $blog_id);
    my $from = sprintf("%04d%02d%02d%02d%02d%02d",
		       $ts[5]+1900, $ts[4]+1, @ts[3,2,1,0]);
    my $count = MT::TBPing->count({ blog_id => $blog_id,
				    ip => $ip,
				    created_on => [$from] },
				  { range => { created_on => 1 } });
    if ($count >= $app->config('OneHourMaxPings')) {
	_add_to_ipbanlist($blog_id, $ip);
	return 0;
    }

    @ts = offset_time_list($now - 86400, $blog_id);
    $from = sprintf("%04d%02d%02d%02d%02d%02d",
		    $ts[5]+1900, $ts[4]+1, @ts[3,2,1,0]);
    $count = MT::TBPing->count({ blog_id => $blog_id,
				 ip => $ip,
				 created_on => [$from] },
			       { range => { created_on => 1 } });
    if ($count >= $app->config('OneDayMaxPings')) {
	_add_to_ipbanlist($blog_id, $ip);
        return 0;
    }
    1;
}

sub add_to_ipbanlist_ping {
    my ($app) = @_;
    my @ids = $app->param('id')
	or return $app->error("Need pings to add to IPBanList");
    for my $id (@ids) {
	my $ping = MT::TBPing->load($id, { cache_ok => 1 });
	_add_to_ipbanlist($ping->blog_id, $ping->ip);
    }
    $app->call_return;
}

sub add_to_ipbanlist_comment {
    my ($app) = @_;
    my @ids = $app->param('id')
	or return $app->error("Need comments to add to IPBanList");
    for my $id (@ids) {
	my $comment = MT::Comment->load($id, { cache_ok => 1 });
	_add_to_ipbanlist($comment->blog_id, $comment->ip);
    }
    $app->call_return;
}

sub _add_to_ipbanlist {
    my ($blog_id, $ip) = @_;
    unless (MT::IPBanList->load({ blog_id => $blog_id, ip => $ip })) {
	my $ban = MT::IPBanList->new;
	$ban->blog_id($blog_id);
	$ban->ip($ip);
	$ban->save or die $ban->errstr;
    }
}

sub ipbanlist {
    my ($ctx, $args) = @_;
    my @blog_ids = defined $args->{blog_id} ?
	split /\s*,\s*/, $args->{blog_id} : [ $ctx->stash('blog_id') ];
    my %ips;
    for my $blog_id (@blog_ids) {
	my @list = MT::IPBanList->load({ blog_id => $blog_id });
	%ips = map { $_->ip => 1 } @list;
    }
    my @res;
    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    for my $ip (keys %ips) {
	local $ctx->{__stash}{'ipbanlist_ip'} = $ip;
	defined(my $out = $builder->build($ctx, $tokens))
	    or return $ctx->error($ctx->errstr);
	push @res, $out;
    }
    my $glue = $args->{glue} || '';
    join $glue, @res;
}

sub ipbanlist_ip {
    $_[0]->stash('ipbanlist_ip') || '';
}

1;

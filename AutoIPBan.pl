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
use base 'MT::Plugin';

use vars qw($VERSION);

sub BEGIN {
    $VERSION = 0.01;
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
	_add_ipbanlist($blog_id, $ip);
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
	_add_ipbanlist($blog_id, $ip);
        return 0;
    }
    1;
}

sub _add_ipbanlist {
    my ($blog_id, $ip) = @_;
    unless (MT::IPBanList->load({ blog_id => $blog_id, ip => $ip })) {
	my $ban = MT::IPBanList->new;
	$ban->blog_id($blog_id);
	$ban->ip($ip);
	$ban->save or die $ban->errstr;
    }
}

1;

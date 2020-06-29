#!/usr/bin/perl

package xCAT::Magiclab;

use strict;
use warnings;

our $err = 0;
our $errstr = '';

my $checks = {
    'hosts' => [
        \&chk_addr_dups,
    ],
    'mac' => [
        \&chk_mac_dups,
    ],
};


sub run {
    my $tab = shift;

    return unless $tab->isa('xCAT::Table');

    $err = 0;
    $errstr = '';

    $_->($tab) for @{$checks->{$tab->{tabname}}};
}

sub chk_mac_dups {
    my $tab = shift;
    my %macs;

    my ($node, $mac);
    my $sth = $tab->{dbh}->prepare('SELECT node,mac FROM ' . $tab->{tabname});

    $sth->execute();
    $sth->bind_columns(\$node, \$mac);

    while ($sth->fetch) {
        push @{$macs{lc $mac}}, $node if $mac;
    }

    __report_dups($tab->{tabname}, \%macs);
}

sub chk_addr_dups {
    my $tab = shift;
    my %addrs;

    my ($node, $ip, $otherinterfaces);
    my $sth = $tab->{dbh}->prepare('SELECT node,ip,otherinterfaces FROM ' . $tab->{tabname});

    $sth->execute();
    $sth->bind_columns(\$node, \$ip, \$otherinterfaces);

    while ($sth->fetch) {
        push @{$addrs{$ip}}, $node if $ip;

        next unless $otherinterfaces;
        for my $rec (split ',', $otherinterfaces) {
            my (undef, $addr) = split ':', $rec, 2;

            push @{$addrs{$addr}}, $node if $addr;
        }
    }

    __report_dups($tab->{tabname}, \%addrs);
}

sub __report_dups {
    my ($tabname, $href) = @_;

    my @dups = grep { scalar @{$href->{$_}} > 1 } keys %$href;

    return unless scalar @dups;

    $err++;
    $errstr .= ' ; ' if length($errstr);
    $errstr .= 'Ignoring duplicates in \'' . $tabname . '\' table: ' . join(', ', @dups);
}

1;

#!/usr/bin/perl

use strict;

use FindBin;
use lib "$FindBin::Bin/";
use MenuSuite;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Net::MPD;
my $mpd = Net::MPD->connect();

sub playOrPause
{
    if ($mpd->state eq 'stop')
    {
        $mpd->play();
    }
    elsif ($mpd->state eq 'pause')
    {
        $mpd->pause(0);
    }
    elsif ($mpd->state eq 'play')
    {
        $mpd->pause(1);
    }
}

sub dumpMpdObject
{
    print Dumper($mpd);
}

sub secondsToString($)
{
    my $seconds = shift;
    return sprintf("%02d:%02d", ($seconds / 60) % 60, $seconds % 60);
}

my %options = (
    List   => sub {
        my @songList = $mpd->playlist_info();

        my $songToString = sub(\%)
        {
            my $song = $_;
            return sprintf("%s %s - %s",
                           $song->{'Track'},
                           $song->{'Title'},
                           $song->{'Album'});
        };

        my @formattedList = map(&$songToString, @songList);

        &MenuSuite::dmenu(join("\n", @formattedList));
    },
    Play   => \&playOrPause,
    Next   => sub { $mpd->next(); },
    Prev   => sub { $mpd->previous(); },
    Replay => sub { $mpd->stop(); $mpd->play(); },
    Pause  => sub { $mpd->pause(); },
    Stop   => sub { $mpd->stop(); },
    State  => sub {
        my %songInfo = %{$mpd->current_song()};
        my @data = (
            $songInfo{'Title'},
            $songInfo{'Artist'},
            $songInfo{'Album'},
            $songInfo{'Track'},
            secondsToString($mpd->elapsed),
            secondsToString($songInfo{'Time'})
            );

        &MenuSuite::dmenu(join("\n", @data));
    },
    Toggle => sub
    {
        my $randomState  = $mpd->random;
        my $repeatState  = $mpd->repeat;
        my $consumeState = $mpd->consume;
        my $singleState  = $mpd->single;

        # Proof of concept
        my %toggleOptions = (
            "Random: $randomState"   => sub { $mpd->random($mpd->random   ? 0 : 1); },
            "Repeat: $repeatState"   => sub { $mpd->repeat($mpd->repeat   ? 0 : 1); },
            "Consume: $consumeState" => sub { $mpd->consume($mpd->consume ? 0 : 1); },
            "Single: $singleState"   => sub { $mpd->single($mpd->single   ? 0 : 1); },
            );

        &MenuSuite::runMenu(\%toggleOptions);
    },
    # Debug => \&dumpMpdObject,
    );

&MenuSuite::runMenu(\%options);

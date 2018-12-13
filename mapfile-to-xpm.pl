#!/usr/bin/perl
use strict;
use warnings;
no warnings 'portable';
#for 32-bit platforms: use bignum qw/hex/;

my $desired_width = shift || 1024;
my $desired_height = shift || 16;

my ($current_pos, $current_mode);
my $max_start;
my %map;
while(<>){
	s/\s*\#.*//;
	next if m/^$/;
	if (m/^0x([0-9A-F]+)\s+(.)$/i) {
		die if defined $current_pos;
		$current_pos = hex $1;
		$current_mode = $2;
	} elsif (m/^0x([0-9A-F]+)\s+0x([0-9A-F]+)\s+(.)$/i) {
		my $start = hex $1;
		$map{$start} = [hex $2, $3];
		$max_start = $start if not defined($max_start) or $start > $max_start;
	}
}

my $end_pos = $max_start + $map{$max_start}->[0];
my $total_pixels = $desired_width * $desired_height;
my $pixel_bytes = int(($end_pos + $total_pixels - 1) / $total_pixels);

my $current_pos_pixel = int($current_pos / $pixel_bytes);

my $margin = 6;  # for arrow
my $image_width = $desired_width + ($margin * 2);
my $image_height = $desired_height + 16;

print "/* XPM */\n";
print "static char * XFACE[] = {\n";
print "\"$image_width $image_height 7 1\",\n";
print "\"_ c #ffffff\",\n";
print "\"B c #000000\",\n";
print "\"? c #cccccc\",\n";
print "\"* c #777777\",\n";
print "\"/ c #773333\",\n";
print "\"- c #ff0000\",\n";
print "\"+ c #00ff00\",\n";

my $arrow_left = int($current_pos_pixel / $desired_height) + $margin - 6;
my $arrow_right = $image_width - $arrow_left - 13;
$arrow_left = "\"" . ("_" x $arrow_left);
$arrow_right = ("_" x $arrow_right) . "\",\n";
print $arrow_left . "_____BBB_____" . $arrow_right for 1..9;
print $arrow_left . "BBBBBBBBBBBBB" . $arrow_right;
print $arrow_left . "_BBBBBBBBBBB_" . $arrow_right;
print $arrow_left . "__BBBBBBBBB__" . $arrow_right;
print $arrow_left . "___BBBBBBB___" . $arrow_right;
print $arrow_left . "____BBBBB____" . $arrow_right;
print $arrow_left . "_____BBB_____" . $arrow_right;
print $arrow_left . "______B______" . $arrow_right;

my @lines;
push @lines, ("\"" . ("_" x $margin)) for 1..$desired_height;

my %status_precedence = (
	"+" => 0,  # finished
	"?" => 1,  # non-tried
	"*" => 2,  # non-trimmed
	"/" => 3,  # non-scraped
	"-" => 4,  # bad sector
);

my %status_stats;

my $byte_pos = 0;
my $pixel_status;
while ($byte_pos < $end_pos) {
	my $block_len = $map{$byte_pos}->[0];
	my $status = $map{$byte_pos}->[1];
	die unless defined $status;
	if (not defined($pixel_status) or $status_precedence{$status} > $status_precedence{$pixel_status}) {
		$pixel_status = $status;
	}
	my $end = $byte_pos + $block_len;
	$status_stats{$status} += $block_len;
	my $pixel_pos = int($byte_pos / $pixel_bytes);
	my $new_pixel_pos = int($end / $pixel_bytes);
	while ($new_pixel_pos > $pixel_pos) {
		# This pixel is complete
		my $pixel_row = $pixel_pos % $desired_height;
		$lines[$pixel_row] .= $pixel_status;
		$pixel_status = $status;
		++$pixel_pos;
	}
	$byte_pos = $end;
	undef $pixel_status if 0 == $byte_pos % $pixel_bytes;
}

$_ .= ("_" x $margin) . "\",\n" for @lines;

$lines[$desired_height-1] =~ s/,(\n)$/$1/;

print for @lines;
print "};\n";

warn sprintf("%s %15u bytes\n", $_, $status_stats{$_}) for sort keys %status_stats;

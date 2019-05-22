#!/usr/bin/env perl

use strict;
use warnings;

use lib 'blib/lib';

use Test::More;

use File::Temp qw/tempfile/;

use Geo::OSM::Overpass;
use Geo::OSM::Overpass::Plugin::ParseXML;
use Geo::BoundingBox;

my $num_tests = 0;

my $bbox = Geo::BoundingBox->new();
ok(defined $bbox && 'Geo::BoundingBox' eq ref $bbox, 'Geo::BoundingBox->new()'.": called") or BAIL_OUT('Geo::BoundingBox->new()'.": failed, can not continue."); $num_tests++;
# this is LAT,LON convention
ok(1 == $bbox->bounded_by(
	[35.150143, 33.354471, 35.166643, 33.390803]
), 'bbox->bounded_by()'." : called"); $num_tests++;

my $eng = Geo::OSM::Overpass->new();
ok(defined $eng && 'Geo::OSM::Overpass' eq ref $eng, 'Geo::OSM::Overpass->new()'.": called") or BAIL_OUT('Geo::OSM::Overpass->new()'.": failed, can not continue."); $num_tests++;
$eng->verbosity(2);
$eng->query_output_type('xml');
#ok(defined $eng->bbox($bbox), "bbox() called"); $num_tests++;

my $plug = Geo::OSM::Overpass::Plugin::ParseXML->new({
	'engine' => $eng
});
ok(defined($plug) && 'Geo::OSM::Overpass::Plugin::ParseXML' eq ref $plug, 'Geo::OSM::Overpass::Plugin::ParseXML->new()'." : called"); $num_tests++;

my $bbox_query = $bbox->stringify_as_OSM_bbox_query_xml();
my $querystr =
	$eng->_overpass_XML_preamble()
." <union>
  <query type='node'>
   <has-kv k='highway' v='traffic_signals'/>
   ${bbox_query}
  </query>
 </union>
"
	.$eng->_overpass_XML_postamble()."\n"
;
ok($querystr =~ /output="xml"/, "checking if output type is set to XML"); $num_tests++;

# run it without any results or input, it should fail
my $res = $plug->gorun();
ok(! defined $res, "checking gorun() without any input or query and should fail"); $num_tests++;

# make some results by calling a query (see above)
ok(defined $eng->query($querystr), "running a simple query") or BAIL_OUT("failed to run a simple query to provide XML input for testing."); $num_tests++;

# run it with instore results
$res = $plug->gorun();

ok(defined $res, "checking gorun() from instore last query result"); $num_tests++;

ok(exists $res->{'node'} and exists  $res->{'meta'} and exists $res->{'version'} and exists $res->{'note'} and exists $res->{'generator'}, "checking if generator, note, node, version and meta exist as keys in returned hashtable."); $num_tests++;
my @nodes = @{$res->{'node'}};
ok(scalar(@nodes) > 0, "checking if more than one nodes returned."); $num_tests++;
my @found = grep { $_->{'id'} eq '25419283' } @nodes;
ok(1 == scalar @found, "found node with id '25419283'."); $num_tests++;

# now run it when input is from string
$res = $plug->gorun({
	'input-string' => ${$eng->last_query_result()}
});

ok(defined $res, "checking gorun() from supplied string"); $num_tests++;

ok(exists $res->{'node'} and exists  $res->{'meta'} and exists $res->{'version'} and exists $res->{'note'} and exists $res->{'generator'}, "checking if generator, note, node, version and meta exist as keys in returned hashtable."); $num_tests++;
@nodes = @{$res->{'node'}};
ok(scalar(@nodes) > 0, "checking if more than one nodes returned."); $num_tests++;
@found = grep { $_->{'id'} eq '25419283' } @nodes;
ok(1 == scalar @found, "found node with id '25419283'."); $num_tests++;

# now run it when input is a string REF
$res = $plug->gorun({
	'input-string' => $eng->last_query_result()
});

ok(defined $res, "checking gorun() from supplied string"); $num_tests++;

ok(exists $res->{'node'} and exists  $res->{'meta'} and exists $res->{'version'} and exists $res->{'note'} and exists $res->{'generator'}, "checking if generator, note, node, version and meta exist as keys in returned hashtable."); $num_tests++;
@nodes = @{$res->{'node'}};
ok(scalar(@nodes) > 0, "checking if more than one nodes returned."); $num_tests++;
@found = grep { $_->{'id'} eq '25419283' } @nodes;
ok(1 == scalar @found, "found node with id '25419283'."); $num_tests++;

# now run it when input is from file
my ($tmph, $tmpf) = File::Temp::tempfile();
print $tmph ${$eng->last_query_result()}; close $tmph;
ok(-f $tmpf && -s $tmpf, "created file with XML") or BAIL_OUT("failed to create temporary file holding some XML input for testing."); $num_tests++;
$res = $plug->gorun({
	'input-filename' => $tmpf
});
ok(defined $res, "checking gorun() from filename '$tmpf'"); $num_tests++;

ok(exists $res->{'node'} and exists  $res->{'meta'} and exists $res->{'version'} and exists $res->{'note'} and exists $res->{'generator'}, "checking if generator, note, node, version and meta exist as keys in returned hashtable."); $num_tests++;
@nodes = @{$res->{'node'}};
ok(0 < scalar @nodes, "checking if more than one nodes returned."); $num_tests++;
@found = grep { $_->{'id'} eq '25419283' } @nodes;
ok(1 == ( ()= grep { $_->{'id'} eq '25419283' } @nodes), "found node with id '25419283'."); $num_tests++;
unlink($tmpf);

use Data::Dumper;
print Dumper($res);

# END
done_testing($num_tests);

package Geo::OSM::Overpass::Plugin::ParseXML;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use parent 'Geo::OSM::Overpass::Plugin';

use XML::Hash::XS qw//;

# assuming that the engine has run a query and some results
# have been obtained OR 'input-string' parameter specifies
# the text to parse or 'input-filename' parameter specifies
# the name of the file containing XML
# returns undef on failure
# WARNING: JSON has 'elements' instead of 'nodes'
sub gorun {
	my $self = $_[0];
	my $params = $_[1];
	$params = {} unless defined $params;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my %conv_params = (
		utf8 => 1,
		encoding => 'utf-8'
	);
	if( exists $params->{'converter-params'} ){
		@conv_params{keys %{$params->{'converter-params'}}} = values %{$params->{'converter-params'}}
	}
	my $conv = XML::Hash::XS->new(%conv_params);
	if( ! defined $conv ){ print STDERR "$whoami (via $parent) : call to ".'XML::Hash::XS->new()'." has failed.\n"; return undef }

	my $res = undef;
	if( exists $params->{'input-string'} ){
print "GETETET\n".$params->{'input-string'}."\n";
		if( 'SCALAR' eq ref $params->{'input-string'} ){
			$res = $conv->xml2hash(${$params->{'input-string'}});
		} else { 
			$res = $conv->xml2hash($params->{'input-string'});
		}
	} elsif( exists $params->{'input-filename'} ){
		my $FH;
		if( ! open $FH, '<:encoding(utf-8)', $params->{'input-filename'} ){ print STDERR "$whoami (via $parent) : failed to open file '".$params->{'input-filename'}."' for reading, $!\n"; return undef }
		my $content;
		{ undef $/; $content = <$FH> } close $FH;
		$res = $conv->xml2hash($content);
	} else {
		my $eng = $self->engine();
		if(  ! defined $eng ){ print STDERR "$whoami (via $parent) : engine is undefined therefore only supplied filename or XML strings can be processed.\n"; return undef }
		my $resref = $eng->last_query_result();
		if( ! defined $resref ){ print STDERR "$whoami (via $parent) : last query result is undefined, there is no XML to process either from the input params ('input-string' or 'input-filename' or from the last query result).\n"; return undef }
		$res = $conv->xml2hash($$resref);
	}
	if( ! defined $res ){ print STDERR "$whoami (via $parent) : call to ".'xml2hash()'." has failed.\n"; return undef }

	return $res # success

# we get something like:
#          'node' => [
#                       {
#                        'id' => '25419283',
#                        'tag' => [
#                                   {
#                                     'k' => 'highway',
#                                     'v' => 'traffic_signals'
#                                   },
#                                   {
#                                     'k' => 'name',
#                                     'v' => 'Likavitou'
#                                   },
#                                   {
#                                     'k' => 'traffic_signals',
#                                     'v' => 'signal'
#                                   }
#                                 ],
#                        'lon' => '33.3639874',
#                        'lat' => '35.1644946'
#                      },
#	   ],
#          'generator' => 'Overpass API 0.7.55.7 8b86ff77',
#          'note' => 'The data included in this document is from www.openstreetmap.org. The data is made available under ODbL.',
#          'meta' => {
#                      'osm_base' => '2019-05-11T12:56:02Z'
#                    },
#          'version' => '0.6'
#        };
#
# WARNING: JSON has 'elements' instead of 'nodes'
}

# end of program, pod starts here
=head1 NAME

Geo::OSM::Overpass::Plugin::ParseXML - Plugin for L<Geo::OSM::Overpass> to fetch bus stop data in given area

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

This is a plugin for L<Geo::OSM::Overpass>, which is a module to fetch
data from the OpenStreetMap (OSM) Project using Overpass API. It fetches
information about an OSM element given element id and element type.

In order to use this plugin, first create
a L<Geo::OSM::Overpass> object to do the communication with the
Overpass API server. Secondly, create the plugin object and run
its C<gorun()> method. (note: no bounding box is required)

    use Geo::OSM::Overpass;
    use Geo::OSM::Overpass::Plugin::ParseXML;
    use Data::Dumper;

    my $eng = Geo::OSM::Overpass->new();
    die unless defined $eng;
    my $plug = Geo::OSM::Overpass::Plugin::ParseXML->new({
        'engine' => $eng
    });
    die unless defined $plug;
    my $perlstruct = $plug->gorun({'input-string'=><<'EOXML'}) or die;
<?xml version="1.0"?>
<osm version="0.6" generator="Overpass API 0.7.55.7 8b86ff77">
<note>The data included in this document is from www.openstreetmap.org.
The data is made available under ODbL.</note>
<meta osm_base="2019-05-15T22:24:03Z"/>

  <node id="37559112" lat="35.1759320" lon="33.3745372">
    <tag k="highway" v="traffic_signals"/>
  </node>

</osm>
EOXML

    # or run a query first, e.g. FetchTrafficSignals and then
    # just call $plug->gorun() (with no parameters) to process those results.
    # anyway, with our minimal example ...
    print Dumper($perlstruct);

=head1 SUBROUTINES/METHODS

=head2 C<< new({'engine' => $eng}) >>

Constructor. A hashref of parameters contains the
only required parameter which is an already created
L<Geo::OSM::Overpass> object. If in your plugin have
no use for this, then call it like C<new({'engine'=>undef})>


=head2 C<< gorun(...) >>

It will convert OSM XML results to a Perl hashtable. The XML to
be converted can either be from the optional hashref parameter
C<input-string> or C<input-filename> or as a last resort from
the last query results of the engine. One of these must be
specified. If you go with the engine then make sure that
a query has been executed and it was successful and
C<last_query_result()> returns a defined value, i.e.
a reference to the string holding the results.

It will return the Perl hashtable produced on success or C<undef> on failure.


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 CAVEATS

This is alpha release, the API is not yet settled and may change.

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-osm-overpass-plugin-ParseXML at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-OSM-Overpass-Plugin-ParseXML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::OSM::Overpass::Plugin::ParseXML


You can also look for information at:

=over 4

=item * L<Geo::BoundingBox> a geographical bounding box class.

=item * L<Geo::OSM::Overpass> aka the engine.

=item * L<Geo::OSM::Plugin> the parent class of all the plugins for
L<Geo::OSM::Overpass>

=item * L<https://www.openstreetmap.org> main entry point for the OpenStreetMap Project.

=item * L<https://wiki.openstreetmap.org/wiki/Overpass_API/Language_Guide> Overpass API
query language guide.

=item * L<https://overpass-turbo.eu> Overpass Turbo query language online
sandbox. It can also convert to XML query language.

=item * L<http://overpass-api.de/query_form.html> yet another online sandbox and
converter.

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-OSM-Overpass-Plugin-ParseXML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-OSM-Overpass-Plugin-ParseXML>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Geo-OSM-Overpass-Plugin-ParseXML>

=item * Search CPAN

L<https://metacpan.org/release/Geo-OSM-Overpass-Plugin-ParseXML>

=back


=head1 DEDICATIONS

Almaz

=head1 ACKNOWLEDGEMENTS

The OpenStreetMap project and all the good people who
thought it, implemented it, collected the data and
publicly host it.

```
 @misc{OpenStreetMap,
   author = {{OpenStreetMap contributors}},
   title = {{Planet dump retrieved from https://planet.osm.org }},
   howpublished = "\url{ https://www.openstreetmap.org }",
   year = {2017},
 }
```

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut

1; # End of Geo::OSM::Overpass::Plugin::ParseXML

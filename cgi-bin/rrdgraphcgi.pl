# CGI library to easily tweak RRD graph parameters from a web browser

# by Timothy.D.Witham@intel.com, 2008/06/27

# TODO: convert to an easy to use object with methods (CGI::RRDs?)
# TODO: convert to datepicker from new 3.6 ganglia web

use warnings;
use CGI qw/:all/;
use Date::Parse;
use RRDs;
use POSIX qw/strftime/;

# Set variables that we will need.  These globals are all available to
# the calling program, if they want to read them.
sub rrdinit {

    our $cgi = new CGI;

    # size
    our $width = param('width') || 400;
    our $height = param('height') || 200;

    # time
    our $HOUR = 60 * 60;
    our $DAY = $HOUR * 24;
    our $WEEK = $DAY * 7;
    our $MONTH = $DAY * 31;
    our $QUARTER = $WEEK * 13;
    our $YEAR = $DAY * 365;
    our $now = time;
    our $start = param('start') || $when || $when || $now - $DAY;
    $start = str2time($start) if $start =~ /\D/;
    our $end = param('end') || $now;
    $end = str2time($end) if $end =~ /\D/;
    $start = $end - $HOUR if $start > $end - $HOUR;
    our $diff = $end - $start;

    # format should match calendar.js and work with RRD
    our $timestart = strftime "%b %d %Y %H:%M", localtime $start;
    our $timeend = strftime "%b %d %Y %H:%M", localtime $end;

    our @onchange = param('manual') ? ()
	: (-onchange => 'this.form.submit()');
}

sub pn { p . "\n" }
sub brn { br . "\n" }

sub rrdgraph {
    my($name, @graph) = @_;
    my $xport = param('xport') || 0;
    print header($xport eq 'csv' ? (-type => 'application/csv',
				    '-Content-Disposition'
				    => 'inline; filename="rrd.csv"')
		 : $xport ? 'text/plain'
		 : 'image/png');

    my $step = 60 * (param('step') || 0);	# minutes -> seconds
    $step = $diff / 2 if $step > $diff / 2; # avoid breaking graphs
    unshift @graph, '--step' => $step if $step;

    if (!$xport or $xport eq 'rrd') {
	my $little = ($width < 400 || param('small')) ? 1 : 0;

	my $time = localtime $end;
	$time =~ s/:\d\d / /;

	# graph can optionally set its title if 2nd arg contains TIME:
	my $span = &secformat($end - $start);
	$graph[1] =~ s/SPAN/$span/;
	$graph[1] =~ s/TIME/$time/
	    or unshift @graph, '--title'
	    => ($little ? $name : "$name: $span to $time");
	my $target = $width / 7;
	my $label = $graph[1];
	$label =~ s/.// while length($label) > $target;
	$graph[1] = "...$label" unless $label eq $graph[1];

	unshift @graph, qw(-M) unless param('zY');
	unshift @graph, '-g' if $little;
	@graph = ('-',
		  '--imgformat'	=> 'PNG',
		  '--start'	=> $start,
		  '--end'	=> $end,
		  '--width'	=> $width,
		  '--height'	=> $height,
		  @graph);
    }
    if ($xport eq 'rrd') {	# reveal the actual rrd command
	print join "\n", "rrdtool graph", @graph;

    } elsif ($xport) {			       # export data
	grep s/\#\w+//, @graph;		       # remove colors
	grep s/:?:(STACK|dash).*//, @graph;      # remove options
	grep s/^(AREA|LINE\d+|STACK)/XPORT/, @graph; # XPORT all graphic vars
	grep s/^(XPORT:)(\w+):*(.*)$/"$1$2:" . ($3 ? "$2=$3" : $2)/e, @graph; # default legend = var
	@graph = grep m/^([CV]?DEF|XPORT)/, @graph; # strip unknowns
	@graph = (-s	=> $start,
		  -e	=> $end,
		  -m	=> $width,
		  @graph);
	if ($xport =~ 'xml|json') {
	    $xport =~ /json/ and unshift @graph, '--json'; # not on SLES10
	    open my $fh, '-|', qw(rrdtool xport), @graph or die $!;
	    while (<$fh>) {
		print;
	    }
	} else {		# csv
	    my($t, $e, $i, $c, $l, $d)
		= RRDs::xport(@graph);
# 	    print join "\n", @graph, "\n";
# 	    use Data::Dumper;
# 	    print Dumper $t, $e, $i, $c, $l, $d;
# 	    print "my($t, $e, $i, $c, $l, $d)\n";
	    print join(',', 'UTC Time', @$l), "\n";
	    for my $ref (@$d) {
		print join(',', strftime('%FT%T', gmtime $t),
			   map { defined $_ ? $_ : '' } @$ref), "\n";
		$t += $i;
	    }
	}
    } else {			# normal graph
	RRDs::graph(@graph);
	my $err = RRDs::error;
	die "ERROR while graphing $name: $err\n" if $err;
    }
}

# return data values from given PRINT commands
sub rrdget {
    my($file, @graph) = @_;
    my $step = 60 * (param('step') || 0); # minutes -> seconds
    $step = $diff / 2 if $step > $diff / 2; # avoid breaking graphs
    unshift @graph, '--step' => $step if $step;
    my($averages) = RRDs::graph('', # write "image" to nowhere?
				'--start' => $start,
				'--end' => $end,
				@graph,
	);
    my $err = RRDs::error;
    die "ERROR while graphing $file: $err\n" if $err;
    return @$averages;
}

# $selection, \%menu, \@prefixes, \@between, \@postfixes
sub rrdheader {
    my($name, $file, $pre, $mid, $mid2, $post) = @_;
    my $parent = $name;
    $parent =~ s@(.*)/[^/]+$@$1@;
    $parent = 0 if $parent eq $name;

    my $calendar = '
<script type="text/javascript">
var fmt = "%b %d %Y %H:%M";	// must be a format that RRDtool likes
function isDisabled(date, y, m, d) {
  var today = new Date();
  return (today.getTime() - date.getTime()) < -1 * Date.DAY;
}
function checkcal(cal) {	// ensure cs < ce
  var date = cal.date;
  var time = date.getTime();
  var field = document.getElementById("cs");
  if (field == cal.params.inputField) {	// cs was changed: change ce
    field = document.getElementById("ce");
    var other = new Date(Date.parseDate(field.value, fmt));
    if (time >= other) {
      date = new Date(time + Date.HOUR);
      field.value = date.print(fmt);
    }
  } else {			// ce was changed: change cs
    field = document.getElementById("cs");
    var other = new Date(Date.parseDate(field.value, fmt));
    if (other >= time) {
      date = new Date(time - Date.HOUR);
      field.value = date.print(fmt);
    }
  }
}
Calendar.setup({
  inputField     : "cs",
  ifFormat       : fmt,
  showsTime      : true,
  step           : 1,
  weekNumbers    : false,
  onUpdate	 : checkcal,
  dateStatusFunc : isDisabled
});
Calendar.setup({
  inputField     : "ce",
  ifFormat       : fmt,
  showsTime      : true,
  step           : 1,
  weekNumbers    : false,
  onUpdate	 : checkcal,
  dateStatusFunc : isDisabled
});
</script>
';
    my $css = '
.img_view {
  float: left;
  margin: 0;
  padding: 1px;
}
.footer {
  clear: both;
';
    print header,
    start_html(-title => "$name to $timeend",
	       -style => {-src => '/jscalendar-1.0/calendar-system.css',
			  -code => $css },
	       -script => [ {-language => 'JAVASCRIPT',
			     -src=>'/jscalendar-1.0/calendar.js'},
			    {-language => 'JAVASCRIPT',
			     -src=>'/jscalendar-1.0/lang/calendar-en.js'},
			    {-language => 'JAVASCRIPT',
			     -src=>'/jscalendar-1.0/calendar-setup.js'},
			  ],
	      ),

    start_form(-method => 'GET');

    $timeend = '' if abs($now - $end) < 5 * 60;

    print @$pre if $pre and @$pre;

    print join('&nbsp;',
	       &link('<<', { start => $start - $diff,
			     end => $end - $diff },
		     'previous full page'),
	       &link('<', { start => $start - int($diff / 2 + 0.5),
			    end => $end - int($diff / 2 + 0.5) },
		     'previous half page'),
	       textfield(-name => 'start', @onchange,
			 -id => 'cs',
			 -title => 'start time',
			 -size => 17,
			 -default => $timestart,
			 -override => 1) . '&nbsp;-&nbsp;' .
	       textfield(-name => 'end', @onchange,
			 -id => 'ce',
			 -title => 'end time',
			 -size => 17,
			 -default => $timeend,
			 -override => 1),
	       &link('now', { start => undef, end => undef }, 'go to TODAY'),
	       &link('>', { start => $start + int($diff / 2 + 0.5),
			    end => $end + int($diff / 2 + 0.5) },
		     'next half page'),
	       &link('>>', { start => $start + $diff,
			     end => $end + $diff },
		     'next full page'),
	       popup_menu(-name => 'step', @onchange,
			  -title => 'Graph Resolution',
			  -values =>
			  [qw/1 5 15 60 180 360 720 1440 10080 43800/],
			  -labels => {1		=> 'most detail',
				      5		=> '5 minutes',
				      15	=> '15 minutes',
				      60	=> 'hourly',
				      180	=> '3 hours',
				      360	=> '6 hours',
				      720	=> '12 hours',
				      1440	=> 'daily',
				      10080	=> 'weekly',
				      43800	=> 'monthly'}));

    print @$mid if $mid and @$mid;
    print brn;
    print @$mid2 if $mid2 and @$mid2;

    print join('&nbsp;',
	       &link('<<', { start => $end - $diff * 3}, 'DRILL OUT * 3'),
	       &link('<', { start => $end - $diff * 2}, 'drill out * 2'),
	       &link('y', { start => $end - $YEAR }, 'year'),
	       &link('q', { start => $end - $QUARTER }, 'quarter'),
	       &link('m', { start => $end - $MONTH }, 'month'),
	       &link('w', { start => $end - $WEEK }, 'week'),
	       &link('d', { start => $end - $DAY }, 'day'),
	       &link('h', { start => $end - $HOUR }, 'hour'),
	       &link('>', { start => $end - int($diff / 2 + 0.5)},
		     'drill in / 2'),
	       &link('>>', { start => $end - int($diff / 3 + 0.5)},
		     'DRILL IN / 3'),
	       textfield(-name => 'width', @onchange,
			 -title => 'plot area width',
			 -default => $width,
			 -size => 4) . 'x' .
	       textfield(-name => 'height', @onchange,
			 -title => 'plot area height',
			 -default => $height,
			 -size => 4),
	       &link('><', { width => $width - 200 >= 200 ? $width - 200 : 200,
			     height => $height-200 >= 100 ? $height-200 : 100 },
		     'smaller graph'),
	       &link('<>', { width => $width + 200,
			     height => $height <= 100 ? $height + 100
				 : $height + 200},
		     'larger graph'),
	       checkbox(-name => 'zY', @onchange,
			-title => 'UnZoom Y axis scaling'),
	       ($file
		? (&link('/', { file => undef }, 'Root Node'),
		   ($parent ? &link('..', { file => $parent },
				    'Parent Node') : ''),
		   popup_menu(-name => 'file', @onchange,
			      -title => 'RRD data file',
			      -values => [@$file],
			      -default => $name))
		: ()));
    print submit('Go'),
    checkbox(-name => 'manual',
	     -title => 'manual form submission instead of automatic'), ' ';
    print @$post if $post and @$post;
    print brn, "\n$calendar\n";
}

sub rrdgraphtime {
    my($i) = @_;		# times should be configurable, but:
    my @time = ($HOUR,6*$HOUR, $DAY, $WEEK, $MONTH, $QUARTER, $YEAR,4*$YEAR);
    for my $time ($end - $start, @time) {
	my $start = $end - $time;
	my $span = &secformat($end - $start);
	my @opts = (graph => $i, start => $start);
	print qq'<div class="img_view">$span - zoom: ',
	&link('3x', { @opts,
		      width => $width * 3,
		      height => $height * 3 }), ' | ',
	&link('4x', { @opts,
		      width => $width * 4,
		      height => $height * 4 }), ' | export: ',
	&link('csv',  { @opts, xport => 'csv' }), ' | ',
	&link('xml',  { @opts, xport => 'xml' }), ' | ',
	&link('json', { @opts, xport => 'json' }), ' | ',
	&link('rrd',  { @opts, xport => 'rrd' }),
	brn,
	&link(img({-src => &link(0, { graph => $i,
				      start => $start }),
		   -alt => "Graph $i",
		   -valign => "top",
		   -title => "Click to Zoom",
		   -border => 0 }),
	      { graph => $i,
		start => $start,
		width => $width * 2,
		height => $height * 2 }),
	"</div>\n";
    }
}

sub rrdtable {
    my($rrd, $drill, $root) = @_;

    print "<table cellspacing=0 cellpadding=0>\n";
    for (my $i = 0; $i < @$rrd; $i++) {
	unless (ref $rrd->[$i]) {
	    print $rrd->[$i];
	    $drill = 1 if $rrd->[$i] =~ /drill/i;
	} elsif (param('Debug')) {
	    print "<pre>", join("\n", @{$rrd->[$i]}), "</pre>\n";
	} elsif ($drill) {
	    my @file = ( file => $rrd->[$i][0] );
	    if ($root) {
		@file = ($root => $1, file => $2)
		    if $root and $rrd->[$i][0] =~ m!^([^/]+)/(.+)$!;
	    }
	    my $prg;	  # hack for nbstatus trends global click-outs
	    my @arg;
	    if (-l "$rrd->[$i][0].url") { # .url can click out to linked URL
		my $arg;
		$prg = readlink "$rrd->[$i][0].url";
		($prg, $arg) = ($1, $2) if $prg =~ /(.*?)\?(.*)/;
		map { push @arg, split m/=/, $_, 2 } split /[;&]/, $arg;
	    } elsif ($rrd->[$i][0] =~ m!global-(\w+)/(\S+\.intel\.com)!) {
		$prg = "http://$2/cgi-bin/nb/$1";
	    }
	    print &link(img({-src => &link(0, { graph => $i,
						small => (param('Legend')
							  ? 0 : 1) }
					  ),
			     -alt => "Graph $i",
			     -valign => "top",
			     -title => "Click to Drill IN",
			     -border => 0 }),
			{ ($prg ? (file => undef, @arg) : @file) },
			undef, $prg);
	} else {
	    print &link(img({-src => &link(0, { graph => $i}),
			     -alt => "Graph $i",
			     -valign => "top",
			     -title => "Click for options",
			     -border => 0 }),
			{ graphtime => $i });
# 			  width => $width * 2,
# 			  height => $height * 2 });
	}
    }
    print "</table>\n";
}

sub rrdfooter {
    my($file) = @_;
    print qq'<div class="footer">\n';

    if (my $info = RRDs::info($file)) {	# format some info about the RRD
	my $data = {};
	my $step = $info->{step};
	my @tr;			# header
	push @tr, Tr([td(['last updated', $info->{last_update},
			  scalar localtime $info->{last_update}]),
		      td(['size', -s $file, 'bytes']),
		      td(['version', $info->{rrd_version}]),
		      td(['step', &secformat($step),
			  'best possible resolution']),
		     ]);
	print table({-border => 1}, caption(b($info->{filename})), @tr);

	for (sort keys %$info) { # reorganize data for easier access
	    $data->{$1}{$2}{$3} = $info->{$_} if /^(\S+)\[([^\]]+)\]\.(\S+)/;
#	print "$_\t$info->{$_}", brn; # uncomment to debug all values
			       }
	@tr = ();		# data sources
	for (sort keys %{$data->{ds}}) {
	    my $info = $data->{ds}{$_};
	    defined $info->{min} or $info->{min} = 'U';
	    defined $info->{max} or $info->{max} = 'U';
	    push @tr, Tr(td([$_, $info->{type},
			     "range $info->{min} - $info->{max}",
			     "unknown after "
			     . &secformat($info->{minimal_heartbeat})]));
	}
	print table({-border => 1}, caption(b('Data Sources')), @tr);

	@tr = ();		# archives
	my $total = 0;
	for (sort {$a <=> $b} keys %{$data->{rra}}) {
	    my $info = $data->{rra}{$_};
	    push @tr, Tr(td([$_, &secformat($info->{pdp_per_row} * $step),
			     $info->{cf}, " for "
			     . &secformat($info->{rows} * $info->{pdp_per_row}
					  * $step),
			     " up to ". $info->{xff} * 100 . "% unknown",
			     $info->{rows} . ' rows',
			    ]));
	    $total += $info->{rows};
	}
	grep s@(\d+) rows@sprintf "$1 rows (%.0f%%)", $1 / $total * 100@e, @tr;
	print table({-border => 1}, caption(b('Round Robin Archives')), @tr);

    } else {

	return unless $file;
	my $time = localtime((stat $file)[9]);
	print "$file last modified $time\n";
    }
    print "</div>\n";
}

BEGIN {
    my %num = (1			=> 'seconds',
	       60			=> 'minutes',
	       60 * 60			=> 'hours',
	       60 * 60 * 24		=> 'days',
	       60 * 60 * 24 * 7		=> 'weeks',
	       60 * 60 * 24 * 365 / 12	=> 'months', # approximate
#	       60 * 60 * 24 * 7 * 13	=> 'quarters',
	       60 * 60 * 24 * 365	=> 'years');

    sub secformat {    # format seconds to a short human readable time
	my $seconds = shift;
	my $n = 0;
	for (sort {$b <=> $a} keys %num) {
	    $n = $_;
	    last if $seconds / $n > 1;
	}
	my $out = sprintf "%.1f %s", $seconds / $n, $num{$n};
	$out =~ s/\.0 / /;
	$out =~ s/^(1 .*)s/$1/;
	return $out;
    }
}

sub link {    # return a link to myself or $prg, with given params set
    my($name, $aref, $title, $prg) = @_;
    my $new = new CGI($cgi);
    $new->delete('graphtime') # hack!!! - return options view to main view
	unless $name =~ /^(><|<>)$/; # except for size change
    for (keys %$aref) {
	my $val = $aref->{$_};
	if (defined $val) {
	    $new->param(-name => $_, -values => $val);
	} else {
	    $new->delete($_);
	}
    }
    my $link = $new->url(-relative => 1, -query => 1);
    $link =~ s![^?/]+(\??|$)!$prg$1! if $prg;
    return $link unless $name; # return link only? (like for image source)

    $aref = {-href => $link};
    $aref->{-title} = $title if $title;
    $name = escapeHTML $name unless $name =~ /<img/;
    return a($aref, $name);
}

1;				# return true

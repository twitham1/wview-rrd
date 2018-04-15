# Things TODO in wview-rrd

* move configurable parameters out to config file.
** database location
** preferred units
** names of extra sensors

* strip ww out of rrdgraphlib.pl, not needed for this app

* re-write rrdgraphcgi.pl as an actual object module, suitable for
  CPAN, unless this already exits.  Something like CGI::RRDs?

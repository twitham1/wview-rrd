# This config file must be valid perl and end with 1.  Keep it secure.

# Anything in the top of cgi-bin/weather can be changed.  Here is what
# my station uses for example. -twitham@sbcglobal.net

# our $where = '/var/lib/weewx/archive'; # or wherever it is
# our $primary = 'FF00FF';
# our $title = 'Weather at my house';

our $name1 = 'Garage';		# extra sensor 1
our $name2 = 'Attic';		# extra sensor 2

our $link = ' See also: '. a({-href => '/weather/'}, 'wview page');

# # to default all units to metric (see %math in ./weather):
# %def = qw(temp C speed kph press mbar depth mm);
# # or to override only one at a time:
# $def{press} = 'kpa';

1;

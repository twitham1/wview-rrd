# This config file must be valid perl and end with 1.  Keep it secure.

# Anything in the top of cgi-bin/weather can be changed.  Here is what
# my station uses for example. -twitham@sbcglobal.net

# our $primary = 'FF00FF';
# our $title = 'Weather at my house';

our $link = ' See also: '. a({-href => '/weather/'}, 'weewx');
# $link .= ', '
#     . a({-href => 'https://wunderground.com/dashboard/pws/KTXAUSTI1217'},
# 	'wunderground');

# our $install = 1341118800;	# station install time in seconds

# # to default all units to metric (see %math in ./weather):
# %def = qw(temp C speed kph press mbar depth mm);
# # or to override only one at a time:
# $def{press} = 'kpa';

# Optional sensors with names and colors.  Uncomment only if you have
# data in .sdb file.  See also /etc/wview-rrd.pl
our $extra = {

    # UV => [ UV => $primary ],	# uncomment if you have Ultra Violet data

    extraTemp1 => [ qw/Garage   000000/ ],
    extraTemp2 => [ qw/Attic    888888/ ],
    extraTemp3 => [ qw/BedRoom  00FF00/ ],
    extraTemp4 => [ qw/Porch    FF00FF/ ],

    extraHumid1 => [ qw/Garage   000000/ ],
    extraHumid2 => [ qw/Attic    888888/ ],
    extraHumid3 => [ qw/BedRoom  00FF00/ ],
    extraHumid4 => [ qw/Porch    FF00FF/ ],

};

1;				# this file must return true

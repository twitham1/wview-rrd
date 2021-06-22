# This config file must be valid perl and end with 1.  Keep it secure.

# configure optional data for wview-rrd, by twitham@sbcglobal.net

# uncomment optional station variables that you have in your .sdb:
our %extra = (
#    UV		=> "GAUGE:0:36",
    extraTemp1	=> "GAUGE:-50:200",
    extraTemp2	=> "GAUGE:-50:200",
    extraTemp3	=> "GAUGE:-50:200",
    extraTemp4	=> "GAUGE:-50:200",
    extraHumid1	=> "GAUGE:0:100",
    extraHumid2	=> "GAUGE:0:100",
    extraHumid3	=> "GAUGE:0:100",
    extraHumid4	=> "GAUGE:0:100",
    );

# uncomment optional status variables that you have:
our %status = (

    # in default wview schema:
    windBatteryStatus	=> "GAUGE:0:1",
    rainBatteryStatus	=> "GAUGE:0:1",
#    uvBatteryStatus	=> "GAUGE:0:1",
    outTempBatteryStatus => "GAUGE:0:1",

    # only in extended TE923 schema:
    extraBatteryStatus1	=> "GAUGE:0:1",
    extraBatteryStatus2	=> "GAUGE:0:1",
    extraBatteryStatus3	=> "GAUGE:0:1",
    extraBatteryStatus4	=> "GAUGE:0:1",
    windLinkStatus	=> "GAUGE:0:1",
    rainLinkStatus	=> "GAUGE:0:1",
#    uvLinkStatus	=> "GAUGE:0:1",
    outLinkStatus	=> "GAUGE:0:1",
    extraLinkStatus1	=> "GAUGE:0:1",
    extraLinkStatus2	=> "GAUGE:0:1",
    extraLinkStatus3	=> "GAUGE:0:1",
    extraLinkStatus4	=> "GAUGE:0:1",
    forecast	=> "GAUGE:0:7",
    storm	=> "GAUGE:0:1",
    );

1;				# this file must return true

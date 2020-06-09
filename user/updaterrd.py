# Update RRD copy of weather data.  See https://github.com/twitham1/wview-rrd

# Thanks to mwall for this simple hook idea.  Enable in weewx.conf
# [Engine][[Services]] by appending to the archive_services list:
# user.updaterrd.UpdateRRD

import subprocess
import weewx
from weewx.engine import StdService

class UpdateRRD(StdService):
    """Update wview-rrd RRD files from source database.""" 
    def __init__(self, engine, config_dict):
        super(UpdateRRD, self).__init__(engine, config_dict)
        self.bind(weewx.NEW_ARCHIVE_RECORD, self.new_archive_record)

    def new_archive_record(self, event):
        subprocess.call(["/usr/bin/wview-rrd"])

# homematic-checkmk

This is a basic implementation of a checkmk-compatible check written in powershell which is parsing the XML output that homematic supplies.

## What goes where?

As of now there are two relevant files included with this check.

* homematic-checkmk.conf, which goes into /etc/check_mk/
* homematic.ps1, which goes into /usr/lib/check_mk_agent/local/

For deployment on Windows some modifications will most likely be required on the paths above.

## Customizing

homematic-checkmk.conf contains the XMLUrl-value, which by default points to a URL on localhost. You might need to change this, should you be monitoring your homematic-CCU from another host.

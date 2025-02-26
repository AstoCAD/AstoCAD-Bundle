import sys
import os
import subprocess
import platform
from datetime import datetime

import freecad
import FreeCAD

package_manager = "conda"
system = platform.platform().split("-")[0]
arch = platform.machine()

if system == "macOS":
    if arch == "x86_64":
        arch = "-intel"
        mac_arch_str = "i386"
    elif arch == "arm64":
        arch =  "-arm"
        mac_arch_str = "arm64"
elif system == "Linux":
    if arch == "aarch64":
        arch = "-arm"
    else:
        arch = "-intel"
else:
    arch = "" # lets just not show that as there only 1 build anyway.

python_version = platform.python_version().split(".")
python_version = "py" + python_version[0] + python_version[1]
date = str(datetime.now()).split(" ")[0]

version_info = FreeCAD.Version()
build_version_suffix = FreeCAD.ConfigGet("BuildVersionSuffix")
dev_version = version_info[0] + "." + version_info[1] + "." + version_info[2] + build_version_suffix
revision = version_info[3].split(" ")[0]

if system == "macOS":
    import jinja2
    print("create plist from template")
    osx_directory = os.path.join(os.path.dirname(__file__), "..", "osx")
    with open(os.path.join(osx_directory, "Info.plist.template")) as template_file:
        template_str = template_file.read()
    template = jinja2.Template(template_str)
    rendered_str = template.render( FREECAD_VERSION=dev_version, 
                                    APPLICATION_MENU_NAME="AstoCAD {}".format(dev_version),
                                    ARCHITECTURE=mac_arch_str )
    with open(os.path.join(osx_directory, "APP", "AstoCAD.app", "Contents", "Info.plist"), "w") as rendered_file:
        rendered_file.write(rendered_str)

if "DEPLOY_RELEASE" in os.environ and os.environ["DEPLOY_RELEASE"] == "weekly-builds":
    dev_version = ""
    revision_separator = ""
else:
    revision_separator = "."
    #revision = ""

bundle_name = f"AstoCAD_{dev_version}{revision_separator}{revision}-{system}{arch}"

with open("bundle_name.txt", "w") as bundle_name_file:
    bundle_name_file.write(bundle_name)

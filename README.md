# vultr-marketplace-scripts
A series of helper scripts meant to make making Vultr Marketplace apps easier on the end user

# vultr-tools.sh
This script is intended to be put on an image to facilitate both building and post deploy. It contains
a series of function to make both easier and reduce complexity and maintenance of your app.

```bash
#!/bin/bash

# Fail out on errors, you should definitely use this if possible
# This prevents silent failures from producing failed images
set -eo pipefail

# Include the file into your environment
. /opt/myapp/vultr-tools.sh

# Realistically you should never need to use it, but it exists just in case you deo
# This waits on apt locks to expire so you can safely run apt commands
wait_on_apt_lock

# Install packages via apt without worrying about apt locks
apt_safe nano vim wget

# Update repos via apt without worrying about apt locks
apt_update_safe

# Update packages via apt without worrying about apt locks
apt_upgrade_safe

# Clean packages via apt without worrying about apt locks
apt_clean_safe

# Get the hostname for this instance
HOSTNAME=$(get_hostname)

# Get the root password for this instance, this will be a hash
ROOTPASS=$(get_root_password)

# Get the userdata for this instance
USERDATA=$(get_userdata)

# Get the SSH Keys for this instance
SSHKEYS=$(get_sshkeys)

# This is to get a variable and set it. The variable name is what will be retrieved and set
get_var site_password
echo ${site_password}

# This will install cloud-init. Note this only works for RHEL based, Debian based, and Ubuntu based distros!
# Acceptable options are latest,nightly, generally you want to use latest
install_cloud_init latest

# This cleans the system for final release
# If you set a pipefail, and you should of, it is safe to disable it for this line
# Otherwise incompatible commands will cause a failure
set +eo pipefail

# This is the command that cleans the system
clean_system

set -eo pipefail
```

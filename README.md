# vps-setup

<img src="setup.png">


This script has been tested on Ubuntu version 22 and higher.

Update and Upgrade system latest packages
Set swap and size
Set SHH port to your choice
Config SHH:
	PermitRootLogin prohibit-password
	Port
	PasswordAuthentication no
	MaxAuthTries 2
	KbdInteractiveAuthentication no
	ChallengeResponseAuthentication no
X11Forwarding no
AuthorizedKeysFile .ssh authorized_keys
Timezone set
Instal and config NTP server
Nano set: set constantshow, set linenumbers, set mouse
Install unattended-upgrades and config:
Unattended-Upgrade::AutoFixInterruptedDpkg
Unattended-Upgrade::Remove-Unused-Kernel-Packages
Unattended-Upgrade::Remove-New-Unused-Dependencies
Unattended-Upgrade::Remove-Unused-Dependencies
Unattended-Upgrade::Remove-New-Unused-Dependencies
Unattended-Upgrade::Automatic-Reboot
Unattended-Upgrade::Automatic-Reboot-Time
20 auto-upgrades
Periodic::Update-Package-Lists
Periodic::Unattended-Upgrade


Install:
```
wget https://raw.github.com/schoutem/vps-setup/master/setup.sh
```

```
bash setup.sh
```


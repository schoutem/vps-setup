# vps-setup

<img src="setup.png">

### VPS Setup

This script has been tested on Ubuntu version 22 and higher.

> [!WARNING]
> You must first set and Generating an SSH key (will be implemented soon)

- Update and Upgrade system latest packages<br />
- Set swap and size<br />
Set SHH port to your choice<br />
- Config SHH:<br />
  - PermitRootLogin prohibit-password<br />
  - Port<br />
  - PasswordAuthentication no<br />
  - MaxAuthTries 2<br />
  - KbdInteractiveAuthentication no<br />
  - ChallengeResponseAuthentication no<br />
  - X11Forwarding no<br />
- AuthorizedKeysFile .ssh authorized_keys<br />
- Timezone set<br />
- Instal and config NTP server<br />
- Nano set: set constantshow, set linenumbers, set mouse<br />
- Install unattended-upgrades and config:<br />
  - Unattended-Upgrade::AutoFixInterruptedDpkg<br />
  - Unattended-Upgrade::Remove-Unused-Kernel-Packages<br />
  - Unattended-Upgrade::Remove-New-Unused-Dependencies<br />
  - Unattended-Upgrade::Remove-Unused-Dependencies<br />
  - Unattended-Upgrade::Remove-New-Unused-Dependencies<br />
  - Unattended-Upgrade::Automatic-Reboot<br />
  - Unattended-Upgrade::Automatic-Reboot-Time<br />
- 20 auto-upgrades<br />
  - Periodic::Update-Package-Lists<br />
  - Periodic::Unattended-Upgrade<br />


Install:
```
wget https://raw.github.com/schoutem/vps-setup/master/setup.sh
```

```
bash setup.sh
```


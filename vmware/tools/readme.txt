In Ubuntu 14.04, GNOME Flashback desktop environment (gnome-session-fallback)
sets the value of environmental variable XDG_CURRENT_DESKTOP as Unity. It is
likely the result that GNOME Flashback desktop environment now has a 
dependency on some packages of Ubuntu Unity desktop environment, for instance,
the following dependency relationship shows that GNOME Flashback desktop
environment depends on "unity-settings-daemon". 

$ apt-cache depends gnome-session-fallback
gnome-session-fallback
  Depends: gnome-session-flashback
$ apt-cache depends gnome-session-flashback
gnome-session-flashback
  Depends: gnome-panel
  Depends: gnome-session-bin
  Depends: gnome-session-common
  Depends: metacity
  Depends: nautilus
  Depends: notification-daemon
  Depends: policykit-1-gnome
    lxpolkit
    lxsession
  Depends: unity-settings-daemon
  Suggests: compiz
  Suggests: desktop-base
  Suggests: gnome-keyring
  Suggests: gnome-user-guide
  Recommends: gnome-power-manager
  Recommends: gnome-screensaver
  Breaks: gnome-session-fallback
  Replaces: gnome-session
  Replaces: gnome-session-bin
  Replaces: gnome-session-fallback
$ 

VMware Unity mode only works with GNOME, KDE, and XFCE desktop environments.
As a result that GNOME Flashback desktop environment in Ubuntu 14.04 sets
the variable as Unity, the script vmware-xdg-detect-de returns Unity and
VMware refuses to enter VMware Unity mode. Similar, when Mate desktop
environment is running, vmware-xdg-detect-de could not recognize the
desktop environment and returns a blank string. In both cases, the desktop
environments are actually a variant of GNOME. 

I made a simple revision to vmware-xdg-detect-de to allow it to return GNOME
in above two cases. VMware can enter the Unity mode when the two desktop
environment environments are running when /usr/bin/vmware-xdg-detect-de is
replaced the revised one. 

Usage/installing:
    cd ~/Downloads
    wget https://raw.githubusercontent.com/graychan/notes/master/vmware/tools/vmware-xdg-detect-de
    sudo cp vmware-xdg-detect-de /usr/bin/vmware-xdg-detect-de
    
You will need to log off and on or restart for it to take effect (in your VM). 
You MUST be logged into the VM in order to use Unity mode, otherwise you will
get an error that the resolution can not be changed.


install gnome-session fallback 

sudo apt-get update
sudo apt-get install gnome-session-fallback

wget https://raw.githubusercontent.com/graychan/notes/master/vmware/tools/vmware-xdg-detect-de
sudo cp vmware-xdg-detect-de /usr/bin/vmware-xdg-detect-de


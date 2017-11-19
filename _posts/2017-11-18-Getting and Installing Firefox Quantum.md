---
layout: post
title: "Getting and Installing Firefox Quantum"
date: "2017-11-18 17:54"
---

# Problem

The following describes the process of trying out Firefox Quantum using an installation of RHEL/CentOS.

# Solution

Firefox Quantum isn't currently available via package manager - yet. Extract the [Firefox Quantum][1] tarball source file into the `/opt` directory.

1. Open a terminal, and issue this command to download & extract Mozilla's latest browser.

       #!/bin/bash

       sudo bash -c '[[ "$(uname -m)" == "x86_64" ]] \
                     && ost="$(uname)";ost="${ost,,}64" \
                     && dir="/opt";app="firefox";ver="latest" \
                     && uri="https://download.mozilla.org" \
                     && src="$uri/?product=$app-$ver-ssl&os=$ost" \
                     && curl -L "$src" | tar xfj - -C $dir \
                     && unset ost app ver uri src dir'

2. Create a GNOME desktop entry for the add-on application software package.

       #!/bin/bash

       sudo bash -c 'OLD_DESKTOP_FILE="/usr/share/applications/firefox.desktop"
                     NEW_DESKTOP_FILE="/usr/share/applications/firefox-quantum.desktop"
                     EXEC_REGEX="Exec\=firefox"; EXEC_SUBST="Exec\=\/opt\/firefox\/firefox"
                     ICON_REGEX="Icon\=firefox"; ICON_SUBST=I"con\=\/opt\/firefox\/browser\/icons\/mozicon128\.png"
                     NAME_REGEX="Firefox"; NAME_SUBST="Firefox Quantum"

                     if [[ ! -f $NEW_DESKTOP_FILE ]]; then
                      if [[ -f $OLD_DESKTOP_FILE ]]; then # Recycle old desktop entry
                       sed "s/$EXEC_REGEX/$EXEC_SUBST/g
                            s/$ICON_REGEX/$ICON_SUBST/g
                            s/$NAME_REGEX/$NAME_SUBST/g" $OLD_DESKTOP_FILE > $NEW_DESKTOP_FILE
                      else                                # Creates new desktop entry
                       cat <<EOF > $NEW_DESKTOP_FILE
       [Desktop Entry]
       Version=1.0
       Name=Firefox Quantum Web Browser
       Comment=Browse the Web
       Exec=/opt/firefox/firefox %u
       Icon=/opt/firefox/browser/icons/mozicon128.png
       Terminal=false
       Type=Application
       MimeType=text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;text/mml;x-scheme-handler/http;x-scheme-handler/https;
       Categories=Network;WebBrowser;
       EOF
       fi
       fi'

3. Restart GNOME Display Manager (GDM).

       #!/bin/bash

       systemctl restart gdm.service

       # [NOTE] Keep in mind that restarting the service forcibly interrupts any
       # currently running GNOME session of any desktop user who is logged in. This
       # can result in users losing unsaved data.

# Summary

Wahllah! You've successfully installed Firefox Quantum from an archive according to the current Linux Foundation [Filesystem Hierarchy Standard (FHS)][2], and freedesktop.org [desktop entry specification][3].

You could also also use `yum install firefox -y`,

Also, what I like about this simple exercise is it's educational with regard to where [Linux distributions endorsed by the Free Software Foundation][4] derive their specifications from.

Which makes the above steps for installation a little more instersting because it improves installation portability! Also, if you wanted Firefox Quantum to be available for one user - it's easy!

Just remove `sudo`, set `dir=$HOME` in step #1, and `NEW_DESKTOP_FILE="$HOME/.local/share/applications/firefox-quantum.desktop"` in step #2.

[1]: https://www.mozilla.org/en-US/firefox/new/
[2]: http://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch03s13.html
[3]: https://www.freedesktop.org/wiki/Specifications/desktop-entry-spec/
[4]: https://en.wikipedia.org/wiki/Comparison_of_Linux_distributions

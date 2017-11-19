---
layout: post
title: "Getting and Installing Firefox Quantum"
date: "2017-11-18 17:54"
---

# Problem

The following describes the process of trying out Firefox Quantum using an installation of RHEL/CentOS.

# Solution

Firefox Quantum isn't currently available via package manager currently. So, extract the [Firefox Quantum][1] tarball source file into the `/opt` directory.

1. Open a terminal, and issue this command to download & extract Mozilla's latest browser.

       #!/bin/bash

       sudo bash -c '[[ "$(uname -m)" == "x86_64" ]] \
                     && ost="$(uname)";ost="${ost,,}64" \
                     && dir="/opt";app="firefox";ver="latest" \
                     && uri="https://download.mozilla.org" \
                     && src="$uri/?product=$app-$ver-ssl&os=$ost" \
                     && curl -L "$src" | tar xfj - -C $dir \
                     && unset ost app ver uri src dir'

2. Create a GNOME desktop entry for our new add-on application software package.

       #!/bin/bash

       sudo bash -c 'OLD_DESKD="/usr/share/applications"
                     OLD_DESKF="$OLD_DESKD/firefox.desktop"

                     NEW_DESKD="/usr/share/applications"
                     NEW_DESKF="$NEW_DESKD/firefox-quantum.desktop"

                     EXEC_FIND="firefox";
                     EXEC_REPL="\/opt\/firefox\/firefox"

                     ICON_FIND="firefox";
                     ICON_REPL="\/opt\/firefox\/browser\/icons\/mozicon128\.png"

                     NAME_FIND="Firefox";
                     NAME_REPL="Firefox Quantum"

                     if [[ ! -f $NEW_DESKF ]]; then
                      if [[ -f $OLD_DESKF ]]; then
                       sed "s/Exec\=$EXEC_FIND/Exec\=$EXEC_REPL/g
                            s/Icon\=$ICON_FIND/Icon\=$ICON_REPL/g
                            s/$NAME_FIND/$NAME_REPL/g" $OLD_DESKF > $NEW_DESKF
                      else
                       cat <<EOF > $NEW_DESKF
       [Desktop Entry]
       Version=1.0
       Name=Firefox Quantum Web Browser
       Comment=Browse the Web
       Exec=/opt/firefox/firefox %u
       Icon=/opt/firefox/browser/icons/mozicon128.png
       Terminal=false
       Type=Application
       Categories=Network;WebBrowser;
       EOF
       fi
       fi'

3. Restart GNOME Display Manager (GDM).

       #!/bin/bash

       sudo systemctl restart gdm.service

       # [NOTE] Keep in mind that restarting the service forcibly interrupts any
       # currently running GNOME session of any desktop user who is logged in. This
       # can result in users losing unsaved data.

# Summary

Wahllah! You've successfully installed Firefox Quantum from an archive according to the current Linux Foundation [Filesystem Hierarchy Standard (FHS)][2], and freedesktop.org [desktop entry specification][3].

You could also also use `yum install firefox -y`, but version 57.0 has not been added to the source repository yet, and that would defeat the purpose of this blog post ;)

Now, what I like about this method of installation, is it sheds some light on where [Linux distributions endorsed by the Free Software Foundation][4] derive their specifications from.

Which makes the above steps a little interesting because it shows a trade off between installation portability, and maintenance. Consider this, what happens when specifications change overtime?

Or, how about if there is an update the tarball source file download URL? Is it really worth troubleshooting? Maybe, or maybe not - it depends on who you ask.

Anyway, hope this helps satisfy ones craving for the latest browser tech, and if you wanted Firefox Quantum to be available for one user - that's easy!

Just remove `sudo`, set `dir=$HOME` in step #1, and `NEW_DESKD="$HOME/.local/share/applications"` in step #2. See you space cowboy...

[1]: https://www.mozilla.org/en-US/firefox/new/
[2]: http://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch03s13.html
[3]: https://www.freedesktop.org/wiki/Specifications/desktop-entry-spec/
[4]: https://en.wikipedia.org/wiki/Comparison_of_Linux_distributions

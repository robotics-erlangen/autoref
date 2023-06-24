#!/usr/bin/env bash

if [[ "$1" == "vnc" ]]; then
	shift 1
	echo "Launch in VNC mode"

	if [[ -z "${VNC_PASSWORD}" ]]; then
		VNC_PASSWORD=vncpassword
	fi
	if [[ -z "${VNC_GEOMETRY}" ]]; then
		VNC_GEOMETRY=1920x1080
	fi

	mkdir ~/.vnc
	x11vnc -storepasswd "${VNC_PASSWORD}" ~/.vnc/passwd

	cat <<EOF >>~/.xinitrc
#!/bin/sh
while true; do
	$HOME/build/bin/autoref --qwindowgeometry ${VNC_GEOMETRY} $@
done
EOF

	chmod 700 ~/.xinitrc
	export X11VNC_CREATE_GEOM="${VNC_GEOMETRY}"
	exec x11vnc -forever -usepw -display WAIT:cmd=FINDCREATEDISPLAY-Xvfb
elif [[ "$1" == "gui" ]]; then
	echo "Launch in GUI mode"
	exec $HOME/build/bin/autoref $@
else
	echo "Launch in headless mode"
	exec $HOME/build/bin/autoref-cli $@
fi

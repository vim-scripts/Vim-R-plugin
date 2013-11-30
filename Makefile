
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# A copy of the GNU General Public License is available at
# http://www.r-project.org/Licenses/


###########################################################
#   This script builds both the zip and the deb files of  #
#   released versions of the plugin. The files are        #
#   created at the /tmp directory.                        #
###########################################################



PLUGINHOME=`pwd`
PLUGINVERSION=0.9.9.8
DEBIANTIME=`date -R`
PLUGINRELEASEDATE=`date +"%Y-%m-%d"`
VIM2HTML=/usr/local/share/vim/vim74/doc/vim2html.pl 


vimball:
	# Update the version date in doc/r-plugin.txt header and in the news
	sed -i -e "s/^Version: [0-9].[0-9].[0-9].[0-9]/Version: $(PLUGINVERSION)/" doc/r-plugin.txt
	sed -i -e "s/^$(PLUGINVERSION) (201[0-9]-[0-9][0-9]-[0-9][0-9])$$/$(PLUGINVERSION) ($(PLUGINRELEASEDATE))/" doc/r-plugin.txt
	vim -c "%MkVimball Vim-R-plugin ." -c "q" list_for_vimball
	mv Vim-R-plugin.vmb /tmp

deb:
	# Clean previously created files
	(cd /tmp ; rm -rf vim-r-plugin-tmp )
	# Create the directory of a Debian package
	( cd /tmp ;\
	    mkdir -p vim-r-plugin-tmp/usr/share/vim/addons ;\
	    mkdir -p vim-r-plugin-tmp/usr/share/vim/registry ;\
	    mkdir -p vim-r-plugin-tmp/usr/share/doc/vim-r-plugin )
	# Create the Debian changelog
	echo $(DEBCHANGELOG) "vim-r-plugin ($(PLUGINVERSION)-1) unstable; urgency=low\n\
	\n\
	  * Initial Release.\n\
	\n\
	 -- Jakson Alves de Aquino <jalvesaq@gmail.com>  $(DEBIANTIME)\n\
	" | gzip --best > /tmp/vim-r-plugin-tmp/usr/share/doc/vim-r-plugin/changelog.gz
	# Create the yaml script
	echo "addon: r-plugin\n\
	description: \"Filetype plugin to work with R\"\n\
	disabledby: \"let disable_r_ftplugin = 1\"\n\
	files:\n\
	  - autoload/rcomplete.vim\n\
	  - doc/r-plugin.txt\n\
	  - ftdetect/r.vim\n\
	  - ftplugin/r.vim\n\
	  - ftplugin/rbrowser.vim\n\
	  - ftplugin/rdoc.vim\n\
	  - ftplugin/rhelp.vim\n\
	  - ftplugin/rnoweb.vim\n\
	  - ftplugin/rmd.vim\n\
	  - ftplugin/rrst.vim\n\
	  - indent/r.vim\n\
	  - indent/rnoweb.vim\n\
	  - indent/rhelp.vim\n\
	  - indent/rmd.vim\n\
	  - indent/rrst.vim\n\
	  - r-plugin/common_buffer.vim\n\
	  - r-plugin/common_global.vim\n\
	  - r-plugin/vimcom.py\n\
	  - r-plugin/global_r_plugin.vim\n\
	  - r-plugin/tex_indent.vim\n\
	  - r-plugin/vimrconfig.vim\n\
	  - syntax/r.vim\n\
	  - syntax/rdoc.vim\n\
	  - syntax/rout.vim\n\
	  - syntax/rmd.vim\n\
	  - syntax/rrst.vim\n\
	  - syntax/rhelp.vim\n\
	  - syntax/rbrowser.vim\n\
	" > /tmp/vim-r-plugin-tmp/usr/share/vim/registry/vim-r-plugin.yaml
	# Create the copyright
	echo "Copyright (C) 2011 Jakson Aquino\n\
	\n\
	License: GPLv2+\n\
	\n\
	This program is free software; you can redistribute it and/or modify\n\
	it under the terms of the GNU General Public License as published by\n\
	the Free Software Foundation; either version 2 of the License, or\n\
	(at your option) any later version.\n\
	\n\
	This program is distributed in the hope that it will be useful,\n\
	but WITHOUT ANY WARRANTY; without even the implied warranty of\n\
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n\
	GNU General Public License for more details.\n\
	\n\
	You should have received a copy of the GNU General Public License\n\
	along with this program; if not, write to the Free Software\n\
	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.\n\
	\n\
	See /usr/share/common-licenses/GPL-2, or\n\
	<http://www.gnu.org/copyleft/gpl.txt> for the terms of the latest version\n\
	of the GNU General Public License.\n\
	" > /tmp/vim-r-plugin-tmp/usr/share/doc/vim-r-plugin/copyright
	# Unpack the plugin
	vim -c 'set nomore' -c 'let g:vimball_home="/tmp/vim-r-plugin-tmp/usr/share/vim/addons"' -c "so %" -c "q" /tmp/Vim-R-plugin.vmb
	# Delete file unnecessary in a Debian system
	(cd /tmp/vim-r-plugin-tmp/usr/share/vim/addons ;\
	    rm r-plugin/windows.py )
	# Create the DEBIAN directory
	( cd /tmp/vim-r-plugin-tmp ;\
	    mkdir DEBIAN ;\
	    INSTALLEDSIZE=`du -s | sed -e 's/\t.*//'` )
	# Create the control file
	echo "Package: vim-r-plugin\n\
	Version: $(PLUGINVERSION)\n\
	Architecture: all\n\
	Maintainer: Jakson Alves de Aquino <jalvesaq@gmail.com>\n\
	Installed-Size: $(INSTALLEDSIZE)\n\
	Depends: vim | vim-gtk | vim-gnome, tmux (>= 1.5), ncurses-term, vim-addon-manager, r-base-core\n\
	Enhances: vim\n\
	Section: text\n\
	Priority: extra\n\
	Homepage: http://www.vim.org/scripts/script.php?script_id=2628\n\
	Description: Plugin to work with R\n\
	 This filetype plugin has the following main features:\n\
	       - Start/Close R.\n\
	       - Send lines, selection, paragraphs, functions, blocks, entire file.\n\
	       - Send commands with the object under cursor as argument:\n\
	         help, args, plot, print, str, summary, example, names.\n\
	       - Support for editing Rnoweb files.\n\
	       - Omni completion (auto-completion) for R objects.\n\
	       - Ability to see R documentation in a Vim buffer.\n\
	       - Object Browser." > /tmp/vim-r-plugin-tmp/DEBIAN/control
	# Create the md5sum file
	(cd /tmp/vim-r-plugin-tmp/ ;\
	    find usr -type f -print0 | xargs -0 md5sum > DEBIAN/md5sums )
	# Create the posinst and postrm scripts
	echo '#!/bin/sh\n\
	set -e\n\
	\n\
	helpztags /usr/share/vim/addons/doc\n\
	\n\
	exit 0\n\
	' > /tmp/vim-r-plugin-tmp/DEBIAN/postinst
	echo '#!/bin/sh\n\
	set -e\n\
	\n\
	helpztags /usr/share/vim/addons/doc\n\
	\n\
	exit 0\n\
	' > /tmp/vim-r-plugin-tmp/DEBIAN/postrm
	# Fix permissions
	(cd /tmp/vim-r-plugin-tmp ;\
	    chmod g-w -R * ;\
	    chmod +x DEBIAN/postinst DEBIAN/postrm )
	# Build the Debian package
	( cd /tmp ;\
	    fakeroot dpkg-deb -b vim-r-plugin-tmp vim-r-plugin_$(PLUGINVERSION)-1_all.deb )

htmldoc:
	vim -c ":helptags ~/src/Vim-R-plugin/doc" -c ":quit" ;\
	(cd doc ;\
	    $(VIM2HTML) tags r-plugin.txt ;\
	    sed -i -e 's/<code class.*gmail.com.*code>//' r-plugin.html ;\
	    sed -i -e 's/|<a href=/<a href=/g' r-plugin.html ;\
	    sed -i -e 's/<\/a>|/<\/a>/g' r-plugin.html ;\
	    sed -i -e 's/|<code /<code /g' r-plugin.html ;\
	    sed -i -e 's/<\/code>|/<\/code>/g' r-plugin.html ;\
	    sed -i -e 's/`//g' r-plugin.html ;\
	    sed -i -e 's/<\/pre><hr><pre>/  --------------------------------------------------------\n/' r-plugin.html ;\
	    mv r-plugin.html vim-stylesheet.css /tmp )

all: zip deb htmldoc


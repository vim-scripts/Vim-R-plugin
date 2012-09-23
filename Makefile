
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
PLUGINVERSION=0.9.8
DEBIANTIME=`date -R`
PLUGINRELEASEDATE=`date +"%Y-%m-%d"`
VIM2HTML=/usr/local/share/vim/vim73/doc/vim2html.pl 

zip:
	# Clean previously created files
	(cd /tmp ;\
	    rm -rf vim-r-plugin-tmp/usr/share/vim/addons ;\
	    mkdir -p vim-r-plugin-tmp/usr/share/vim/addons )
	rm -f /tmp/vim-r-plugin-$(PLUGINVERSION).zip
	# To make the distribution version of the plugin the files
	# functions.vim.vanilla and omnils.vanilla must exist. To generate these
	# files, the Vim command :RUpdateObjList must be run with R vanilla running
	# (that is, R with only the default libraries loaded) and, then, the files
	# functions.vim and omnils must be renamed.
	( cd r-plugin ;\
	    mv functions.vim functions.vim.current ;\
	    mv omnils omnils.current ;\
	    cp functions.vim.vanilla functions.vim ;\
	    cp omnils.vanilla omnils )
	# Update the version date in doc/r-plugin.txt header and in the news
	sed -i -e "s/^Version: [0-9].[0-9].[0-9]/Version: $(PLUGINVERSION)/" doc/r-plugin.txt
	sed -i -e "s/^$(PLUGINVERSION) (201[0-9]-[0-9][0-9]-[0-9][0-9])$$/$(PLUGINVERSION) ($(PLUGINRELEASEDATE))/" doc/r-plugin.txt
	# Create a tar.gz file
	tar -cvzf /tmp/vimrplugintmpfile.tar.gz ftdetect/r.vim indent/r.vim indent/rmd.vim \
	    indent/rrst.vim indent/rnoweb.vim indent/rhelp.vim autoload/rcomplete.vim ftplugin/r*.vim \
	    syntax/rout.vim syntax/r.vim syntax/rhelp.vim syntax/rmd.vim \
	    syntax/rrst.vim syntax/rdoc.vim syntax/rbrowser.vim \
	    doc/r-plugin.txt r-plugin/functions.vim r-plugin/vimcom.py \
	    r-plugin/global_r_plugin.vim r-plugin/omnils r-plugin/windows.py \
	    r-plugin/vimActivate.js r-plugin/tex_indent.vim r-plugin/r.snippets \
	    r-plugin/common_buffer.vim r-plugin/common_global.vim \
	    bitmaps/ricon.xbm bitmaps/ricon.png \
	    bitmaps/RStart.png bitmaps/RStart.bmp \
	    bitmaps/RClose.png bitmaps/RClose.bmp \
	    bitmaps/RSendFile.png bitmaps/RSendFile.bmp \
	    bitmaps/RSendBlock.png bitmaps/RSendBlock.bmp \
	    bitmaps/RSendFunction.png bitmaps/RSendFunction.bmp \
	    bitmaps/RSendParagraph.png bitmaps/RSendParagraph.bmp \
	    bitmaps/RSendSelection.png bitmaps/RSendSelection.bmp \
	    bitmaps/RSendLine.png bitmaps/RSendLine.bmp \
	    bitmaps/RListSpace.png bitmaps/RListSpace.bmp \
	    bitmaps/RClear.png bitmaps/RClear.bmp \
	    bitmaps/RClearAll.png bitmaps/RClearAll.bmp
	# Rename the functions.vim and omnils files
	( cd $(PLUGINHOME)/r-plugin ;\
	    mv functions.vim.current functions.vim ;\
	    mv omnils.current omnils )
	# Unpack the tar.gz and create the zip file
	(cd /tmp ;\
	    tar -xvzf vimrplugintmpfile.tar.gz -C vim-r-plugin-tmp/usr/share/vim/addons > /dev/null ;\
	    rm vimrplugintmpfile.tar.gz )
	(cd /tmp/vim-r-plugin-tmp/usr/share/vim/addons ;\
	    chmod +w r-plugin/tex_indent.vim ;\
	    rm -f /tmp/vim-r-plugin-$(PLUGINVERSION).zip ;\
	    zip -r /tmp/vim-r-plugin-$(PLUGINVERSION).zip . )

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
	  - bitmaps/RClose.png\n\
	  - bitmaps/RClear.png\n\
	  - bitmaps/RClearAll.png\n\
	  - bitmaps/RListSpace.png\n\
	  - bitmaps/RSendBlock.png\n\
	  - bitmaps/RSendFile.png\n\
	  - bitmaps/RSendFunction.png\n\
	  - bitmaps/RSendLine.png\n\
	  - bitmaps/RSendParagraph.png\n\
	  - bitmaps/RSendSelection.png\n\
	  - bitmaps/RStart.png\n\
	  - bitmaps/ricon.png\n\
	  - bitmaps/ricon.xbm\n\
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
	unzip /tmp/vim-r-plugin-$(PLUGINVERSION).zip -d /tmp/vim-r-plugin-tmp/usr/share/vim/addons
	# Delete the files unnecessary in a Debian system
	(cd /tmp/vim-r-plugin-tmp/usr/share/vim/addons ;\
	    rm bitmaps/*.bmp r-plugin/windows.py r-plugin/vimActivate.js )
	# Add a comment to r-plugin.txt
	(cd /tmp/vim-r-plugin-tmp/usr/share/vim/addons ;\
	    sed -e 's/3.2.1. Unix (Linux, OS X, etc.)./3.2.1. Unix (Linux, OS X, etc.)~\n\nNote: If the plugin was installed from the Debian package, then the\ninstallation is finished and you should now read sections 3.3 and 3.4./' -i doc/r-plugin.txt )
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
	(cd doc ;\
	    $(VIM2HTML) tags r-plugin.txt ;\
	    sed -i -e 's/<code class.*gmail.com.*code>//' r-plugin.html ;\
	    mv r-plugin.html vim-stylesheet.css /tmp )

all: zip deb htmldoc


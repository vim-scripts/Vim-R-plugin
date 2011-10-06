#!/bin/sh

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
PLUGINVERSION=`date +%y%m%d`

# To make the distribution version of the plugin the files
# functions.vim.vanilla and omniList.vanilla must exist. To generate these
# files, the Vim command :RUpdateObjList must be run with R vanilla running
# (that is, R with only the default libraries loaded) and, then, the files
# functions.vim and omniList must be renamed.
cd r-plugin
mv functions.vim functions.vim.current
mv omniList omniList.current
cp functions.vim.vanilla functions.vim
cp omniList.vanilla omniList

# Go back to the plugin direictory
cd -

# Update the version date in doc/r-plugin.txt header
sed -i -e "s/Version: [0-9][0-9][0-9][0-9][0-9][0-9]/Version: $PLUGINVERSION/" doc/r-plugin.txt

# Create a tar.gz file
tar -cvzf /tmp/vimrplugintmpfile.tar.gz ftdetect/r.vim indent/r.vim \
    indent/rnoweb.vim indent/rhelp.vim autoload/rcomplete.vim ftplugin/r*.vim \
    syntax/rout.vim syntax/r.vim syntax/rhelp.vim syntax/rdoc.vim syntax/rbrowser.vim \
    doc/r-plugin.txt r-plugin/*.R r-plugin/functions.vim \
    r-plugin/global_r_plugin.vim r-plugin/omniList r-plugin/windows.py \
    r-plugin/vimActivate.js r-plugin/tex_indent.vim r-plugin/r.snippets \
    r-plugin/common_buffer.vim r-plugin/common_global.vim \
    r-plugin/tmux.conf r-plugin/screenrc \
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

# Rename the functions.vim and omniList files
cd $PLUGINHOME/r-plugin
mv functions.vim.current functions.vim
mv omniList.current omniList

########################################################
##           Create a Debian package                  ##

# Create the directory of a Debian package
cd /tmp
mkdir -p vim-r-plugin-tmp/usr/share/vim/addons
mkdir -p vim-r-plugin-tmp/usr/share/vim/registry
mkdir -p vim-r-plugin-tmp/usr/share/doc/vim-r-plugin

# Create the Debian changelog
DEBIANTIME=`date -R`
echo "vim-r-plugin ($PLUGINVERSION-1) unstable; urgency=low

  * Initial Release.

 -- Jakson Alves de Aquino <jalvesaq@gmail.com>  $DEBIANTIME
" > vim-r-plugin-tmp/usr/share/doc/vim-r-plugin/changelog
gzip --best vim-r-plugin-tmp/usr/share/doc/vim-r-plugin/changelog

# Create the yaml script
echo "addon: r-plugin
description: "Filetype plugin to work with R"
disabledby: "let disable_r_ftplugin = 1"
files:
- autoload/rcomplete.vim
- bitmaps/RClose.png
- bitmaps/RClear.png
- bitmaps/RClearAll.png
- bitmaps/RListSpace.png
- bitmaps/RSendBlock.png
- bitmaps/RSendFile.png
- bitmaps/RSendFunction.png
- bitmaps/RSendLine.png
- bitmaps/RSendParagraph.png
- bitmaps/RSendSelection.png
- bitmaps/RStart.png
- bitmaps/ricon.png
- bitmaps/ricon.xbm
- doc/r-plugin.txt
- ftdetect/r.vim
- ftplugin/r.vim
- ftplugin/rbrowser.vim
- ftplugin/rdoc.vim
- ftplugin/rhelp.vim
- ftplugin/rnoweb.vim
- indent/r.vim
- indent/rnoweb.vim
- indent/rhelp.vim
- r-plugin/build_omniList.R
- r-plugin/common_buffer.vim
- r-plugin/common_global.vim
- r-plugin/etags2ctags.R
- r-plugin/global_r_plugin.vim
- r-plugin/specialfuns.R
- r-plugin/tex_indent.vim
- r-plugin/tmux.conf
- r-plugin/screenrc
- r-plugin/vimbrowser.R
- r-plugin/vimhelp.R
- r-plugin/vimprint.R
- r-plugin/vimSweave.R
- syntax/r.vim
- syntax/rdoc.vim
- syntax/rout.vim
- syntax/rhelp.vim
- syntax/rbrowser.vim
" > vim-r-plugin-tmp/usr/share/vim/registry/vim-r-plugin.yaml

# Create the copyright
echo "Copyright (C) 2011 Jakson Aquino

License: GPLv2+

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.

See /usr/share/common-licenses/GPL-2, or
<http://www.gnu.org/copyleft/gpl.txt> for the terms of the latest version
of the GNU General Public License.
" > vim-r-plugin-tmp/usr/share/doc/vim-r-plugin/copyright

# Unpack the tar.gz and create the zip file
tar -xvzf vimrplugintmpfile.tar.gz -C vim-r-plugin-tmp/usr/share/vim/addons > /dev/null
rm vimrplugintmpfile.tar.gz
cd vim-r-plugin-tmp/usr/share/vim/addons
chmod +w r-plugin/tex_indent.vim
rm -f /tmp/vim-r-plugin-$PLUGINVERSION.zip
zip -r /tmp/vim-r-plugin-$PLUGINVERSION.zip .

# Delete the files unnecessary in a Debian system
rm bitmaps/*.bmp r-plugin/windows.py r-plugin/vimActivate.js

# Add a comment to r-plugin.txt:
sed -e 's/3.2.1. Unix (Linux, OS X, etc.)./3.2.1. Unix (Linux, OS X, etc.)~\n\nNote: If the plugin was installed from the Debian package, then the\ninstallation is finished and you should now read sections 3.3 and 3.4./' -i doc/r-plugin.txt

# Create the DEBIAN directory
cd /tmp/vim-r-plugin-tmp
mkdir DEBIAN
INSTALLEDSIZE=`du -s | sed -e 's/\t.*//'`

# Create the control file
echo "Package: vim-r-plugin
Version: $PLUGINVERSION
Architecture: all
Maintainer: Jakson Alves de Aquino <jalvesaq@gmail.com>
Installed-Size: $INSTALLEDSIZE
Depends: vim | vim-gtk | vim-gnome, screen, tmux (>= 1.5), ncurses-term, vim-addon-manager, r-base-core
Enhances: vim
Section: text
Priority: extra
Homepage: http://www.vim.org/scripts/script.php?script_id=2628
Description: Plugin to work with R
 This filetype plugin has the following main features:
      - Start/Close R.
      - Send lines, selection, paragraphs, functions, blocks, entire file.
      - Send commands with the object under cursor as argument:
        help, args, plot, print, str, summary, example, names.
      - Support for editing Rnoweb files.
      - Omni completion (auto-completion) for R objects.
      - Ability to see R documentation in a Vim buffer.
      - Object Browser." > DEBIAN/control

# Create the md5sum file
arquivos=`find -type f | grep -v DEBIAN | sed -e 's/^\.\///'`
for i in $arquivos
do
    md5sum $i >> DEBIAN/md5sums
done

# Create the posinst and postrm scripts
echo '#!/bin/sh
set -e

helpztags /usr/share/vim/addons/doc

exit 0
' > DEBIAN/postinst

echo '#!/bin/sh
set -e

helpztags /usr/share/vim/addons/doc

exit 0
' > DEBIAN/postrm

chmod +x DEBIAN/postrm DEBIAN/postinst

# Build the Debian package
cd /tmp
fakeroot dpkg-deb -b vim-r-plugin-tmp vim-r-plugin_$PLUGINVERSION-1_all.deb

# Clean
rm -rf vim-r-plugin-tmp


# Warn if the date in the doc is outdated
PLUGINVERSION=`date +"%Y-%m-%d"`
DOCDATEOK=`grep $PLUGINVERSION $PLUGINHOME/doc/r-plugin.txt`
if [ "x$DOCDATEOK" = "x" ]
then
    echo "\033[31mYou must update the version date in r-plugin.txt\033[0m"
fi


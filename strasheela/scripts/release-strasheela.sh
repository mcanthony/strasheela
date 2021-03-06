###!/bin/sh

#
# NB: this is no script anymore, but describes the release process 
#


# test current version: does compilation run smoothly?
cd ~/oz/music/Strasheela/strasheela/trunk/
./strasheela/scripts/uninstall-all.sh
tar -cvzf - `find strasheela -type f \! \( -name "*.wav" -o -name "*.aiff" -o -name "*.mp3" -o -name "*.ozf" \) -print | sed /.svn/d` > ~/tmp/strasheela-test.tar.gz
cd ~/tmp/
tar -xvzf strasheela-test.tar.gz
cd strasheela
./scripts/install-all.sh



#
# update CHANGELOG.txt
#
cd ~/oz/music/Strasheela/strasheela/trunk/strasheela/ # move into strasheela trunk
# NOTE: updating in top-level dir causes loading all tags etc..
svn update					      

# create full change log (first edits to new trunk, and then edits to top-level)
# !!?? why do I need to call svn explicitly on different branches? 
# In this approach the order of the revisions is not OK, revisions top-level (e.g., creation of release branch) happen only after revisions to trunk 
cd ~/oz/music/Strasheela/strasheela/trunk/strasheela/ # move into strasheela trunk
svn -v log > CHANGELOG.txt 
cd ~/oz/music/Strasheela/strasheela # move into top-level strasheela directory
svn -v log >> trunk/strasheela/CHANGELOG.txt

#
# create tag file in SVN repository
#
export VERSION=0.10.1

svn copy https://strasheela.svn.sourceforge.net/svnroot/strasheela/trunk \
         https://strasheela.svn.sourceforge.net/svnroot/strasheela/tags/release-$VERSION \
      -m "Tagging the $VERSION release of Strasheela."


#
# download this release (only files in repository are then in release..)
#
cd ~/oz/music/Strasheela/releases/ # move into top-level release dir 
svn co https://strasheela.svn.sourceforge.net/svnroot/strasheela/tags/release-$VERSION strasheela-$VERSION


#
# archive and compress the release into a tgz file
#
cd ~/oz/music/Strasheela/releases/strasheela-$VERSION
# create tar, only of the essential files -- excluding all soundfiles etc. (take VERSION as argument)
# however, include *.ly and *.midi files: not very big and sometimes needed for testing or functionality
tar -cvzf - `find strasheela -type f \! \( -name "*.wav" -o -name "*.aiff" -o -name "*.mp3" \) -print | sed /.svn/d` > strasheela-$VERSION.tar.gz
# create tar of all the files in the repository (take VERSION as argument)
# tar -cvzf - `find strasheela -type f -print | sed /.svn/d` > strasheela-withSounds-$VERSION.tar.gz



################################################################
#
# old
#

# # This script creates a tar-ball release of Strasheela. Expects the
# # version as argument (e.g. 0.7) and stores all files in the
# # strasheela directory which should be part of a release (e.g. skims
# # files such as *~ or subversion data).
# #
# # TODO: change top-level dir name strasheela into strasheela-$VERSION
# #
# # Problem: some files in my strasheela dir are not added to the subversion repository (like directories labeled "old"), but they will be included in the release.  I don't want to have them in the release, however.
# # Idea to work around this: instead of this script, use subversion tags to denote releases. In that case, however, I must include and update all files which I want to have in the repository (like the file CHANGELOG.txt, which presently is not part of the repository).  
# #
# # what about large sound files which are not part of SVN repository?
# #

# VERSION=$1

# # change to scripts directory 
# cd `dirname $0`

# # move into top-level strasheela directory
# cd ..

# # create CHANGELOG: 
# # NB: I first have to do 'svn update' in order to get my local copy in sync with the resposity
# # svn update
# svn -v log > CHANGELOG.txt

# # move into directory above strasheela
# cd ..

# # create tar (take VERSION as argument)
# # tar -cvzf - `find strasheela -type f \! \( -name "*~" -o -name "*.ozf" \) -print | sed /.svn/d -` > strasheela-withSounds-$VERSION.tar.gz


# #
# # NB: for some reason, I had to remove the trailing - (i.e. hyphen)
# # from sed call on MacOS. I have no idea why it worked before on
# # Linux, but not on Mac. But this version seems to work on both Linux
# # and Mac..
# #

# # create tar, only of the essential files (take VERSION as argument)
# tar -cvzf - `find strasheela -type f \! \( -name "*~" -o -name ".*~" -o -name "*.ozf" -o -name "*.o" -o -name "*.lo" -o -name "*.la" -o -name " #*#" -o -name ".DS_Store" -o -name "*.exe" -o -name "*.fasl" -o -name "*.wav" -o -name "*.aiff" -o -name "*.mp3" -o -name "*.mid" -o -name "*.midi" -o -name "*.ly" -o -name "*.log" -o -name "*.ps" -o -name "*.eps" -o -name "*.pdf" \) -print | sed /.svn/d` > strasheela-$VERSION.tar.gz

# # create tar for the essential files plus the mp3 and midi files (take VERSION as argument)
# tar -cvzf - `find strasheela -type f \! \( -name "*~" -o -name ".*~" -o -name "*.ozf" -o -name "*.o" -o -name "*.lo" -o -name "*.la" -o -name " #*#" -o -name ".DS_Store" -o -name "*.exe" -o -name "*.fasl" -o -name "*.wav" -o -name "*.aiff" -o -name "*.ly" -o -name "*.log" -o -name "*.ps" -o -name "*.eps" -o -name "*.pdf" \) -print | sed /.svn/d` > strasheela-withSound-$VERSION.tar.gz

# # # create tar, only of the essential files (take VERSION as argument)
# # tar -cvzf - `find strasheela -type f \! \( -name "*~" -o -name ".*~" -o -name "*.ozf" -o -name "*.o" -o -name "*.lo" -o -name "*.la" -o -name " #*#" -o -name ".DS_Store" -o -name "*.exe" -o -name "*.fasl" -o -name "*.wav" -o -name "*.aiff" -o -name "*.mp3" -o -name "*.mid" -o -name "*.midi" -o -name "*.ly" -o -name "*.log" -o -name "*.ps" -o -name "*.eps" -o -name "*.pdf" \) -print | sed /.svn/d -` > strasheela-$VERSION.tar.gz
# #
# # # create tar for the essential files plus the mp3 and midi files (take VERSION as argument)
# # tar -cvzf - `find strasheela -type f \! \( -name "*~" -o -name ".*~" -o -name "*.ozf" -o -name "*.o" -o -name "*.lo" -o -name "*.la" -o -name " #*#" -o -name ".DS_Store" -o -name "*.exe" -o -name "*.fasl" -o -name "*.wav" -o -name "*.aiff" -o -name "*.ly" -o -name "*.log" -o -name "*.ps" -o -name "*.eps" -o -name "*.pdf" \) -print | sed /.svn/d -` > strasheela-withSound-$VERSION.tar.gz


# #
# # test
# #
# # lists all files (no dirs) in . except those which (i) match *~, (ii) *.ozf, or (iii) somewhere in their name contain '.svn'
# # find . -type f \! \( -name "*~" -o -name "*.ozf" \) -print | sed /.svn/d - > ../test.log
# # find . -type f \( -name "*~" \) -print 


#!/bin/bash
# 
# Updates WordPress to a new version.
#
# The MIT License (MIT)
# Copyright (c) 2016 Sander Venema <sander@sandervenema.ch>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Should we be verbose?
VERBOSE=false
# controls whether git will autocommit the changes
GIT_AUTOCOMMIT=true
# controls whether git will automatically push the changes to upstream
GIT_PUSH=true

# Some ANSI colours for giving colours to certain messages.
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
NC="$(tput sgr0)"

CACHE_DIR=$HOME/.update_wordpress_cache
WORDPRESS_URL="https://wordpress.org/latest.tar.gz"
WORDPRESS_DIR=$CACHE_DIR/wordpress
WORDPRESS_VERSION=0.0.0 # keep this set to 0.0.0. Will be updated by the script

# Check if cache directory exists, and create it if necessary
if [[ ! -d $CACHE_DIR ]]; then
    echo -e "${YELLOW}Cache directory $CACHE_DIR does not exist, creating...${NC}"
    mkdir $CACHE_DIR
fi

# This should be run in a WordPress directory
if [[ ! -d wp-admin && ! -d wp-includes && ! -d wp-content ]]; then
    echo -e "${RED}Error: Not in a WordPress directory!${NC}"
    echo -e "${RED}cd to a WordPress directory to update and try again.${NC}"
    exit
fi

# We set WORDPRESS_VERSION when we have a WordPress directory in the cache and
# it contains a readme.html file with the version.
if [[ -d $WORDPRESS_DIR && -e $WORDPRESS_DIR/readme.html ]]; then
    WORDPRESS_VERSION=$(cat $WORDPRESS_DIR/readme.html | grep Version | awk '{print $4}')
fi
# Check the version, iff the one on the site is newer, redownload
LATEST_WORDPRESS_VERSION=$(curl -s https://wordpress.org/download/ | perl -lne 'print $1 if /\(Version (.*)\)/')
if [[ ! ($LATEST_WORDPRESS_VERSION == $WORDPRESS_VERSION) ]]; then
    echo "Downloading the latest WordPress..."
    if [[ $VERBOSE ]]; then
      wget -O $CACHE_DIR/latest.tar.gz $WORDPRESS_URL
    else
      wget -q -O $CACHE_DIR/latest.tar.gz $WORDPRESS_URL
    fi

    echo "Checking SHA-1 hash..."
    if [[ $VERBOSE ]]; then
      wget -O $CACHE_DIR/latest.tar.gz.sha1 https://wordpress.org/latest.tar.gz.sha1
    else
      wget -O $CACHE_DIR/latest.tar.gz.sha1 https://wordpress.org/latest.tar.gz.sha1
    fi
    SHA1=$(cat $CACHE_DIR/latest.tar.gz.sha1)
    SHA1_LOCAL=$(sha1sum $CACHE_DIR/latest.tar.gz | awk '{print $1}')
    if [[ ! ($SHA1 == $SHA1_LOCAL) ]]; then
        echo -e "${RED}Error: The SHA-1 checksum does NOT match! Aborting!${NC}"
        echo -e "${RED}SHA-1 checksum from wordpress.org: $SHA1${NC}"
        echo -e "${RED}does not match calculated checksum $SHA1_LOCAL${NC}"
        exit 1
    else
        echo -e "${GREEN}The SHA-1 checksum matches, continuing...${NC}"
    fi

    if [[ -d $CACHE_DIR/wordpress ]]; then
        echo "Removing the old WordPress from the cache..."
        rm -rf $CACHE_DIR/wordpress
    fi
    echo "Unpacking WordPress tarball..."
    if [[ $VERBOSE ]]; then
      tar xfvz $CACHE_DIR/latest.tar.gz -C $CACHE_DIR
    else
      tar xfz $CACHE_DIR/latest.tar.gz -C $CACHE_DIR
    fi
    # Update the version variable to the newly-downloaded version
    WORDPRESS_VERSION=$(cat $WORDPRESS_DIR/readme.html | grep Version | awk '{print $4}')
else
    echo "The latest WordPress (version $WORDPRESS_VERSION) is already in cache, using that."
fi

# Version check
CURRENT_WORDPRESS_VERSION=$(cat readme.html | grep Version | awk '{print $4}')
if [[ $CURRENT_WORDPRESS_VERSION == $WORDPRESS_VERSION ]]; then
    echo -e "${GREEN}WordPress was already updated to version $WORDPRESS_VERSION${NC}"
    exit
fi

GIT=$(which git)
# Are we in a git repo?
if [[ -d .git ]]; then
    GIT_REPO=true
else
    GIT_REPO=false
fi

# Ready to party!

echo "Updating WordPress to version $WORDPRESS_VERSION ..."
echo "Removing wp-includes/ and wp-admin/..."
if [[ -e $GIT && $GIT_REPO == true ]]; then
    $GIT rm -r wp-includes/
    $GIT rm -r wp-admin/
    rm -rf wp-admin/
else
    rm -rf wp-includes/
    rm -rf wp-admin/
fi

echo "Copying new files..."
cp -r $WORDPRESS_DIR/wp-{includes,admin} .
cp $WORDPRESS_DIR/wp-content/*.* wp-content/
cp $WORDPRESS_DIR/*.* .

if [[ -e $GIT && $GIT_REPO == true ]]; then
    echo "Add new files to git repo..."
    $GIT add .
    if [[ $GIT_AUTOCOMMIT == true ]]; then
        echo "Commit files to git repo..."
        $GIT commit -a -m "Updated WordPress to version $WORDPRESS_VERSION"
    fi
    if [[ $GIT_PUSH == true && $GIT_AUTOCOMMIT == true ]]; then
        echo "Push changes to remote git repo..."
        $GIT push
    fi
fi

echo -e "${GREEN}Done! WordPress was successfully updated to version $WORDPRESS_VERSION${NC}"

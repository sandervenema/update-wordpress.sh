# update-wordpress.sh

![demo](https://sandervenema.ch/wp-content/uploads/demo.gif)

`update-wordpress.sh` is a Bash shell script to automatically update
a directory containing [WordPress](https://www.wordpress.org) files to the
latest version that is available for download from the WordPress website. 

The script was written to automate the task of manually updating a WordPress
install in cases where the automatic installation does not work. I wrote it to
dramatically expedite the task of updating WordPress, instead of manually
removing directories and files, downloading the tarball from the website,
checking the SHA-1 checksum and then carefully copying the files/directories
back over.

The script is meant to be run whilst in the directory containing the WordPress
files. Put the script somewhere in your `PATH`, then run it like so:

```
$ update-wordpress.sh
```

The script will automatically detect what version is the latest available (from
the website), download that if necessary, or else use the copy of WordPress 
stored in the cache, and it will only update the website if the versions don't
match up.

## Git

The script will automatically detect if it's running in a git repository. If
this is the case, it will use the `git rm` command to properly record the
removal of directories, and then do a `git add .` at the end.

To save even more time, the script can also auto-commit and push the changes
back to a git repository if necessary. For this, the variables `GIT_AUTOCOMMIT`
and `GIT_PUSH` exist (see the file `update-wordpress.sh`, immediately after the
license). The default value is `true`, meaning that the script will
automatically make a commit with the message:

> `Updated WordPress to version <version>`

and then push the changes to the git repository. Of course, provided that
you've correctly configured git to do a simple `git push`.

## Caching

It will cache the latest version of WordPress in a directory in your
home directory, called `$HOME/.update_wordpress_cache`, where it will put the
`latest.tgz` file from the WordPress website, the SHA-1 checksum, and also the
actual files unpacked in a `wordpress` directory. This is to prevent the script
from re-downloading the files when you have multiple sites you want to update.

## License

The MIT license was used for this script, enclosed in this repository in the
`LICENSE` file.

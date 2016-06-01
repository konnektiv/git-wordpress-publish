#! /bin/bash
# A modification of Dean Clatworthy's deploy script as found here: https://github.com/deanc/wordpress-plugin-git-svn
# The difference is that this script lives in the plugin's git repo & doesn't require an existing SVN repo.

# import main config
CONFIG_FILE="./deploy-config.sh"

if ! test -f $CONFIG_FILE;
	then
		echo "$CONFIG_FILE does not exist. Please create it with the following configuration options:

PLUGINSLUG=\"Your plugin slug as submitted to wordpress.org\"
MAINFILE=\"The name of your main php file in the wordpress plugin\"
SVNUSER=\"your svn username\""
		exit 1
	else
		. $CONFIG_FILE
	fi

CURRENTDIR=`pwd`
# git config
GITPATH="$CURRENTDIR/" # this file should be in the base of your git repository

# svn config
SVNPATH="/tmp/$PLUGINSLUG" # path to a temp SVN repo. No trailing slash required and don't add trunk.
SVNURL="http://plugins.svn.wordpress.org/$PLUGINSLUG/" # Remote SVN repo on wordpress.org, with trailing slash
SVNUSER="konnektiv" # your svn username


# Let's begin...
echo ".........................................."
echo
echo "Preparing to deploy wordpress plugin"
echo
echo ".........................................."
echo

# Check if subversion is installed before getting all worked up
if ! which svn >/dev/null; then
	echo "You'll need to install subversion before proceeding. Exiting....";
	exit 1;
fi

# Check version in readme.txt is the same as plugin file after translating both to unix line breaks to work around grep's failure to identify mac line breaks
NEWVERSION1=`grep "^Stable tag:" $GITPATH/readme.txt | awk -F' ' '{print $NF}'`
echo "readme.txt version: ${NEWVERSION1}"
NEWVERSION2=`grep "^\s*\*\s*Version:" $GITPATH/$MAINFILE | awk -F' ' '{print $NF}'| tr -d '\r'`
echo "$MAINFILE version: ${NEWVERSION2}"

if [ "$NEWVERSION1" != "$NEWVERSION2" ]; then echo "Version in readme.txt & $MAINFILE don't match. Exiting...."; exit 1; fi

echo "Versions match in readme.txt and $MAINFILE. Let's proceed..."

if git show-ref --tags --quiet --verify -- "refs/tags/$NEWVERSION1"
	then
		echo "Version $NEWVERSION1 already exists as git tag. Checking it out.";
		git checkout $NEWVERSION1
	else
		echo "Git version does not exist. Let's create it."
		cd $GITPATH
		echo "Tagging new version in git"
		git tag -a "$NEWVERSION1" -m "Tagging version $NEWVERSION1"
		echo "You should push the new created tag to your git repository with git 'push --tags'"
fi

echo
echo "Creating local copy of SVN repo ..."
svn co $SVNURL $SVNPATH

echo "Clearing svn repo so we can overwrite it"
svn rm --force $SVNPATH/trunk/*

echo "Exporting the HEAD of master from git to the trunk of SVN"
git checkout-index -a -f --prefix=$SVNPATH/trunk/

echo "Ignoring github specific files and deployment script"
svn propset svn:ignore "deploy-config.sh
README.md
.git
.gitignore" "$SVNPATH/trunk/"

echo "Changing directory to SVN and committing to trunk"
cd $SVNPATH/trunk/
# Add all new files that are not set to be ignored
svn status | grep -v "^.[ \t]*\..*" | grep "^?" | awk '{print $2}' | xargs svn add
svn commit --username=$SVNUSER -m "Commiting version $NEWVERSION1"

echo "Creating new SVN tag & committing it"
cd $SVNPATH
svn copy trunk/ tags/$NEWVERSION1/
cd $SVNPATH/tags/$NEWVERSION1
svn commit --username=$SVNUSER -m "Tagging version $NEWVERSION1"

echo "Removing temporary directory $SVNPATH"
rm -fr $SVNPATH/

echo "*** FIN ***"

# Shell script to deploy WordPress plugins from a git repository

## Usage

* Create a file ```deploy-config.sh``` in your plugin base directory with the following options:
```
# main config
PLUGINSLUG="plugin-slug" # The slug of your plugin as submitted to wordpress.org
MAINFILE="plugin-mainfile.php" # this should be the name of your main php file in the wordpress plugin
SVNUSER="svnuser" # your svn username
```
* Run the script ```deploy.sh``` from the top of your plugin directory.
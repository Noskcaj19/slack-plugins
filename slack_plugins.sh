#!/usr/bin/env bash

####################################################################################
# Allow usagge of arbitrary javascript "plugins" with the Slack desktop client
####################################################################################
#
# Loads JavaScript files from `~/.slack_plugins` and injects them
# into the main slack view
#
#
# Derived heavily from Math with Slack (https://github.com/fsavje/math-with-slack)
#
# https://github.com/Noskcaj19/slack-plugins
#
####################################################################################

error() {
	echo "$(tput setaf 124)$(tput bold)✘ $1$(tput sgr0)"
	exit 1
}

if [ "$(uname)" == "Darwin" ]; then
	# macOS
	COMMON_SLACK_LOCATIONS=(
		"/Applications/Slack.app/Contents/Resources/app.asar.unpacked/src/static"
	)
else
	# Linux
	COMMON_SLACK_LOCATIONS=(
		"/usr/lib/slack/resources/app.asar.unpacked/src/static"
		"/usr/local/lib/slack/resources/app.asar.unpacked/src/static"
		"/opt/slack/resources/app.asar.unpacked/src/static"
	)
fi


if [ -z "$SLACK_DIR" ]; then
	for loc in "${COMMON_SLACK_LOCATIONS[@]}"; do
		if [ -e "$loc" ]; then
			SLACK_DIR="$loc"
			break
		fi
	done
fi

if [ -z "$SLACK_DIR" ]; then
	error "Cannot find Slack installation."
elif [ ! -e "$SLACK_DIR" ]; then
	error "Cannot find Slack installation at: $SLACK_DIR"
elif [ ! -e "$SLACK_DIR/ssb-interop.js" ]; then
	error "Cannot find Slack file: $SLACK_DIR/ssb-interop.js"
elif [ ! -w "$SLACK_DIR/ssb-interop.js" ]; then
	error "Cannot write to Slack file: $SLACK_DIR/ssb-interop.js"
fi

echo "Using Slack installation at: $SLACK_DIR"

## Inject code loader

inject_loader() {
	# Check if already injected
	if grep -q -F "/////SLACK PLUGINS START/////" $1; then
		error "File already injected: $1"
	fi

	# Inject loader code
	echo $'

/////SLACK PLUGINS START/////
// ** slack-plugins ** https://github.com/Noskcaj19/slack-plugins
const fs = require(\'fs\');

var scriptElement = document.createElement("script");
scriptElement.src = "https://rawgit.com/Noskcaj19/slack-plugins/master/plugin_utils.js";
document.head.appendChild(scriptElement);

// Load plugins
const pluginPath = path.join(require(\'os\').homedir(), \'.slack_plugins\')
fs.readdir(pluginPath, (err, files) => {
  files.forEach(file => {
    if (path.extname(file) === ".js") {
      console.log(`Loaded plugin from: ${path.join(pluginPath, file)}`);
      fs.readFile(path.join(pluginPath, file), \'utf8\', (e, r) => {
        if (e) {
          console.err(e); 
        } else {
          eval(`document.addEventListener(\'DOMContentLoaded\', function() {${r}})`); 
        }
      });
    }
  });
});
/////SLACK PLUGINS END/////' >> $1
}



inject_loader $SLACK_DIR/ssb-interop.js
inject_loader $SLACK_DIR/ssb-interop-lite.js

echo "Slack Plugins has been installed. Please restart the Slack client."
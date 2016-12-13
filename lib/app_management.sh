#!/usr/bin/env bash
##
# Copyright IBM Corporation 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

function installAgent() {
  mkdir $BUILD_DIR/.app-management
  mkdir $BUILD_DIR/.app-management/utils
  mkdir $BUILD_DIR/.app-management/handlers
  mkdir $BUILD_DIR/.app-management/scripts

  cp $BP_DIR/app_management/scripts/* $BUILD_DIR/.app-management/scripts
  cp $BP_DIR/app_management/utils/* $BUILD_DIR/.app-management/utils
  cp -ra $BP_DIR/app_management/handlers/* $BUILD_DIR/.app-management/handlers
  # vendor folder seems to be a node.js thing... that is even deprecated not for node.js...
  # see following link: http://stackoverflow.com/questions/5178334/folder-structure-for-a-node-js-project
  # also, the liberty buildpack has its own initial_startup.rb file tool
  # see ./resources/liberty/initial_startup.rb
  # the initial_startup.rb file seems to be used only for updating the start command??
  cp $BP_DIR/app_management/initial_startup.rb $BUILD_DIR/.app-management
  cp $BP_DIR/app_management/env.json $BUILD_DIR/.app-management

  chmod +x $BUILD_DIR/.app-management/utils/*
  chmod +x $BUILD_DIR/.app-management/scripts/*
  chmod -R +x $BUILD_DIR/.app-management/handlers/
  chmod +x $BUILD_DIR/.app-management/initial_startup.rb
}

# https://docs.cloudfoundry.org/buildpacks/custom.html#release-script
function updateStartCommands() {
  # Update start command on start script (used by agent/initial startup)
  if test -f ${BUILD_DIR}/Procfile; then
    local start_command=$(sed -n -e '/^web:/p' ${BUILD_DIR}/Procfile | sed 's/^web: //')
    sed -i s#%COMMAND%#"${start_command}"# "${BUILD_DIR}"/.app-management/scripts/start

    # Use initial_startup to start application
    sed -i 's#web:.*#web: ./.app-management/initial_startup.rb#' $BUILD_DIR/Procfile
  else
    sed -i s#%COMMAND%#"npm start"# "${BUILD_DIR}"/.app-management/scripts/start
    # Use initial_startup to start application
    touch $BUILD_DIR/Procfile
    echo "web: ./.app-management/initial_startup.rb" > $BUILD_DIR/Procfile
  fi

  # Update env vars used for dev mode
  #echo "export BOOT_SCRIPT=${start_cmd}" >> ${BUILD_DIR}/.profile.d/bluemix_env.sh
}

function generateAppMgmtInfo() {
  local CONTAINER="warden"
  local SSH_ENABLED="false"
  local PROXY_SUPPORTED='["v1", "v2"]'

  # Generate app management info file. proxy_enabled is set during startup.
cat > $BUILD_DIR/.app-management/app_mgmt_info.json << EOL
{
  "container": "$CONTAINER",
  "ssh_enabled": $SSH_ENABLED,
  "proxy_enabled": false,
  "proxy_supported_version": $PROXY_SUPPORTED
}
EOL

}

function installAppManagement() {
  # Find boot script file
  start_cmd=$($BP_DIR/bin/find_start_cmd $BUILD_DIR)

  status "start_cmd: $start_cmd"

  if [ "$start_cmd" == "" ]; then
    info "WARN: App Management cannot be installed because the start command could not be found."
    info "To install App Management utilities, specify a start command for your Swift application in 'Procfile'."
  else
    # Install development mode utilities
    installAgent && updateStartCommands && generateAppMgmtInfo
    status "installAppManagement end"
  fi
}

installAppManagement
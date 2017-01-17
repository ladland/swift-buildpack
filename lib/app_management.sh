#!/usr/bin/env bash
##
# Copyright IBM Corporation 2016,2017
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

  cp $BP_DIR/app_management/initial_startup.rb $BUILD_DIR/.app-management
  cp $BP_DIR/app_management/env.json $BUILD_DIR/.app-management

  chmod +x $BUILD_DIR/.app-management/utils/*
  chmod +x $BUILD_DIR/.app-management/scripts/*
  chmod -R +x $BUILD_DIR/.app-management/handlers/
  chmod +x $BUILD_DIR/.app-management/initial_startup.rb
}

function updateStartCommands() {
  # Update start command on start script (used by agent/initial startup)
  local start_command=$(sed -n -e '/^web:/p' ${BUILD_DIR}/Procfile | sed 's/^web: //')
  sed -i s#%COMMAND%#"${start_command}"# "${BUILD_DIR}"/.app-management/scripts/start
  # Use initial_startup to start application
  sed -i 's#web:.*#web: ./.app-management/initial_startup.rb#' $BUILD_DIR/Procfile
  status "Updated start command in Procfile:"
  cat ${BUILD_DIR}/Procfile | indent
}

function copyLLDBServer() {
  # Copy lldb-server executable to .swift-bin
  find $CACHE_DIR/$SWIFT_NAME_VERSION -name "lldb-server-*" -type f -perm /a+x -exec cp {} $BUILD_DIR/.swift-bin/lldb-server \;
  # Copy lldb program as well (this is not actually needed for remote debugging... copying it for now)
  find $CACHE_DIR/$SWIFT_NAME_VERSION -regex ".*/lldb-[0-9][0-9.]*"  -type f -perm /a+x -exec cp {} $BUILD_DIR/.swift-bin/lldb \;
}

# function downloadPython() {
#   status "Getting Python"
#   local pkgs=('libpython2.7')
#   download_packages "${pkgs[@]}"
# }

# function removePythonDEBs() {
#   find $APT_CACHE_DIR/archives -name "*python*.deb" -type f -delete
# }

function copyDebugDEBs() {
  status "Copying deb dependencies for debugging..."
  cp $BP_DIR/binary-debug-dependencies/*.deb $APT_CACHE_DIR/archives
}

function removeDebugDEBs() {
  for DEB in $(ls -1 $BP_DIR/binary-debug-dependencies/*.deb); do
    rm $APT_CACHE_DIR/archives/$(basename $DEB)
  done
}

function installAppManagement() {
  # Find boot script file
  start_cmd=$($BP_DIR/lib/find_start_cmd.rb $BUILD_DIR)

  status "start_cmd (app_management): $start_cmd"

  if [ "$start_cmd" == "" ]; then
    status "WARNING: App Management cannot be installed because the start command could not be found."
    status "WARNING: To install App Management utilities, specify a start command for your Swift application in a 'Procfile'."
  else
    # Install development mode utilities
    installAgent && updateStartCommands && copyLLDBServer && copyDebugDEBs
  fi
}

install_app_management() {
  # Install App Management only if user asked for it
  if [[ $BLUEMIX_APP_MGMT_ENABLE == *"debug"* ]]; then
    status "Installing App Management (debug)"
    installAppManagement
    status "Finished installing App Management (debug)"
  else
    removeDebugDEBs
    status "Skipping installation of App Management (debug)"
  fi
}

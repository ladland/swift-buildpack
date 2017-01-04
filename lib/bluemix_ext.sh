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

install_app_management() {
  # Install App Management
  if ! [[ ${BLUEMIX_APP_MGMT_INSTALL,,} == "false" ]]; then
    if ! [[ ${INSTALL_BLUEMIX_APP_MGMT,,} == "false" ]]; then
      status "Installing App Management start"
      source $BP_DIR/lib/app_management.sh
      status "Installed App Management end"
      # We may have to tweak the different handlers... see the handlers for node and liberty and compare them
      # we may need a subset of all of these handlers for an MVP...
      # for instance, see the start-debug handler in the libery buildpack (it requires proxy)
    fi
  fi
}

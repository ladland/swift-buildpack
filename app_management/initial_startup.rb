#!/usr/bin/env ruby
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

# points to /home/vcap/app
app_dir = File.expand_path('..', File.dirname(__FILE__))

app_mgmt_dir = File.join(app_dir, '.app-management')

$LOAD_PATH.unshift app_mgmt_dir

require 'json'
require 'utils/handlers'
require 'utils/simple_logger'

def get_handler_list
  if !ENV['BLUEMIX_APP_MGMT_ENABLE'].nil?
    ENV['BLUEMIX_APP_MGMT_ENABLE'].downcase.split('+').map(&:strip)
  end
end

def start_runtime(app_dir)
  exec(".app-management/scripts/start #{ENV['PORT']}", chdir: app_dir)
end

def start_proxy(app_dir)
  raise 'start_proxy is not implemented yet!'
  #exec('.app-management/bin/proxyAgent', chdir: app_dir)
end

def run(app_dir, env, handlers, background)
  if handlers.length != 0
    command = handlers.map(&:start_script).join(' ; ')
    command = "( #{command} ) &" if background
    system(env, command.to_s, chdir: app_dir)
  end
end

def run_handlers(app_dir, handlers, valid_handlers, invalid_handlers)
  Utils::SimpleLogger.warning("Ignoring unrecognized app management utilities: #{invalid_handlers.join(', ')}") unless invalid_handlers.empty?
  Utils::SimpleLogger.info("Activating app management utilities: #{valid_handlers.join(', ')}")

  # get environment for handlers
  env = get_environment(app_dir)

  # sort handlers for sync and async execution
  sync_handlers, async_handlers = handlers.executions(valid_handlers)

  # execute sync handlers
  run(app_dir, env, sync_handlers, false)

  # execute async handlers
  run(app_dir, env, async_handlers, true)
end

def write_json(file, key, value)
  hash = JSON.parse(File.read(file))
  hash[key] = value
  File.open(file, 'w') do |f|
    f.write(hash.to_json)
  end
end

handler_list = get_handler_list

if handler_list.nil? || handler_list.empty?
  # No handlers are specified. Start the runtime normally.
  start_runtime(app_dir)
else
  handlers_dir = File.join(app_mgmt_dir, 'handlers')

  handlers = Utils::Handlers.new(handlers_dir)

  # validate handlers
  valid_handlers, invalid_handlers = handlers.validate(handler_list)

  # check if proxy agent is required
  proxy_required = handlers.proxy_required?(valid_handlers)

  if proxy_required
    # check instance index
    index = JSON.parse(ENV['VCAP_APPLICATION'])['instance_index']
    if index != 0
      # Start the runtime normally. Only allow dev mode on index 0
      start_runtime(app_dir)
    else
      # Run handlers
      run_handlers(app_dir, handlers, valid_handlers, invalid_handlers)

      # Start proxy
      write_json(File.join(app_mgmt_dir, 'app_mgmt_info.json'), 'proxy_enabled', 'true')
      start_proxy(app_dir)
    end
  else
    # Run handlers
    run_handlers(app_dir, handlers, valid_handlers, invalid_handlers)

    # Start runtime
    start_runtime(app_dir)
  end
end

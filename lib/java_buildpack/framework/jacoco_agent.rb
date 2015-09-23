# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'
require 'java_buildpack/util/qualify_path'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch Jacoco support.
    class JacocoAgent < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Util

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download_zip false
        @droplet.copy_resources
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
       java_opts   = @droplet.java_opts
       java_opts.add_javaagent(@droplet.sandbox + @jacoco_config)
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
       agent_configuration
       #true
       # @application.services.one_service? FILTER, 'configuration'
      end

      private

      FILTER = /jacoco/.freeze

      private_constant :FILTER

      def application_name
        @application.details['application_name']
      end
      
      def configuration
        @application.services.find_service(FILTER)['agentconfig']['configuration'] || 'output=tcpclient,address=localhost,port=6300,includes=*'
      end
      
      def agent_dir
        @droplet.sandbox + 'home/jacoco'
      end

      def logs_dir
        @droplet.sandbox + 'home/log'
      end

      def home_dir
        @droplet.sandbox + 'home'
      end

      def agent_configuration
          # JACOCO_SERVER_URL from ENV
           if ENV.has_key?('JACOCO_SERVER_URL')
              unless ENV['JACOCO_SERVER_URL'].nil? && ENV['JACOCO_SERVER_URL'].empty?
              @server_url = ENV['JACOCO_SERVER_URL']
              end
           end
          # JACOCO_SERVER_PORT from ENV 
           if ENV.has_key?('JACOCO_SERVER_PORT')
              unless ENV['JACOCO_SERVER_PORT'].nil? && ENV['JACOCO_SERVER_PORT'].empty?
              @server_port = ENV['JACOCO_SERVER_PORT']
              end
           end
           
           #construct jacoco_agent configuration using server and port for tcpclient.
           unless @server_url.nil? or @server_port.nil?
               if (not @server_url.empty?) && (not @server_port.empty?)
                 @jacoco_config = "lib/jacocoagent.jar=output=tcpclient,address="+@server_url+",port="+@server_port+",includes=*,append=true"
                  return true
               end
           end
           
           return false
           
      end
    end

  end
end

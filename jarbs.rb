#!/usr/bin/env ruby

require 'rubygems'
require 'fileutils'
require 'commander'

require_relative 'lib/lambda'

module Jarbs
  class CLI
    include Commander::Methods

    def run
      program :version, '0.0.1'
      program :description, 'Lambda Tooling'

      command :new do |c|
        c.syntax = 'jarbs new [options] [name: defaults to dir specified by --dir flag]'
        c.summary = 'Create new lambda function'
        c.option "--dir STRING", String, "Path of code dir to package"
        c.action do |args, options|
          name = args[0] || File.basename(options.dir)

          lambda = Lambda.new(name)
          lambda.create(options.dir)
        end
      end

      command :update do |c|
        c.syntax = 'jarbs update [options] [name: defaults to dir specified by --dir flag]'
        c.summary = 'Update a lambda function'
        c.option "--dir STRING", String, "Path of code dir to package"
        c.action do |args, options|
          name = args[0] || File.basename(options.dir)

          lambda = Lambda.new(name)
          lambda.update(options.dir)
        end
      end

      command :rm do |c|
        c.syntax = 'jarbs rm NAME'
        c.summary = "Delete a lambda function"
        c.action do |args, options|
          lambda = Lambda.new(args[0])
          lambda.delete
        end
      end
      run!
    end
  end
end

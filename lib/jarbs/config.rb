require 'pp'

module Jarbs
  class Config
    FILE_NAME = '.jarbs'
    GLOBAL_CONFIG = File.join(Dir.home, FILE_NAME)

    def self.touch(for_global: false)
      path = for_global ? GLOBAL_CONFIG : FILE_NAME
      File.open(path, 'w') {|f| f.write JSON.pretty_generate({}) }
    end

    def self.global
      new GLOBAL_CONFIG
    end

    def initialize(file=FILE_NAME)
      @file = file
      @config = read
    end

    def global
      @global ||= self.class.global
    end

    def set(key, value, from_global: false)
      return global.set(key, value) if from_global

      @config[key] = value
      finalize
    end

    def get(key, from_global: false, &block)
      return global.get(key, &block) if from_global

      val = @config[key]

      if !val && block_given?
        val = yield
        set(key, val)
      end

      val
    end

    def print(for_global: false)
      return global.print if for_global

      pp @config
    end

    private

    def finalize
      File.open(@file, 'w') {|f| f.write JSON.pretty_generate(@config) }
    end

    def read
      if File.exists? @file
        JSON.parse(File.read(@file))
      else
        {}
      end
    end
  end
end

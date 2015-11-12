module Jarbs
  class Config
    FILE_NAME = '.jarbs'

    def self.touch
      File.open(FILE_NAME, 'w') {|f| f.write JSON.pretty_generate({}) }
    end

    def initialize(file=FILE_NAME)
      @file = file
      @config = read
    end

    def set(key, value)
      @config[key] = value
      finalize
    end

    def get(key, &block)
      val = @config[key]

      if !val && block_given?
        val = yield
        set(key, val)
      end

      val
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

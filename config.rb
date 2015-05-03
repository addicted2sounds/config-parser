module Config

  class Boolean < Object
    ALLOWED_VALUES = ['true','1','yes','false','0','no']

    def self.=== val
      ALLOWED_VALUES.member? val
    end

    def self.convert val
      case val
        when 'yes','true','1'
         true
        when 'no','false','0'
         false
        else
          nil
      end
    end
  end

  class Numeric
    ALLOWED_VALUES = /^(?<num>[[:digit:].]*)$/

    def self.=== val
      !ALLOWED_VALUES.match(val).nil?
    end

    def self.convert val
      match = ALLOWED_VALUES.match(val)
      match[:num].to_f unless match.nil?
    end
  end

  class ConfigHash < Hash
    def method_missing(key)
      self[key]
    end
  end

  class Params
    def initialize(settings)
      @raw_settings = settings
      @settings = ConfigHash.new
    end

    def method_missing(key)
      @raw_settings[key].each {|k,v|
        @settings[key] = ConfigHash.new if @settings[key].nil?
        @settings[key][k] = v[:value] unless v[:value].nil?
      }
      @settings[key]
    end
  end

  class Config
    attr_reader :settings

    def initialize(filename, overrides=[])
      @filename = filename
      @overrides = overrides.map(&:to_sym)
      @settings = Hash.new
    end

    def to_s
      @settings
    end

    def method_missing(key)
      @settings[key]
    end

    def convert_value(val)
      case val
        when Boolean
          Boolean.convert val
        when Numeric
          Numeric.convert val
        else
          val
      end
    end

    def override_param(old, new)
      if new[:override].nil?
        new
      else
        if @overrides.index(new[:override].to_sym).nil?
          old
        else
          if old[:override].nil?
            new
          else
            (@overrides.index(new[:override].to_sym) > @overrides.index(old[:override].to_sym)) ? new : old
          end
        end
      end
    end

    def load
      current_section = @settings
      File.open(@filename).each { |row|
        match = row.match(/^\[(?<section>.+)\]$/)
        unless match.nil?
          current_section = @settings[match[:section].to_sym] = Hash.new
          next
        end
        param = parse_row(row)
        current_section.merge!(param) { |k, old, new|
          override_param old,new
        } unless param.nil?
      }
      @settings
    end

    def parse_row(line)
      match = line.split(';')[0].match(
          /^\s*(?<name>.*?)(?:<(?<override>.*)>)?\s*=\s*(?<val>.*)\s*$/
      )
      unless match.nil?
        str = match[:val].match /^[“|"|'](?<string>.*)[”|"|']$/
        value = str.nil? ? match[:val].split(',').map {|v| convert_value v } : str[:string]
        {
          match[:name].to_sym => {
            value: (value.length == 1) ? value[0] : value,
            override: match[:override],
          }
        }
      end
    end
  end
end

def load_config(filename, overrides=[])
  Config::Params.new Config::Config.new(filename, overrides).load
end
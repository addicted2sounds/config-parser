# Patch Hash for properties for 'dot' access
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

    def override_param(param, existing)

    end

    def load
      current_section = @settings
      File.open(@filename).each { |row|
        match = row.match(/^\[(.+)\]$/)
        unless match.nil?
          current_section = @settings[match[1]] = Hash.new
          next
        end
        param = parse_row(row)
        # param[:override] unless param.nil?
        current_section.merge!(param) { |k, old, new|
          if new[:override].nil?
           new
          else
            if @overrides.index(new[:override].to_sym).nil?
              p @overrides, new[:override] + 'index not present'
              old
            else
              if old[:override].nil?
                new
              else
                (@overrides.index(new[:override].to_sym) > @overrides.index(old[:override].to_sym)) ? new : old
              end
            end
          end
        } unless param.nil?
      }
      @settings
    end

    def parse_row(line)
      match = line.split(';')[0].match(
          /^\s*(?<name>.*?)(?:<(?<override>.*)>)?\s*=\s*(?<val>.*)\s*$/
      )
      unless match.nil?
        value = match[:val].split(',').map {|v| convert_value v }
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
  config = File.exist?(filename) ? Config::Config.new(filename, overrides) : Hash.new
  config.load filename
end
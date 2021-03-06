require 'rspec'
require './config.rb'

FILENAME = './example.conf'

describe Config do

  let(:config) { Config::Config.new(FILENAME, ['ubuntu', :production]) }

  it 'should load file values' do
    config = load_config FILENAME, ['ubuntu', :production]
    p config.ftp.name
  end

  describe '.convert_value' do
    context 'boolean' do
      it 'should parse "no" as false' do
        expect(config.convert_value('no')).to be false
      end
      it 'should parse "false" as false' do
        expect(config.convert_value('false')).to be false
      end
      it 'should parse "0" as false' do
        expect(config.convert_value('0')).to be false
      end
      it 'should parse "yes" as true' do
        expect(config.convert_value('yes')).to be true
      end
      it 'should parse "1" as true' do
        expect(config.convert_value('1')).to be true
      end
      it 'should parse "true" as true' do
        expect(config.convert_value('true')).to be true
      end
    end
    context 'numeric' do
      it 'should convert int values' do
        expect(config.convert_value('12')).to eq 12
      end
      it 'should convert partial numbers' do
        expect(config.convert_value '1.2').to eq 1.2
      end
      it 'should return string for invalid numbers' do
        expect(config.convert_value '1a2d').to eq '1a2d'
      end
    end
  end

  describe '.parse_row' do
    context 'valid line' do
      let(:line) { 'path<staging> = /srv/uploads/; This is another comment' }
      subject(:settings) { config.parse_row line }

      it { is_expected.to have_key :path }
      it { expect(settings[:path]).to have_key :override }
      it { expect(settings[:path]).to have_key :value }
      it 'value should be string' do
        expect(settings[:path][:value]).to be_a_kind_of String
      end
    end
  end
end


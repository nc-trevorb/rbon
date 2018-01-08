require 'spec_helper'

describe 'Json types' do
  let(:all_types) { }

  describe '#default' do
    context 'for value types' do
      it 'should be configured' do
        {
          JsonNumber => 1,
          JsonString => 'something',
          JsonBool => true,
          JsonNull => nil,
        }.each do |type, default_value|
          expect(type.default).to eq(default_value)
        end
      end
    end

    context 'for collection types' do
      it 'should be an empty object' do
        expect(JsonArray.get_schema_value(value: [])).to eq([])
        expect(JsonObject.get_schema_value(value: {})).to eq({})
      end
    end
  end

  describe '#schema_type' do
    it 'should always return a string' do
      {
        JsonNumber => 'number',
        JsonString => 'string',
        JsonBool => 'boolean',
        JsonNull => '(null)', # FIXME figure out what this should really be
        JsonObject => 'object',
        JsonArray => 'array',
      }.each do |type, schema_type|
        expect(type.schema_type).to eq(schema_type)
      end
    end
  end

  describe '#other_schema_fields' do
    it 'should be nil for value types' do
      [
        JsonNumber,
        JsonString,
        JsonBool,
        JsonNull,
      ].each do |type|
        expect(type.other_schema_fields).to be(nil)
      end
    end

    it 'should recurse into items for JsonArrays' do
      expect(JsonArray.other_schema_fields(value: [])).to eq({ items: {} })
      expect(JsonArray.other_schema_fields(value: [1,2,3])).to eq({ items: { type: 'number' } })
      expect(JsonArray.other_schema_fields(value: ['a','s','d','f'])).to eq({ items: { type: 'string' } })
    end

    it 'should recurse into items for JsonObjects' do
      expect(JsonObject.other_schema_fields(value: {})).to eq({ properties: {} })
      expect(JsonObject.other_schema_fields(value: { a: 1 })).to eq({ properties: { a: { type: 'number' }}})
      expect(JsonObject.other_schema_fields(value: { a: 'bla' })).to eq({ properties: { a: { type: 'string' }}})
      expect(JsonObject.other_schema_fields(value: { a: nil })).to eq({ properties: { a: {}}})
    end
  end


  #   describe '#schema_value' do
  #     it 'raises an error when the value is missing or not the correct type' do
  #       expect { JsonObject.get_schema_value }.to raise_error(StandardError)
  #       expect { JsonArray.get_schema_value }.to raise_error(StandardError)

  #       expect { JsonObject.get_schema_value(value: nil) }.to raise_error(StandardError)
  #       expect { JsonArray.get_schema_value(value: nil) }.to raise_error(StandardError)

  #       expect { JsonObject.get_schema_value(value: false) }.to raise_error(StandardError)
  #       expect { JsonArray.get_schema_value(value: false) }.to raise_error(StandardError)
  #     end

  #     it 'returns the schema for collections' do
  #       expect(JsonArray.get_schema_value(value: [JsonValue.new(1)])).to eq(['number'])
  #     end

  #     xit 'should be based on the elements in the collection' do
  #       expect(JsonArray.schema_value(raw_value: ['asdf'])).to eq('<>string')
  #       expect(JsonArray.schema_value(raw_value: [1])).to eq('<>number')
  #     end
  #   end
  # end

  describe '#get_swagger_lines' do
    context 'for a JsonObject' do
      def swagger_for_hash(h, opts={})
        depth = opts[:depth] || ''
        json_object = JsonValue.build(h)

        json_object.get_swagger_lines(key: 'Indentation', depth: depth)
      end

      it 'should start with two space indent' do
        swag = swagger_for_hash({a: 1})

        expect(swag).to include(<<SWAG.chomp)
  type: object
  properties:
    a:
      type: number
SWAG
      end

      it 'should build any depth' do
        swag = swagger_for_hash({a: 1}, {depth: '  '})

        expect(swag).to include(<<SWAG.chomp)
    type: object
    properties:
      a:
        type: number
SWAG
      end

      it 'should indent nested objects' do
        swag = swagger_for_hash({a: {b: 'x'}}, {depth: '  '})

        expect(swag).to include(<<SWAG.chomp)
    type: object
    properties:
      a:
        type: object
        properties:
          b:
            type: string
SWAG
      end
    end
  end
end

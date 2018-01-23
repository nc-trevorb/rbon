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
        expect(JsonArray.default).to eq([])
        expect(JsonObject.default).to eq({})
      end
    end
  end

  describe '#schema_type' do
    it 'should always return a string' do
      {
        JsonNumber => 'number',
        JsonString => 'string',
        JsonBool => 'boolean',
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
        expect(type.other_schema_fields).to eq({})
      end
    end

    it 'should recurse into items for JsonArrays' do
      [
        [[],                { items: {} }],
        [[1,2,3],           { items: { type: 'number' } }],
        [['a','s','d','f'], { items: { type: 'string' } }],
      ].each do |value, expected|
        val = JsonValue.new(value).value
        expect(JsonArray.other_schema_fields(value: val)).to eq(expected.indifferent)
      end
    end

    it 'should recurse into items for JsonObjects' do
      [
        [{}, { properties: {} }],
        [{ a: 1 }, { properties: { a: { type: 'number' }}}],
        [{ a: 'bla' }, { properties: { a: { type: 'string' }}}],
        # FIXME specs for nulls
        # [{ a: nil }, { properties: { a: {}}}],
      ].each do |value, expected|
        val = JsonValue.new(value).value
        expect(JsonObject.other_schema_fields(value: val)).to eq(expected.indifferent)
      end
    end
  end


  describe '#get_swagger_lines' do
    context 'for a JsonObject' do
      def swagger_for_hash(h, opts={})
        depth = opts[:depth] || ''
        json_object = JsonValue.new(h)

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

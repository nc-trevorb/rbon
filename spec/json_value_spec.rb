require 'spec_helper'

describe JsonValue do
  type_to_value = {
    JsonNull => nil,
    JsonBool => false,
    JsonNumber => 3,
    JsonString => 'asdf',
    JsonObject => {},
    JsonArray => [],
  }

  describe 'to_json_schema' do
    type_to_value.each do |json_type, value|
      context "for a #{json_type}" do
        let(:json_schema) { JsonValue.new(value).to_json_schema }

        it "should always return a HashWithIndifferentAccess with a 'type' key" do
          expect(json_schema).to be_a(HashWithIndifferentAccess)
          expect(json_schema[:type]).not_to be(nil)
          expect(json_schema[:type]).to eq(json_schema['type'])
          expect(json_schema[:type]).to eq(json_type.schema_type)
        end
      end
    end

    {
      JsonNull => nil,
      JsonBool => false,
      JsonNumber => 3,
      JsonString => 'asdf',
    }.each do |type, value|
      context "for value types" do
        let(:json_schema) { JsonValue.new(value).to_json_schema }

        it "should not have properties" do # FIXME probably won't always be true
          expect(json_schema[:properties]).to be(nil)
        end
      end
    end

    context "for JsonArray types" do
      let(:json_schema) { JsonValue.new([1,2,3]).to_json_schema }

      it "should have items" do
        expect(json_schema[:items]).not_to be(nil)
      end
    end

    context "for JsonObject types" do
      let(:json_schema) { JsonValue.new({ a: 1 }).to_json_schema }

      it "should have properties" do
        expect(json_schema[:properties]).not_to be(nil)
      end
    end
  end

  describe 'creating from raw values' do
    type_to_value.each do |json_type, value|
      it "should infer the type for #{value} as #{json_type}" do
        json_value = JsonValue.new(value)
        expect(json_value.type).to eq(json_type)
      end
    end

    it 'should not recurse into objects' do
      arg = { a: 'asdf' }.with_indifferent_access
      expect(JsonValue.new(arg).value).to eq(arg)
    end
  end

  describe "building values" do
    it "should recurse into objects to create more JsonValues" do
      arg = { a: 'asdf' }.with_indifferent_access
      expect(JsonValue.build(arg).value.values.first).to be_a(JsonValue)
    end
  end

  describe "JsonValue#schema_value" do
    describe "should convert raw primitives to schema types" do
      [
        [JsonString, 'asdf', 'string'],
        [JsonNumber, 5, 'number'],
      ].each do |json_type, raw, expected_schema_value|
        it "should convert a #{json_type} to '#{expected_schema_value}'" do
          json_value = JsonValue.new(raw)

          expect(json_value.type).to eq(json_type)
          expect(json_value.schema_value).to eq(expected_schema_value)
        end
      end
    end

    describe "should parse an array into alphabetized types" do
      {
        'for an empty array' =>
          [[], []],

        'for an array with numbers' =>
          [[1, 2], ['number']],

        'for an array with strings' =>
          [['asdf', 'jkl'], ['string']],

        'for an array with mixed types' =>
          [[1, 'jkl'], ['number','string']],

        'for an array with mixed types in the other order' =>
          [['jkl', 1], ['number','string']],

        'for nested arrays' =>
          [[['asdf'], [1]], [['number'],['string']]],

        'for arrays with objects' =>
          [[{ a: 1 }], [{'a' => 'number'}]],

        'for arrays with multiple objects' =>
          [[{ a: 1 }, { b: 'asdf' }], [{'a' => 'number'}, {'b' => 'string' }]],
      }.each do |should, (raw, expected_schema_value)|
        it should do
          expect(JsonValue.build(raw).schema_value).to eq(expected_schema_value)
        end
      end
    end

    describe "should convert a top-level object to a hash" do
      {
        'for an empty object' =>
          [{}, {}],

        'for an object with a primitive value' =>
          [{ a: 1 }, { a: 'number' }],

        'for an object with an array value' =>
          [{ a: ['asdf'] }, { a: ['string'] }],

        'for nested objects' =>
          [{ a: { b: 'asdf' }}, { a: { b: 'string' }}],

        'should handle nested objects in arrays' =>
          [{ a: [{ b: 'asdf' }, { c: 1 }]}, { a: [{ b: 'string' }, { c: 'number' }] }],

        'should handle deeply-nested objects' =>
          [{ a: { b: { c: 'asdf' }}}, { a: { b: { c: 'string' }}}],

        'should handle any object' =>
          [{ a: { b: 'asdf', c: 1 }}, { a: { b: 'string', c: 'number' }}],
      }.each do |should, (raw, expected_schema_value)|
        it should do
          expect(JsonValue.build(raw).schema_value).to eq(expected_schema_value.with_indifferent_access)
        end
      end
    end
  end
end

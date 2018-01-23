require 'spec_helper'

describe Combine do
  let(:combine) { described_class.new }

  describe "#two_schemas" do
    context "for identical schemas" do
      [
        ['a', 'b'],
        [1, 2],
        [{ a: 1 }, { a: 2 }],
        [[1], [2]],
        [[{ a: 'asdf' }], [{ a: 'jkl' }]],
      ].each do |a, b|
        it "should return them" do
          schema_a = Convert.json_to_schema(a)
          schema_b = Convert.json_to_schema(b)
          combined = combine.two_schemas(schema_a, schema_b)

          expect(combined).to eq(schema_a)
          expect(combined).to eq(schema_b)
        end
      end
    end

    context "for different types" do
      it "should list the type as an array" do
        schema_a = { type: 'number' }.indifferent
        schema_b = { type: 'string' }.indifferent
        combined = combine.two_schemas(schema_a, schema_b)

        expect(combined[:type]).to include('number')
        expect(combined[:type]).to include('string')
      end

      context "when one type is already an array" do
        it "should add the new type" do
          schema_a = { type: ['number', 'boolean'] }.indifferent
          schema_b = { type: 'string' }.indifferent
          combined = combine.two_schemas(schema_a, schema_b)

          expect(combined[:type]).to include('number')
          expect(combined[:type]).to include('string')
          expect(combined[:type]).to include('boolean')
        end
      end
    end

    context "for different items" do
      it "should allow the array to be heterogenous" do
        schema_a = Convert.json_to_schema(['a'])
        schema_b = Convert.json_to_schema([1])
        combined = combine.two_schemas(schema_a, schema_b)
        type = combined[:items][:type]

        expect(combined[:type]).to eq('array')
        expect(type).to include('string')
        expect(type).to include('number')
      end
    end

    context "for different properties" do
      context "for compatible schemas" do
        it "should merge the properties" do
          schema_a = Convert.json_to_schema({ a: 1 })
          schema_b = Convert.json_to_schema({ a: 2, b: 3 })
          combined = combine.two_schemas(schema_a, schema_b)
          properties = combined[:properties]

          expect(combined).to eq(schema_b)
        end
      end

      context "for conflicting schemas" do
        it "should list nested types as arrays" do
          schema_a = Convert.json_to_schema({ a: 1 })
          schema_b = Convert.json_to_schema({ a: 'asdf' })
          combined = combine.two_schemas(schema_a, schema_b)
          nested_type = combined[:properties][:a][:type]

          expect(combined[:type]).to eq('object')
          expect(nested_type).to include('string')
          expect(nested_type).to include('number')
        end
      end
    end
  end
end
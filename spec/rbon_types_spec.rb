require 'spec_helper'

describe 'Rbon types' do
  let(:all_types) { }

  describe '#default' do
    context 'for primitive types' do
      it 'should be configured' do
        {
          RbonNumber => 1,
          RbonString => 'something',
          RbonBool => true,
          RbonNull => nil,
        }.each do |type, default_value|
          expect(type.default).to eq(default_value)
        end
      end
    end

    context 'for collection types' do
      it 'should recurse into its value and use the children collection types' do
        expect(RbonValue.create([]).default).to eq([])
        expect(RbonValue.create([50]).default).to eq([RbonNumber.default])
        expect(RbonValue.create(['asdf']).default).to eq([RbonString.default])

        expect(RbonValue.create({}).default).to eq({})
        expect(RbonValue.create({ a: 50 }).default).to eq({ a: RbonNumber.default }.indifferent)
        expect(RbonValue.create({ a: 'hi' }).default).to eq({ a: RbonString.default }.indifferent)
      end

      it 'should deeply recurse' do
        rbon = RbonValue.create({ a: { aa: 5 }, b: ['asdf'] })
        expected = {
          a: {
            aa: RbonNumber.default,
          },
          b: [RbonString.default],
        }.indifferent

        expect(rbon.default).to eq(expected)
      end
    end
  end

  describe '#schema_type' do
    it 'should return a string for non-null values' do
      {
        RbonNumber => 'number',
        RbonString => 'string',
        RbonBool => 'boolean',
        RbonObject => 'object',
        RbonArray => 'array',
      }.each do |type, schema_type|
        expect(type.schema_type).to eq(schema_type)
      end
    end

    it 'should raise an error for RbonNulls because the json_schema should be an empty object' do
      expect { RbonNull.schema_type }.to raise_error(StandardError)
    end
  end

  describe '#other_schema_fields' do
    it 'should be nil for value types' do
      [
        1,
        'asdf',
        true,
        nil,
      ].each do |value|
        fields = RbonValue.create(value).other_schema_fields
        expect(fields).to eq({})
      end
    end

    it 'should recurse into items for RbonArrays' do
      [
        [[],                { items: {} }],
        [[1,2,3],           { items: { type: 'number' } }],
        [['a','s','d','f'], { items: { type: 'string' } }],
      ].each do |raw_value, expected|
        fields = RbonValue.create(raw_value).other_schema_fields
        expect(fields).to eq(expected.indifferent)
      end
    end

    it 'should recurse into items for RbonObjects' do
      [
        [{}, { properties: {} }],
        [{ a: 1 }, { properties: { a: { type: 'number' }}}],
        [{ a: 'bla' }, { properties: { a: { type: 'string' }}}],
        # FIXME specs for nulls
        # [{ a: nil }, { properties: { a: {}}}],
      ].each do |raw_value, expected|
        fields = RbonValue.create(raw_value).other_schema_fields
        expect(fields).to eq(expected.indifferent)
      end
    end
  end
end

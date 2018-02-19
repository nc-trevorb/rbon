require 'spec_helper'

describe Convert do
  let(:json) do
    {
      k_string: 'hi',
      k_number: 1,
      k_array_of_numbers: [1,2,3],
      k_object: {
        string_in_object: 'asdf',
      },
      k_array_of_objects: [{ string_in_object_in_array: 'blah' }],
    }
  end
  let(:rbon) { convert.json_to_rbon(json) }
  let(:json_schema) { rbon.to_json_schema }
  let(:json_paths) { convert.json_schema_to_json_paths(json_schema) }

  let(:convert) { described_class }

  context "hashes with integer keys (e.g. allocations)" do
    it "compacts them with a key of '<id>'" do
      skip "add specs for custom names"
      paths = convert.json_to_paths({ a: { '30' => 2, '31' => 6 }})
      expect(paths).to include('a/<id>:number')
    end
  end

  describe "#json_to_rbon" do
    def assert_json_type(jr, type)
      expect(jr).to be_a(RbonValue)
      expect(jr.class).to eq(type)
    end

    it "should build primitive rbon values" do
      RbonPrimitive.descendants.each do |type|
        rbon = convert.json_to_rbon(type.default)
        expect(rbon.class).to eq(type)
      end
    end

    it "should build collection rbon values" do
      assert_json_type(rbon, RbonObject)
    end

    it "should convert values to RbonValues" do
      assert_json_type(rbon.value[:k_string], RbonString)
      assert_json_type(rbon.value[:k_number], RbonNumber)
      assert_json_type(rbon.value[:k_array_of_numbers], RbonArray)
      assert_json_type(rbon.value[:k_object], RbonObject)
    end

    context "recursing into objects" do
      it 'recurses into arrays' do
        assert_json_type(rbon.value[:k_array_of_objects], RbonArray)
        assert_json_type(rbon.value[:k_array_of_objects].value.first, RbonObject)
        assert_json_type(rbon.value[:k_array_of_objects].value.first.value[:string_in_object_in_array], RbonString)
      end

      it 'recurses into objects' do
        assert_json_type(rbon.value[:k_object].value[:string_in_object], RbonString)
      end
    end
  end

  # FIXME probably doesn't belong in Convert specs
  describe "rbon.to_json_schema" do
    context "for non-RbonObjects" do
      it "should build the schema" do
        json.keys.each do |key|
          jr = rbon.value[key]
          js = json_schema[:properties][key]
          converted = jr.to_json_schema

          expect(converted).to eq(js)
        end
      end
    end

    context "for RbonObjects" do
      it "indifferentiates hashes" do
        json.keys.each do |key|
          expect(json_schema[key]).to eq(json_schema[key.to_s])
        end
      end

      it "should convert RbonValues to a json schema" do
        expect(json_schema).to be_a(Hash)
        expect(json_schema[:properties][:k_string][:type]).to eq('string')
        expect(json_schema[:properties][:k_number][:type]).to eq('number')

        array = json_schema[:properties][:k_array_of_numbers]
        expect(array[:type]).to eq('array')
        expect(array[:items][:type]).to eq('number')

        object = json_schema[:properties][:k_object]
        expect(object[:type]).to eq('object')
        expect(object[:properties][:string_in_object][:type]).to eq('string')

        array_of_objects = json_schema[:properties][:k_array_of_objects]
        expect(array_of_objects[:type]).to eq('array')

        object_in_array = array_of_objects[:items]
        expect(object_in_array[:type]).to eq('object')
        expect(object_in_array[:properties][:string_in_object_in_array][:type]).to eq('string')
      end

      context 'heterogenous arrays' do
        it 'merges compatible schemas into one' do
          json = { a: [{ b: 5 }, { c: 'asdf' }]}
          rbon = convert.json_to_rbon(json)
          json_schema = rbon.to_json_schema

          expect(json_schema[:properties][:a][:type]).to eq('array')
          expect(json_schema[:properties][:a][:items][:type]).to eq('object')
          expect(json_schema[:properties][:a][:items][:properties][:b][:type]).to eq('number')
          expect(json_schema[:properties][:a][:items][:properties][:c][:type]).to eq('string')
        end

        it 'lists incompatible objects as alternatives' do
          json = { a: [{ b: 5 }, { b: 'asdf' }]}
          rbon = convert.json_to_rbon(json)
          json_schema = rbon.to_json_schema

          expect(json_schema[:properties][:a][:type]).to eq('array')
          expect(json_schema[:properties][:a][:items][:type]).to eq('object')
          expect(json_schema[:properties][:a][:items][:properties][:b][:type]).to include('number')
          expect(json_schema[:properties][:a][:items][:properties][:b][:type]).to include('string')
        end
      end
    end
  end

  xdescribe '#json_schema_to_rbon' do
    context "building RbonValues" do
      context "for simple schemas" do
        [
          [{ type: 'string' }, RbonString],
          [{ type: 'number' }, RbonNumber],
          [{ type: 'boolean' }, RbonBool],
          [{}, RbonNull],
        ].each do |schema, json_type|
          it "should use the default value (#{json_type})" do
            jr = convert.json_schema_to_rbon(schema.indifferent)

            expect(jr).to be_a(RbonValue)
            expect(jr.class).to eq(json_type)
            expect(jr.value).to eq(json_type.default)
          end
        end
      end

      context "for complex schemas" do
        # FIXME these inputs only work because they use .default, would be nice to not have to do that
        [
          [{ type: 'array', items: { type: 'number' } }, [RbonNumber.default]],
          [{ type: 'object', properties: { a: { type: 'number' }, b: { type: 'string' }}}, { a: RbonNumber.default, b: RbonString.default }],
        ].each do |schema, raw|
          it 'should populate the other schema fields' do
            expected = RbonValue.create(raw)
            converted = convert.json_schema_to_rbon(schema.indifferent)

            expect(converted).to eq(expected)
          end
        end
      end
    end
  end

  describe "#rbon_to_json_paths" do
    def expect_paths(json, path)
      json_paths = convert.json_to_paths(json)
      expect(json_paths).to include(path)
    end

    it "converts primitives" do
      expect_paths(json, 'k_string:string')
      expect_paths(json, 'k_number:number')
    end

    it "converts objects" do
      expect_paths(json, 'k_object/string_in_object:string')
    end

    context "arrays" do
      it "converts homogenous lists of primitives" do
        expect_paths(json, 'k_array_of_numbers[]:number')
      end

      it "lists all types for heterogenous lists" do
        expect_paths({ k_mixed_array: ['asdf', 5]}, 'k_mixed_array[]:number')
        expect_paths({ k_mixed_array: ['asdf', 5]}, 'k_mixed_array[]:string')
      end

      it "converts homogenous arrays of objects" do
        expect_paths(json, 'k_array_of_objects[]/string_in_object_in_array:string')
      end

      it "merges arrays without conflicts" do
        expect_paths({ a: [{ b: 5 }, { c: 'asdf' }]}, 'a[]/b:number')
        expect_paths({ a: [{ b: 5 }, { c: 'asdf' }]}, 'a[]/c:string')
      end

      it "lists conflicts at the same path" do
        expect_paths({ a: [{ b: 5 }, { b: 'asdf' }]}, 'a[]/b:number')
        expect_paths({ a: [{ b: 5 }, { b: 'asdf' }]}, 'a[]/b:string')
      end
    end

    context "nested hashes" do
      let(:json_1) do
        {
          a: {
            b: 'asdf',
            c: 'asdf',
            e: 'jkl',
          }
        }
      end
      let(:json_2) do
        {
          a: {
            b: 2,
            c: 'asdf',
            d: 2,
          }
        }
      end
    end
  end
end

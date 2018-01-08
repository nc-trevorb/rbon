require 'spec_helper'

describe Convert do
  let(:convert) { described_class }
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
  let(:json_ruby) { convert.json_to_json_ruby(json) }
  let(:json_schema) { convert.json_ruby_to_json_schema(json_ruby) }
  let(:json_paths) { convert.json_schema_to_json_paths(json_schema) }

  describe "#json_to_json_ruby" do
    def assert_json_type(jr, type)
      expect(jr).to be_a(JsonValue)
      expect(jr.type).to eq(type)
    end

    it "should only accept a hash argument" do
      [1, 'asdf', []].each do |input|
        expect { convert.json_to_json_ruby(input) }.to raise_error(RuntimeError)
      end
    end

    it "should convert a hash to a JsonValue" do
      assert_json_type(json_ruby, JsonObject)
    end

    it "should convert values to JsonValues" do
      assert_json_type(json_ruby[:k_string], JsonString)
      assert_json_type(json_ruby[:k_number], JsonNumber)
      assert_json_type(json_ruby[:k_array_of_numbers], JsonArray)
      assert_json_type(json_ruby[:k_object], JsonObject)
    end

    it "indifferentiates nested hashes" do
      json_ruby = convert.json_to_json_ruby({ asdf: 'jkl' })
      assert_json_type(json_ruby['asdf'], JsonString)
    end

    context "recursing into objects" do
      it 'recurses into arrays' do
        assert_json_type(json_ruby[:k_array_of_objects], JsonArray)
        assert_json_type(json_ruby[:k_array_of_objects].value.first, JsonObject)
        assert_json_type(json_ruby[:k_array_of_objects].value.first[:string_in_object_in_array], JsonString)
      end

      it 'recurses into objects' do
        assert_json_type(json_ruby[:k_object][:string_in_object], JsonString)
      end
    end
  end

  describe "#json_ruby_to_json_schema" do
    it "should only accept a JsonObject argument" do
      [1, 'asdf', []].each do |value|
        input = JsonValue.new(value)
        expect { convert.json_ruby_to_json_schema(input) }.to raise_error(RuntimeError)
      end
    end

    it "indifferentiates hashes" do
      json.keys.each do |key|
        expect(json_schema[key]).to eq(json_schema[key.to_s])
      end
    end

    it "should convert JsonValues to a json schema" do
      expect(json_schema).to be_a(Hash)
      expect(json_schema[:k_string]).to eq('string')
      expect(json_schema[:k_number]).to eq('number')
      expect(json_schema[:k_array_of_numbers]).to eq(['number'])
      expect(json_schema[:k_object][:string_in_object]).to eq('string')
      expect(json_schema[:k_array_of_objects].first[:string_in_object_in_array]).to eq('string')
    end

    context 'collisions' do
      it 'handles different keys' do
        json = { a: [{ b: 5 }, { c: 'asdf' }]}
        json_ruby = convert.json_to_json_ruby(json)
        json_schema = convert.json_ruby_to_json_schema(json_ruby)

        expect(json_schema[:a].keys).to include('b')
        expect(json_schema[:a].keys).to include('c')
      end

      it 'handles different values' do
        # (conflicting types like `{ a: [{ b: 5 }, { b: 'asdf' }]}`)
      end
    end
  end

  describe "#json_schema_to_json_paths" do
    def get_paths(json)
      json_ruby = convert.json_to_json_ruby(json)
      json_schema = convert.json_ruby_to_json_schema(json_ruby)
      json_paths = convert.json_schema_to_json_paths(json_schema)
    end

    def expect_paths(json, path)
      json_ruby = convert.json_to_json_ruby(json)
      json_schema = convert.json_ruby_to_json_schema(json_ruby)
      json_paths = convert.json_schema_to_json_paths(json_schema)

      expect(json_paths).to include(path)
    end

    it "converts primitives" do
      expect_paths(json, 'k_string:string')
      expect_paths(json, 'k_number:number')
    end

    it "converts objects" do
      expect_paths(json, 'k_object.string_in_object:string')
    end

    context "arrays" do
      it "converts homogenous lists of primitives" do
        expect_paths(json, 'k_array_of_numbers<>:number')
      end

      it "converts heterogenous lists of primitives and sorts types" do
        expect_paths({ k_mixed_array: ['asdf', 5]}, 'k_mixed_array<>:number,string')
      end

      it "converts homogenous arrays of objects" do
        expect_paths(json, 'k_array_of_objects<>.string_in_object_in_array:string')
      end

      it "merges arrays without conflicts" do
        expect_paths({ a: [{ b: 5 }, { c: 'asdf' }]}, 'a.b:number')
        expect_paths({ a: [{ b: 5 }, { c: 'asdf' }]}, 'a.c:string')
      end

      it "labels arrays with conflicts with an <id>" do
        expect_paths({ a: [{ b: 5 }, { b: 'asdf' }]}, 'a.b_conflict_0:number')
        expect_paths({ a: [{ b: 5 }, { b: 'asdf' }]}, 'a.b_conflict_1:string')
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

      context "hashes with integer keys (e.g. allocations)" do
        it "compacts them with a key of '<id>'" do
          paths = convert.json_to_paths({ a: { '30' => 2, '31' => 6 }})
          expect(paths).to include('a.<id>:number')
        end
      end
    end
  end

  describe "#json_schema_to_json_ruby" do
    let(:converted) { convert.json_schema_to_json_ruby(json_schema) }

    it "should fill in default values" do
      skip "not ready for this yet"
      json.keys.each do |key|
        expect(converted[key]).to be_a(JsonValue)
      end

      expect(converted[:k_string].type).to eq(JsonString)
      expect(converted[:k_number].type).to eq(JsonNumber)
      expect(converted[:k_array_of_numbers].type).to eq(JsonArray)
      expect(converted[:k_object].type).to eq(JsonObject)
      expect(converted[:k_array_of_objects].type).to eq(JsonArray)
    end
  end

  describe "#json_to_swag" do
    let(:name) { "DefinitionName" }
    let(:swag) { convert.json_to_swag(json, name) }

    it "should scope everything under the json name" do
      expect(swag).to match(/^ *#{name}:/)
    end

    it "should convert primitives" do
      expect(swag).to include(<<SWAG)
    k_string:
      type: string
SWAG

      expect(swag).to include(<<SWAG)
    k_number:
      type: number
SWAG
    end

    it "should convert arrays" do
      expect(swag).to include(<<SWAG)
    k_array_of_numbers:
      type: array
      items:
        type: number
SWAG
    end

    it "should convert nested objects" do
      expect(swag).to include(<<SWAG)
    k_object:
      type: object
      properties:
        string_in_object:
          type: string
SWAG
    end

    it "should convert objects in arrays" do
      expect(swag).to include(<<SWAG.chomp)
    k_array_of_objects:
      type: array
      items:
        type: object
        properties:
          string_in_object_in_array:
            type: string
SWAG
    end
  end

  describe "#type_to_path" do
    context "for primitives" do
      it "should be easy" do
        expect(convert.type_to_path("key", "type", "prefix")).to eq("prefix.key:type")
      end
    end

    context "for arrays" do
      let(:path) { convert.type_to_path("key", type, "prefix") }

      context "with primitive types" do
        let(:type) { ['number', 'string'] }

        it "should list them with angle brackets" do
          expect(path).to include("prefix.key<>:number,string")
        end
      end

      context "with object elements" do
        context "one element" do
          let(:type) { [{ a: 'number', b: 'string' }] }

          it "should list the paths with <>" do
            expect(path).to include('prefix.key<>.a:number')
            expect(path).to include('prefix.key<>.b:string')
          end
        end

        context "homogenous (with multiple elements)" do
          let(:type) { [{ a: 'number', b: 'string' }, { a: 'number', b: 'string' }] }

          it "should list the paths with <all>" do
            expect(path).to include('prefix.key<all>.a:number')
            expect(path).to include('prefix.key<all>.b:string')
          end
        end

        context "heterogenous" do
          let(:type) { [{ a: 'number', b: 'string' }, { c: 'string', d: 'number' }] }

          it "should give each member an id" do
            expect(path).to include('prefix.key<0>.a:number')
            expect(path).to include('prefix.key<0>.b:string')
            expect(path).to include('prefix.key<1>.c:string')
            expect(path).to include('prefix.key<1>.d:number')
          end
        end
      end
    end
  end

end

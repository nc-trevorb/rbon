require 'spec_helper'

describe Combine do
  let(:agg) { described_class }

  describe "#merge_schemas" do
    let(:json_a) {{ a: 1 }}
    let(:json_b) {{ b: 'asdf' }}

    let(:schema_a) { Convert.json_to_schema(json_a) }
    let(:schema_b) { Convert.json_to_schema(json_b) }
    let(:schema_c) { Convert.json_to_schema(json_c) }

    let(:merged) { agg.merge_schemas(schema_a, schema_b, schema_c) }

    context "with no conflicts" do
      let(:json_c) do
        {
          a: 1,
          b: nil,
        }
      end

      it "should include keys from both schemas" do
        expect(merged[:a]).to eq('number')
      end

      it "should combine types when one is null" do
        expect(merged[:b]).to eq('string')
      end
    end

    context "with conflicts" do
      let(:json_c) do
        {
          a: 'no',
          b: [],
        }
      end

      it "should split type conflicts into two keys" do
        expect(merged[:a]).to be(nil)
        expect(merged[:b]).to be(nil)

        expect(merged[:a_conflict_1]).to eq('number')
        expect(merged[:a_conflict_2]).to eq('string')
        expect(merged[:b_conflict_1]).to eq('string')
        expect(merged[:b_conflict_2]).to eq([])
      end
    end
  end
end
require 'spec_helper'

describe Compare do
  let(:compare) { described_class }

  # pending until this class is actually used
  xdescribe "#diff_jsons" do
    it "should list the same paths" do
      j1 = { a: 'asdf', b: 1 }
      j2 = { a: 'jkl',  b: 'asdf' }

      expect(compare.diff_jsons(j1, j2)[:same]).to include('a:string')

      b_in_same = compare.diff_jsons(j1, j2)[:same].any? do |same_paths|
        same_paths.start_with?('b:')
      end

      expect(b_in_same).to be(false)
    end

    it "should list extra paths" do
      j1 = { a: 'asdf', b: { c: ['zxcv'] } }
      j2 = { a: 'jkl' }

      expect(compare.diff_jsons(j1, j2)[:extra]).to include('b.c<>:string')
    end

    it "should list missing paths" do
      j1 = { a: 'asdf' }
      j2 = { a: 'jkl', b: [5] }

      expect(compare.diff_jsons(j1, j2)[:missing]).to include('b<>:number')
    end

    it "should list paths with different types" do
      j1 = { a: 'asdf', b: 1 }
      j2 = { a: 5, b: 1 }

      expect(compare.diff_jsons(j1, j2)[:different_types][:a]).to eq(['number', 'string'])
    end

    it "should list paths with different nested types" do
      j1 = { a: { b: 'asdf' }, c: 1 }
      j2 = { a: { b: 5 }, c: 1 }

      expect(compare.diff_jsons(j1, j2)[:different_types]['a.b']).to eq(['number', 'string'])
    end

    it "should not consider null a distinct type" do
      j1 = { a: nil, c: 1 }
      j2 = { a: 5, c: 1 }

      expect(compare.diff_jsons(j1, j2)[:different_types].keys.map(&:to_s)).not_to include('a')
      expect(compare.diff_jsons(j1, j2)[:same]).to include('a:number')
    end
  end
end

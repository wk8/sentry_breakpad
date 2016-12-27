require 'spec_helper'

describe SentryBreakpad::HashHelper do
  describe '.deep_merge!' do
    it 'performs a deep merge' do
      hash1 = { a1: { b1: { c1: 2 }, b2: 12, b3: { c2: 42 } }, a2: { b4: 76 } }
      hash2 = { a1: { b1: { c1: 3 }, b3: { c3: 56 } }, a2: { b4: 7 } }

      expected_merged_hash = { a1: { b1: { c1: 3 }, b2: 12, b3: { c2: 42, c3: 56 } },
                               a2: { b4: 7 } }
      expect(described_class.deep_merge!(hash1, hash2)).to eq(expected_merged_hash)
    end
  end

  describe '.deep_symbolize_keys!' do
    it "recursively symbolizes a hash's keys" do
      hash = { 'coucou' => 'toi', "t'as" => { de: { beaux: 'yeux' } }, 'tu' => :sais }

      expected_result = { coucou: 'toi', :"t'as" => { de: { beaux: 'yeux' } }, tu: :sais }
      expect(described_class.deep_symbolize_keys!(hash)).to eq(expected_result)
    end
  end
end

require_relative '../spec_helper'

describe ResqueDelay::SerializedObject do
  let(:class_key) { 'CLASS:Integer' }
  let(:sym_key) { 'SYMBOL:dragon' }
  let(:str_key) { 'thing' }
  let(:date_key) { "OBJ:#{Base64.strict_encode64(Marshal.dump(Date.today))}" }
  let(:obj_key) { "OBJ:BAhJdToJVGltZQ1xIh+AZ2diIAc6C29mZnNldGn+sLk6CXpvbmVJIghDRFQG\nOgZFRg==\n" }
  
  describe '.serialize' do
    it 'works for symbols' do
      expect(described_class.serialize(:dragon)).to eq(sym_key)
    end

    it 'works for Classes' do
      expect(described_class.serialize(Integer)).to eq(class_key)
    end

    it 'works for strings' do
      expect(described_class.serialize('thing')).to eq(str_key)
    end

    it 'works for dates' do
      expect(described_class.serialize(Date.today)).to eq(date_key)
    end

    it 'works for objects' do
      d = 2.days.from_now
      str = described_class.serialize(d)
      expect(described_class.deserialize(str)).to eq(d)
    end

    it "dumps complext symbols" do
      expect(described_class.serialize(:"a totTALLY 234-thing")).to eq("SYMBOL:a totTALLY 234-thing")
    end
  end
  
  describe '.display_name' do
    it 'prints Classes' do
      expect(described_class.display_name('CLASS:Integer', :to_s)).to eq('Integer.to_s')
    end

    it 'prints symbols' do
      expect(described_class.display_name('SYMBOL:dragon', :to_s)).to eq('Symbol#to_s')
    end

    it 'prints Unknowns' do
      expect(described_class.display_name("I'm not expected", :to_s)).to eq('Unknown#to_s')
    end
  end
  
  describe '.deserialize' do
    it 'loads symbols' do
      expect(described_class.deserialize(sym_key)).to eq(:dragon)
    end

    it 'loads complex symbols' do
      expect(described_class.deserialize("SYMBOL:a totTALLY 234-thing")).to eq(:"a totTALLY 234-thing")
    end

    it 'loads Classes' do
      expect(described_class.deserialize(class_key)).to eq(Integer)
    end

    it 'loads other' do
      expect(described_class.deserialize(str_key)).to eq('thing')
    end
  end
end

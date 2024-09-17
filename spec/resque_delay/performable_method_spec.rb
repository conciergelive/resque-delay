require_relative '../spec_helper'
require 'active_record'
require 'data_mapper'
require 'mongoid'

describe 'performable_method' do
  class TheARecord < ::ActiveRecord::Base
    def play
      @played = true
    end
  end

  class TheDataMapper
    include DataMapper::Resource
    def play
      @played = true
    end
  end

  class TheMongoid 
    include Mongoid::Document
    def play
      @played = true
    end
  end

  let(:ar) {
    ar = instance_double("TheARecord")
    allow(ar).to receive(:kind_of?).and_return(false)
    allow(ar).to receive(:kind_of?).with(ActiveRecord::Base).and_return(true)
    allow(ar).to receive(:id).and_return(1)
    allow(ar).to receive(:class).and_return(TheARecord)
    ar
  }

  let(:ar_key) { 'AR:TheARecord:1' }
  let(:klass) { 3.class }
  let(:klass_key) { 'CLASS:Integer' }

  let(:dm) {
    instance_double("TheDataMapper").tap do |dm|
      allow(dm).to receive(:kind_of?).and_return(false)
      allow(dm).to receive(:kind_of?).with(DataMapper::Resource).and_return(true)
      allow(dm).to receive(:key).and_return([1,2])
      allow(dm).to receive(:class).and_return(TheDataMapper)
    end
  }

  let(:dm_key) { 'DM:TheDataMapper:1:2' }

  let(:mg) {
    instance_double("TheMongoid").tap do |mg|
      allow(mg).to receive(:kind_of?).and_return(false)
      allow(mg).to receive(:kind_of?).with(Mongoid::Document).and_return(true)
      allow(mg).to receive(:id).and_return(1)
      allow(mg).to receive(:class).and_return(TheMongoid)
    end
  } 

  let(:mg_key) {'MG:TheMongoid:1'}

  before(:each) do
    allow(TheARecord).to receive(:find).with("1").and_return(ar)
    allow(TheDataMapper).to receive('get!'.to_sym).with("1","2").and_return(dm)
    allow(TheMongoid).to receive(:find).with("1").and_return(mg)
  end

  describe '.perform' do
    it 'executes AR methods' do
      pm = ResqueDelay::PerformableMethod.new(ar, :play, [], nil, nil)
      expect(ar).to receive(:play)
      pm.perform
    end

    it 'executes DM methods' do
      pm = ResqueDelay::PerformableMethod.new(dm, :play, [], nil, nil)
      expect(dm).to receive(:play)
      pm.perform
    end

    it 'executes Class methods' do
      pm = ResqueDelay::PerformableMethod.new(klass, :to_s, [], nil, nil)
      expect(klass).to receive(:to_s)
      pm.perform
    end

    it 'eats ActiveRecord::NotFound exceptions' do
      pm = ResqueDelay::PerformableMethod.new(ar, :play, [], nil, nil)
      expect(ar).to receive(:play).and_raise(ActiveRecord::RecordNotFound)
      pm.perform
    end

    it 'does NOT eat exceptions other than ActiveRecord::NotFound' do
      expect do
        pm = ResqueDelay::PerformableMethod.new(ar, :play, [], nil, nil)
        expect(ar).to receive(:play).and_raise(::RuntimeError)
        pm.perform
      end.to raise_error(::RuntimeError)
    end
  end
end

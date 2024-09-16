require_relative './spec_helper'
require 'resque-delay'

describe "resque" do
  context 'delay' do
    class FairyTale
      attr_accessor :happy_ending
      def self.princesses; end
      def self.ending(which: :happy); end
    end

    before do
      Resque.queues.each{|q| Resque.redis.del "queue:#{q}" } #Empty all queues
      Resque.remove_delayed_selection do true end #Remove all delayed jobs
    end

    it 'creates a new PerformableMethod job' do
      expect do
        job = 'hello'.delay.count('l')
        expect(job.class).to eq(ResqueDelay::PerformableMethod)
        expect(job.method).to eq(:count)
        expect(job.args).to eq(['l'])
      end.to change { Resque.info[:pending] }.by(1)
    end

    it 'has kwargs' do
      expect do
        job = FairyTale.delay.ending
        expect(job.class).to eq(ResqueDelay::PerformableMethod)
        expect(job.method).to eq(:ending)
        expect(job.args).to eq([])
        expect(job.kwargs).to eq({})
      end.to change { Resque.info[:pending] }.by(1)
    end

    it 'saves kwargs when set' do
      expect do
        job = FairyTale.delay.ending(which: :sad)
        expect(job.class).to eq(ResqueDelay::PerformableMethod)
        expect(job.method).to eq(:ending)
        expect(job.args).to eq([])
        expect(job.kwargs).to eq({ which: :sad })
      end.to change { Resque.info[:pending] }.by(1)
    end

    it 'sets default queue name' do
      job = FairyTale.delay(to: 'abbazabba').to_s
      expect(job.queue).to eq('abbazabba')
    end

    it 'sets job in the future' do
      expect do
        run_in = 1 * 3600 * 24
        job = FairyTale.delay(in: run_in).to_s
        expect(job.run_in).to eq(run_in)
      end.to change { Resque.delayed_queue_schedule_size }.by(1)
    end

    it 'fails if in option is not valid' do
      expect do
        job = FairyTale.delay(in: 'I will fail').to_s
      end.to raise_error(::ArgumentError)
    end
  end

  describe 'self.perform' do
    it 'sends perform when argument responds to :[]' do
      obj = "hello"
      expect(obj).to receive(:to_s)
      ResqueDelay::DelayProxy.perform({ 'object' => obj, 'method' => :to_s, 'args' => [], 'kwargs' => {}})
    end

    it 'sends keyword arguments' do
      expect(FairyTale).to receive(:ending).with(which: :sad)
      ResqueDelay::DelayProxy.perform({ 'object' => FairyTale, 'method' => :ending, 'args' => [], 'kwargs' => { which: :sad }})
    end

    it 'sends perform when argument does NOT respond to :[]' do
      obj = "hello"
      args = [obj, :to_s, [], nil, nil]
      expect(obj).to receive(:to_s)
      expect(args).to receive('respond_to?').with(:[]).and_return(false)
      ResqueDelay::DelayProxy.perform(args)
    end
  end
end

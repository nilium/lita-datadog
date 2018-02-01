require 'spec_helper'

describe Lita::Handlers::Datadog, lita_handler: true do
  EXAMPLE_IMAGE_URL     = 'http://www.example.com/path/that/ends/in.png'.freeze
  EXAMPLE_ERROR_MSG     = 'Error making DataDog request'.freeze
  EXAMPLE_BAD_QUERY_MSG = ':failed: No query given'.freeze

  let(:success) do
    client = double
    allow(client).to receive(:graph_snapshot) {
      [200, { 'snapshot_url' => EXAMPLE_IMAGE_URL }]
    }
    allow(client).to receive(:mute_host) {
      [200, { 'hostname' => 'host01' }]
    }
    allow(client).to receive(:unmute_host) {
      [200, { 'hostname' => 'host01' }]
    }
    allow(client).to receive(:search).with(/^hosts:/) {
      [200, { 'results' => { 'hosts' => %w[host-01 host-02 host-03] } }]
    }
    allow(client).to receive(:search).with(/^metrics:/) {
      [200, { 'results' => { 'metrics' => %w[test.metric] } }]
    }
    client
  end

  let(:error) do
    client = double
    allow(client).to receive(:graph_snapshot) { [500, { 'errors' => ['foo'] }] }
    allow(client).to receive(:mute_host) { [500, { 'errors' => ['foo'] }] }
    allow(client).to receive(:unmute_host) { [500, { 'errors' => ['foo'] }] }
    client
  end

  it do
    is_expected.to route_command(
      'dd graph metric:"system.load.1{*}"')
      .to(:graph)
    is_expected.to route_command(
      'dd graph metric:"system.load.1{host:hostname01}"')
      .to(:graph)
    is_expected.to route_command(
      'dd graph metric:"system.load.1{*},system.load.5{*}"')
      .to(:graph)
    is_expected.to route_command(
      'dd graph metric:"system.load.1{*}" event:"sources:something"')
      .to(:graph)

    is_expected.to route_command('dd hosts host01').to(:hosts)
    is_expected.to route_command('dd   hosts    host-2').to(:hosts)
    is_expected.to route_command('dd hosts').to(:hosts)

    is_expected.to route_command('dd metrics test').to(:metrics)
    is_expected.to route_command('dd   metrics    test').to(:metrics)
    is_expected.to route_command('dd metrics').to(:metrics)

    is_expected.to route_command('dd mute host01').to(:mute)
    is_expected.to route_command('dd mute host01 message:"Foo Bar"').to(:mute)
    is_expected.to route_command('dd unmute host01').to(:unmute)
  end

  describe '#hosts' do
    it 'with valid query returns a list of zero or more hosts' do
      expect(Dogapi::Client).to receive(:new) { success }
      send_command('dd hosts host')
      expect(replies.last).to eq("Hosts found:\n- host-01\n- host-02\n- host-03")
    end

    it 'with empty query returns an error' do
      send_command('dd hosts   ')
      expect(replies.last).to eq(EXAMPLE_BAD_QUERY_MSG)
    end
  end

  describe '#metrics' do
    it 'with valid query returns a list of zero or more metrics' do
      expect(Dogapi::Client).to receive(:new) { success }
      send_command('dd metrics test')
      expect(replies.last).to eq("Metric found:\n- test.metric")
    end

    it 'with empty query returns an error' do
      send_command('dd metrics')
      expect(replies.last).to eq(EXAMPLE_BAD_QUERY_MSG)
    end
  end

  describe '#graph' do
    it 'with valid metric returns an image url' do
      expect(Dogapi::Client).to receive(:new) { success }
      send_command('dd graph metric:"system.load.1{*}"')
      expect(replies.last).to eq(EXAMPLE_IMAGE_URL)
    end

    it 'with invalid metric returns an error' do
      expect(Dogapi::Client).to receive(:new) { error }
      send_command('dd graph metric:"omg.wtf.bbq{*}"')
      expect(replies.last).to eq(EXAMPLE_ERROR_MSG)
    end

    it 'with valid metric and event returns an image url' do
      expect(Dogapi::Client).to receive(:new) { success }
      send_command('dd graph metric:"system.load.1{*}"')
      expect(replies.last).to eq(EXAMPLE_IMAGE_URL)
    end

    it 'with an invalid metric returns an error' do
      expect(Dogapi::Client).to receive(:new) { error }
      send_command('dd graph metric:"omg.wtf.bbq{*}" event:"sources:sourcename"')
      expect(replies.last).to eq(EXAMPLE_ERROR_MSG)
    end

    it 'with an invalid event returns an error' do
      expect(Dogapi::Client).to receive(:new) { error }
      send_command('dd graph metric:"system.load.1{*}" event:"omg:wtf"')
      expect(replies.last).to eq(EXAMPLE_ERROR_MSG)
    end
  end

  describe '#mute' do
    it 'mutes a hostname' do
      expect(Dogapi::Client).to receive(:new) { success }
      send_command('dd mute host01')
      expect(replies.last).to eq('Host host01 muted')
    end

    it 'mutes a hostname with a message' do
      expect(Dogapi::Client).to receive(:new) { success }
      send_command('dd mute host01 message:"Foo Bar"')
      expect(replies.last).to eq('Host host01 muted')
    end

    it 'reports an error if there was a problem with the request' do
      expect(Dogapi::Client).to receive(:new) { error }
      send_command('dd mute host01')
      expect(replies.last).to eq(EXAMPLE_ERROR_MSG)
    end
  end

  describe '#unmute' do
    it 'unmutes a hostname' do
      expect(Dogapi::Client).to receive(:new) { success }
      send_command('dd unmute host01')
      expect(replies.last).to eq('Host host01 unmuted')
    end

    it 'reports an error if there was a problem with the request' do
      expect(Dogapi::Client).to receive(:new) { error }
      send_command('dd unmute host01')
      expect(replies.last).to eq(EXAMPLE_ERROR_MSG)
    end
  end
end

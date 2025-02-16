require 'rails_helper'
require_relative '../../app/models/expertiza_logger'

RSpec.describe ExpertizaLogFormatter do
  let(:formatter) { ExpertizaLogFormatter.new }
  let(:timestamp) { Time.now }
  let(:severity) { 'INFO' }
  let(:progname) { 'Expertiza' }

  context 'when the message is a plain string' do
    let(:message) { 'Test message with more text' }

    it 'formats the message correctly' do
      formatted_message = formatter.call(severity, timestamp, progname, message)
      expect(formatted_message).to include("TST=[#{timestamp}] SVT=[#{severity}] PNM=[#{progname}] OIP=[] RID=[] CTR=[] UID=[] MSG=[Test message with more text]")
    end
  end

  context 'when the message is a plain string with newline' do
    let(:message) { "Test message with newline\nto more text" }

    it 'formats the message correctly' do
      formatted_message = formatter.call(severity, timestamp, progname, message)
      expect(formatted_message).to include("TST=[#{timestamp}] SVT=[#{severity}] PNM=[#{progname}] OIP=[] RID=[] CTR=[] UID=[] MSG=[Test message with newline to more text]")
    end
  end

  context 'when the message is a LoggerMessage object' do
    let(:logger_message) do
      LoggerMessage.new('gen1', 'unityid1', 'Test message')
    end

    it 'formats the message correctly' do
      formatted_message = formatter.call(severity, timestamp, progname, logger_message)
      expect(formatted_message).to include("TST=[#{timestamp}] SVT=[#{severity}] PNM=[#{progname}] OIP=[] RID=[] CTR=[gen1] UID=[unityid1] MSG=[Test message]")
    end
  end

  context 'when the message is a LoggerMessage object with request' do
    let(:logger_message) do
      LoggerMessage.new('gen1', 'unityid1', 'Test message', double("request", remote_ip: "192.168.1.1", uuid: "12345"))
    end

    it 'formats the message correctly' do
      formatted_message = formatter.call(severity, timestamp, progname, logger_message)
      expect(formatted_message).to include("TST=[#{timestamp}] SVT=[#{severity}] PNM=[#{progname}] OIP=[192.168.1.1] RID=[12345] CTR=[gen1] UID=[unityid1] MSG=[Test message]")
    end
  end
end

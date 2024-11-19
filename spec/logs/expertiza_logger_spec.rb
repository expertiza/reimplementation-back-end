RSpec.describe ExpertizaLogger do
  let(:message) { 'Test message' }
  let(:timestamp) { Time.now }

  # Create a mock logger instance
  let(:mock_logger) { instance_double(Logger) }

  before do
    allow(Logger).to receive(:new).and_return(mock_logger)
    allow(mock_logger).to receive(:formatter)
    allow(mock_logger).to receive(:formatter=).with(an_instance_of(ExpertizaLogFormatter))
    allow(mock_logger).to receive(:info)
    allow(mock_logger).to receive(:warn)
    allow(mock_logger).to receive(:error)
    allow(mock_logger).to receive(:fatal)
    allow(mock_logger).to receive(:debug)
  end

  describe '.info' do
    it 'logs the message to the correct file with info severity' do
      ExpertizaLogger.info(message)
      expect(Logger).to have_received(:new).with(Rails.root.join('log', 'expertiza_info.log'))
      expect(mock_logger).to have_received(:formatter=).with(an_instance_of(ExpertizaLogFormatter))
      expect(mock_logger).to have_received(:info).with(message)
    end
  end

  describe '.warn' do
    it 'logs the message to the correct file with warn severity' do
      ExpertizaLogger.warn(message)
      expect(Logger).to have_received(:new).with(Rails.root.join('log', 'expertiza_warn.log'))
      expect(mock_logger).to have_received(:formatter=).with(an_instance_of(ExpertizaLogFormatter))
      expect(mock_logger).to have_received(:warn).with(message)
    end
  end

  describe '.error' do
    it 'logs the message to the correct file with error severity' do
      ExpertizaLogger.error(message)
      expect(Logger).to have_received(:new).with(Rails.root.join('log', 'expertiza_error.log'))
      expect(mock_logger).to have_received(:formatter=).with(an_instance_of(ExpertizaLogFormatter))
      expect(mock_logger).to have_received(:error).with(message)
    end
  end

  describe '.fatal' do
    it 'logs the message to the correct file with fatal severity' do
      ExpertizaLogger.fatal(message)
      expect(Logger).to have_received(:new).with(Rails.root.join('log', 'expertiza_fatal.log'))
      expect(mock_logger).to have_received(:formatter=).with(an_instance_of(ExpertizaLogFormatter))
      expect(mock_logger).to have_received(:fatal).with(message)
    end
  end

  describe '.debug' do
    it 'logs the message to the correct file with debug severity' do
      ExpertizaLogger.debug(message)
      expect(Logger).to have_received(:new).with(Rails.root.join('log', 'expertiza_debug.log'))
      expect(mock_logger).to have_received(:formatter=).with(an_instance_of(ExpertizaLogFormatter))
      expect(mock_logger).to have_received(:debug).with(message)
    end
  end
end

class BaseCommand
  attr_reader :result

  def self.call(*args)
    new(*args).call
  end

  def call
    @result = nil
    payload
    self
  end

  private

  def initialize(*_)
  end

  def payload
  end
end

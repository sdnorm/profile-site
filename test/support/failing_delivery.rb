# Mail interceptor that makes delivery raise, to exercise "couldn't send" paths
# through real ActionMailer hooks rather than mocks. Register it inside a test
# and unregister it in an ensure block.
class FailingDelivery
  def self.delivering_email(_message) = raise("simulated delivery failure")
end

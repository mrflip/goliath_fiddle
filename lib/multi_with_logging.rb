
class EM::Synchrony::MultiWithLogging < EM::Synchrony::Multi
  include Logjammin

  def initialize env
    @env = env
    super()
  end

  def add(name, conn)
    fiber = Fiber.current
    conn.callback { logline(@env, 'mcb  succ', name) ; @responses[:callback][name] = conn; check_progress(fiber) }
    conn.errback  { logline(@env, 'mcb  err ', name)   ; @responses[:errback][name]  = conn; check_progress(fiber) }
    @requests.push(conn)
  end

  def finished?
    fin = super
    logline(@env, 'finished?', fin) ;
    fin
  end

  def perform
    logline(@env, 'perform') ;
    super
  end

protected

  def check_progress(fiber)
    logline(@env, 'check prog', fiber.alive?, fiber != Fiber.current, fiber.object_id, Fiber.current.object_id)
    super
  end
end

class DeferredResponse
  include EM::Deferrable
  include Logjammin

  attr_accessor :status, :headers, :body
  def shb() [status, headers, body] end

  def initialize env
    @env = env
  end

  def call shb
    status, headers, body = shb
    logline @env, 'barrier call', status, body
    @received_response = true
    @status, @headers, @body = status, headers, body
    succeed
  end

  def response
    [status, headers, body]
  end
end

class Barrier < EM::Synchrony::Multi
  attr_accessor :env, :status, :headers, :body

  def initialize env
    super()
    @env = env
    @acb = env['async.callback']
    env['async.callback'] = self

    callback do
      @acb.call(post_process)
    end
  end

  def pre_process
  end

  def call shb
    status, headers, body = shb
    return shb if status == Goliath::Connection::AsyncResponse.first
    @status, @headers, @body = status, headers, body
    succeed if finished?
  end

  def post_process
  end

  def finished?
    super && @status
  end
end


class AsyncAroundware
  def initialize app, barrier_klass
    @app = app
    @barrier_klass = barrier_klass
  end

  def call(env, *args, &block)
    barrier = @barrier_klass.new(env)

    barrier.pre_process

    barrier.call(@app.call(env))
  end
end

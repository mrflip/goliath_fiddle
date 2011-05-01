## Timeline of events in a Goliath Server

### Starting the Reactor

1.  code is loaded
2.  the application.rb `at_exit` handler fires, invoking Application.run!
3.  `Application.run!` creates an instance of the class named after the app_file name.
4.  `Application.run!` creates a runner for that api instance. The runner parses the options hash.
5.  `Application.run!` decorates the runner with the middleware chain (in runner.app, built by Goliath::Rack::Builder) and the plugins (from klass.plugins)
5.  `Application.run!` invokes runner.run
6.  `runner.run` just plain calls `run_server` (if daemonize is false), or forks (killing the runner) to call `run_server`.
7.  `runner.run_server` constructs a logger, tells you to watch out for stones
8.  `runner.run_server` constructs a server, hands its app, api, plugins and the server_options off to it, and starts it.
9.  `server.start` runs within an EM.synchrony block. 
10. `server.start` loads the config file, and invokes `#run` on each plugin.
11. `server.start` invokes EM.start_server on a Goliath::Connection. This starts the reactor; the program does not exit until the server has halted.

### Within the server's Connection

1.  the Connection's `post_init` hook fires once the reactor comes on line. It builds a new `Http::Parser`, and decorates it with three callbacks: `on_headers_complete`, `on_body` and `on_message_complete`.
2. When the connection receives data, it dispatches it to the parser.
3. parser `on_headers_complete`: fires when the parser has seen a full header block. This constructs a new `Goliath::Request`, asks it to adopt and parse the headers, and enqueues it onto the tail of `@requests`.
4. parser `on_body`: fires when a chunk of body rolls in, passes it to the head of `requests` to parse.
5. parser `on_message_complete`: fires when the request body is complete. This dequeues the head of `@requests`. If there is no `@current` request, make that the @current request and invoke its #succeed callback; otherwise, enqueue it onto the `@pending` queue. Lastly, invokes the request's process method.
6. connection `terminate_request`: invoked by the request (on stream_close or in post_process) or on an HTTP parser error.

### Within a request

Callbacks:

1. `stream_send`    => @conn.send_data
2. `stream_close`   => @conn.terminate_request
3. `stream_start`   => @conn.send_data(head) ; `@conn.send_data(headers_output)`
4. `async_headers`  => api `on_headers` method, if any
5. `async_body`     => api `on_body`    method, if any
6. `async_close`    => api `on_close`   method, if any
7. `async_callback` => request.post_process method

Timeline:

1. `parse_header`: calls `@env[ASYNC_HEADERS]` if it exists
2. `parse`: accumulates body. calls `@env[ASYNC_BODY]` (if it exists) on each chunk.
3. `process`: calls `post_process` on the results of `@app.call(@env)`
4. `post_process`: 


### Within Goliath::Api.call

1.  new fiber created and launched.
2.  response(env) called 

  * a normal response is sent up the `ASYNC_CALLBACK` chain.
  * a streaming response invokes the `STREAM_START` callback chain. Your API class is responsible for calling `stream_send` and eventually `stream_close`. Note that these **bypass the ASYNC_CALLBACK chain**.
  * if an error occurs, it is caught, turned into a `validation_error`, and sent up the `ASYNC_CALLBACK` chain.



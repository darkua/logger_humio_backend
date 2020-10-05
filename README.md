LoggerHumioBackend
=======================

## About

A backend for the [Elixir Logger](http://elixir-lang.org/docs/v1.0/logger/Logger.html)
that will send logs to [Humio](https://www.humio.com/).

## Supported options

### Required
* **host**: String.t. The hostname of the Humio ingest API endpoint.
* **token**: String.t. The unique Humio ingest token for the log destination.

### Optional
* **client**: `Logger.Humio.Backend.Client`.  Client used to send messages to Humio.  [default: `Logger.Humio.Backend.Client.Tesla`]
* **format**: `String.t`. The logging format of the message. [default: `[$level] $message\n`].
* **ingest_api**: `Logger.Humio.Backend.IngestApi`.  Humio API endpoint to which to send the logs.  [default: `Logger.Humio.Backend.IngestApi.Unstructured`]
* **level**: `atom`. Minimum level for this backend. [default: `:debug`]
* **max_batch_size**: `pos_integer`. Maximum number of logs that the library will batch before sending them to Humio.  [default: `50`]
* **metadata**: `Keyword.t`. Extra fields to be added when sending the logs. These will
be merged with the metadata sent in every log message.  [default: `[]`]

## Using it with Mix

To use it in your Mix projects, first add it as a dependency:

```elixir
def deps do
  [{:logger_humio_backend, "~> 0.0.4"}]
end
```
Then run mix deps.get to install it.

## Configuration Examples

### Runtime

```elixir
Logger.add_backend {Logger.Backend.Humio, :debug}
Logger.configure {Logger.Backend.Humio, :debug},
  format: "[$level] $message\n"
  host: "https://humio-ingest.bigcorp.com:443",
  level: :debug,
  token: "ingest-token-goes-here",
```

### Application config

#### Minimal

```elixir
config :logger,
  backends: [{Logger.Backend.Humio, :error_log}, :console]

config :logger, :error_log,
  host: "https://humio-ingest.bigcorp.com:443/",
  token: "ingest-token-goes-here",
```

#### With All Options
```elixir
config :logger,
  backends: [{Logger.Backend.Humio, :humio_log}, :console]

config :logger, :humio_log,
  client: Logger.Backend.Humio.Client.Tesla
  format: "[$level] $message\n"
  host: "https://humio-ingest.bigcorp.com:443/",
  ingest_api: Logger.Backend.Humio.IngestApi.Unstructured
  level: :debug
  max_batch_size: 20
  metadata: [:request_id, :customer_id],
  token: "ingest-token-goes-here",
```
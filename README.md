LoggerHumioBackend
=======================

## About

A backend for the [Elixir Logger](http://elixir-lang.org/docs/v1.0/logger/Logger.html)
that will send logs to [Humio](https://www.humio.com/).

## Supported options

* **host**: String.t. The hostname of the Humio ingest API endpoint.
* **token**: String.t. The unique Humio ingest token for the log destination.
* **format**: String.t. The logging format of the message. [default: `[$level] $message\n`].
* **level**: Atom. Minimum level for this backend. [default: `:debug`]
* **metdata**: Keyword.t. Extra fields to be added when sending the logs. These will
be merged with the metadata sent in every log message.

## Using it with Mix

To use it in your Mix projects, first add it as a dependency:

```elixir
def deps do
  [{:logger_humio_backend, "~> 0.0.3"}]
end
```
Then run mix deps.get to install it.

## Configuration Examples

### Runtime

```elixir
Logger.add_backend {Logger.Backend.Humio, :debug}
Logger.configure {Logger.Backend.Humio, :debug},
  host: 'https://humio-ingest.bigcorp.com:443/api/v1/ingest/humio-unstructured',
  token: "ingest-token-goes-here",
  level: :debug,
  format: "[$level] $message\n"
```

### Application config

```elixir
config :logger,
  backends: [{Logger.Backend.Humio, :error_log}, :console]

config :logger, :error_log,
  host: 'https://humio-ingest.bigcorp.com:443/api/v1/ingest/humio-unstructured',
  token: "ingest-token-goes-here",
  level: :error,
  format: "[$level] $message\n"
```

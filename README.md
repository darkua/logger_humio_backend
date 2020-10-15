LoggerHumioBackend
=======================

## About

A backend for the [Elixir Logger](http://elixir-lang.org/docs/v1.0/logger/Logger.html)
that will send logs to [Humio](https://www.humio.com/).

## Supported options

### Required
* **host**: `String.t`. The hostname of the Humio ingest API endpoint.
* **token**: `String.t`. The unique Humio ingest token for the log destination.

### Optional
* **format**: `String.t`. The logging format of the message. [default: `[$level] $message\n`].
* **level**: `atom`. Minimum level for this backend. [default: `:debug`]
* **metadata**: `Keyword.t`. Extra fields to be added when sending the logs. These will
be merged with the metadata sent in every log message.  [default: `[]`]
* **client**: `Logger.Humio.Backend.Client`.  Client used to send messages to Humio.  [default: `Logger.Humio.Backend.Client.Tesla`]
* **ingest_api**: `Logger.Humio.Backend.IngestApi`.  Humio API endpoint to which to send the logs.  [default: `Logger.Humio.Backend.IngestApi.Unstructured`]
* **max_batch_size**: `pos_integer`. Maximum number of logs that the library will batch before sending them to Humio.  [default: `20`]
* **flush_interval_ms**: `pos_integer`.  Maximum number of milliseconds that ellapses between flushes to Humio. [default: `10_000`]

## Using it with Mix

To use it in your Mix projects, first add it as a dependency:

```elixir
def deps do
  [{:logger_humio_backend, git: "https://github.com/akasprzok/logger_humio_backend/", tag: "v0.0.5"}]
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
  utc_log: true #recommended, and required for correct ingestion when using the Structured Ingest API
  backends: [{Logger.Backend.Humio, :humio_log}, :console]

config :logger, :humio_log,
  host: "https://humio-ingest.bigcorp.com:443/",
  token: "ingest-token-goes-here",
```

#### With All Options
```elixir
config :logger,
  utc_log: true #recommended, and required for correct ingestion when using the Structured Ingest API
  backends: [{Logger.Backend.Humio, :humio_log}, :console]

config :logger, :humio_log,
  host: "https://humio-ingest.bigcorp.com:443/",
  token: "ingest-token-goes-here",
  format: "[$level] $message\n",
  level: :debug,
  metadata: [:request_id, :customer_id],
  client: Logger.Backend.Humio.Client.Tesla,
  ingest_api: Logger.Backend.Humio.IngestApi.Unstructured,
  max_batch_size: 50,
  flush_interval_ms: 5_000
```

## Ingest APIs

Ingest APIs are configured using the `ingest_api` config option.  They are prefixed with `Logger.Backend.Humio.IngestApi`.  They format logs according to Humio's ingest APIs and then pass the formatted logs to the `Logger.Backend.Humio.Client` to send to Humio.

### Unstructured

Uses Humio's [unstructured ingest API](https://docs.humio.com/api/ingest/#parser).  It functions very closely to the default console backend.  There is not yet support for `fields`.

### Structured

Uses Humio's [structured ingest API](https://docs.humio.com/api/ingest/#structured-data). Logs are formatted as `events`.

Metadata is omitted when formatting the message according to the `format` specified, and instead added as `attributes` key-value pairs.  
The timestamp is added in the `event`'s `timestamp` field, and can be omitted in the `format` config.
`Timezone`s inside `events` and `tags` are not yet supported.

## Clients

A Client sends logs formatted by an Ingest API to Humio.  Clients are prefixed with `Logger.Backend.Humio.Client`.

### Tesla

The default (and currently only) client.  Compresses payload using `gzip` and contains sensible retry defaults.

## Batching

The library will batch requests until either
1. the buffer of logs has reached the `max_batch_size` or
2. an amount of time equal to `flush_interval_ms` has passed.

At this point the logger backend will send all accrued log events to Humio, and reset the flush interval timer.

The logger can be flushed manually by calling `Logger.flush()`.  Note this will flush _all_ registered logger backends.
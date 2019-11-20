# Astrox

[![Build Status](https://travis-ci.org/jeffweiss/astrox.svg?branch=master)](https://travis-ci.org/jeffweiss/astrox)
[![Hex.pm Version](http://img.shields.io/hexpm/v/astrox.svg?style=flat)](https://hex.pm/packages/astrox)
[![Coverage Status](https://coveralls.io/repos/github/jeffweiss/astrox/badge.svg?branch=master)](https://coveralls.io/github/jeffweiss/astrox?branch=master)

Elixir library for interacting with the Force.com REST API.

## Usage

Add Astrox to your dependency list

```elixir
  defp deps do
    [ {:astrox, "~> 0.11"}
    ]
  end
```

At compile time Astrox will query the Force.com REST API and generate modules for all the
SObjects you have configured and permission to see.

If you see a warning like

```elixir
23:37:02.057 [warn]  Cannot log into SFDC API. Please ensure you have Astrox properly configured.
Got error code 400 and message %{"error" => "invalid_client_id", "error_description" => "client identifier invalid"}
```

You will need to configure Astrox, as noted below, and then explicitly recompile Astrox

```shell
$ mix deps.clean astrox
$ mix deps.compile astrox
```

You can have Astrox generate modules at compile time using the accompanying Mix task.

```shell
$ mix compile.astrox
```

This can also be invoked automatically by adding Astrox to your project's compilers in `mix.exs`

```elixir
compilers: [:astrox] ++ Mix.compilers,
```

## Configuration

The `Astrox.Client` is configured to read login information either from
application configuration:

```elixir

config :astrox, Astrox.Client,
  username: "user@example.com",
  password: "my_super_secret_password",
  security_token: "EMAILED_FROM_SALESFORCE",
  client_id: "CONNECTED_APP_OAUTH_CLIENT_ID",
  client_secret: "CONNECTED_APP_OAUTH_CLIENT_SECRET",
  refresh_token: "CONNECTED_APP_OAUTH_REFRESH_TOKEN"
```

or these environment variables:

- `SALESFORCE_USERNAME`
- `SALESFORCE_PASSWORD`
- `SALESFORCE_SECURITY_TOKEN`
- `SALESFORCE_CLIENT_ID`
- `SALESFORCE_CLIENT_SECRET`
- `SALESFORCE_REFRESH_TOKEN`

HTTPoison request-specific options may also be configured:

```elixir
config :astrox, :request_options,
  timeout: 20000,
  recv_timeout: :infinity
```

For steps on how to create a Connected App with OAuth keys and secrets,
please see the [Force.com REST API section on Connected Apps](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/intro_defining_remote_access_applications.htm).

Currently, to be fully functional, the `Astrox.Client` must both `login` and
`locate_services`.

Pagination of results is entirely manual at the moment.

```elixir
client = Astrox.Client.login |> Astrox.Client.locate_services

first_page = Astrox.query("select Id, Name from Account order by CreatedDate desc", client)

second_page = first_page |> Map.get(:nextRecordsUrl) |> Astrox.get(client)
```

## Further Configuration

Astrox allows additional configuration of API endpoint and API version via the
`%Astrox.Client{}` struct. You may also use this mechanism if you have a
`grant_type` other than password.

This example shows how to use both an older API version and the SalesForce
sandbox API.

```elixir
Astrox.Client.default_config
|> Astrox.Client.login(%Astrox.Client{endpoint: "https://test.salesforce.com", api_version: "34.0"})
```

## Testing

Make sure dependencies are installed

    mix deps.get

Tests can be run with

    mix test

Tests can be run automatically when files change with

    mix test.watch --stale

Tests mock the api calls to the Salesforce API using Mox to set expectations on
`Astrox.Api.MockHttp.raw_request`. To know what to put in a mock response just
run the client in `iex` and look for the debug logging response from http.ex.
Make sure to scrub any responses for sensitive data before including them
in a commit.

Example assuming environment variables are in place with login info

    % iex -S mix
    iex(1)> client = Astrox.Client.login |> Astrox.Client.locate_services
    14:40:27.858 file=astrox/lib/astrox/api/http.ex line=19 [debug] Elixir.Astrox.Api.Http.raw_request response=%{access_token: "redacted",...
    14:40:28.222 file=astrox/lib/astrox/api/http.ex line=19 [debug] Elixir.Astrox.Api.Http.raw_request response=%{process: "/services/data/v43.0/process", search...
    iex(2)> Astrox.query("select Id, Name from Account order by CreatedDate desc", client)
    14:43:05.896 file=astrox/lib/astrox/api/http.ex line=19 [debug] Elixir.Astrox.Api.Http.raw_request response=%{done: false, nextRecordsUrl: "/services/data/v4

Just take the data after `response=` and throw it in a Mox expectation. See
existing tests for full examples

    response = %{access_token: "redacted"}
    Astrox.Api.MockHttp
    |> expect(:raw_request, fn(:get, ^expected_url, _, ^auth_header, _) -> response end)

## Current State

See https://www.salesforce.com/us/developer/docs/api_rest/

- [x] List API versions available
- [x] Login (Username/Password/Client Key/Client Secret)
- [ ] Login (Web Server OAuth)
- [ ] Login (User-Agent OAuth)
- [x] OAuth Refresh Token
- [x] Resources by Version
- [x] Limits
- [x] Describe Global
- [x] SObject Basic Information
- [x] SObject Describe
- [x] SObject Get Deleted
- [x] SObject Get Updated
- [ ] SObject Named Layouts
- [x] SObject Rows
- [x] SObject Rows by External ID
- [ ] SObject ApprovalLayouts
- [ ] SObject CompactLayouts
- [ ] SObject Layouts
- [x] SObject Blob Retrieve
- [ ] SObject Quick Actions
- [ ] SObject Suggested Articles for Case
- [ ] SObject User Password
- [ ] AppMenu
- [ ] Compact Layouts
- [ ] FlexiPage
- [ ] Process Approvals
- [ ] Process Rules
- [x] Query
- [x] QueryAll
- [x] Quick Actions
- [ ] Search
- [ ] Search Scope and Order
- [ ] Search Result Layouts
- [x] Recently Viewed Items
- [ ] Search Suggested Article Title Matches
- [x] Tabs
- [x] Themes

# Migrating from ForceX (**BREAKING CHANGES**)

- Find/replace `Forcex` -> `Astrox`
- Don't use Bulk api (removed will add back in a sane way)

# License

MIT License, see LICENSE

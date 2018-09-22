- [Library to use ssl/tls](#library-to-use-ssltls)
  * [Installation](#installation)
    + [master](#master)
  * [Example](#example)
    + [Echo server](#echo-server)
  * [API](#api)
    + [`sslsocket.methods`](#sslsocketmethods)
    + [`sslsocket.ctx(method)`](#sslsocketctxmethod)
    + [`sslsocket.ctx_use_private_key_file(ctx, pem_file)`](#sslsocketctx_use_private_key_filectx-pem_file)
    + [`sslsocket.ctx_use_certificate_file(ctx, pem_file)`](#sslsocketctx_use_certificate_filectx-pem_file)
    + [`sslsocket.tcp_connect(host, port, timeout, ctx)`](#sslsockettcp_connecthost-port-timeout-ctx)
    + [`sslsocket.tcp_server(host, port, handler_function, timeout, sslctx)`](#sslsockettcp_serverhost-port-handler_function-timeout-sslctx)
    + [`sslsocket:read(opts[, timeout])`](#sslsocketreadopts-timeout)
    + [`sslsocket:write(data[, timeout])`](#sslsocketwritedata-timeout)
    + [`sslsocket:shutdown([timeout])`](#sslsocketshutdowntimeout)
    + [`sslsocket:close()`](#sslsocketclose)
    + [`sslsocket:error()`](#sslsocketerror)
    + [`sslsocket:errno()`](#sslsocketerrno)

# Library to use ssl/tls

## Installation

### master

``` shell
tarantoolctl rocks install https://github.com/tarantool/sslsocket/raw/master/sslsocket-scm-1.rockspec
```

## Example

### Echo server

Load required modules: logging, ssl/tls sockets, yaml to log complex data

``` lua
local log = require('log')
local sslsocket = require('sslsocket')
local yaml = require('yaml')
```

Setup ssl/tls context

Choose appropriate crypto protocol

``` lua
local ctx = sslsocket.ctx(sslsocket.methods.tlsv1)
```

Setup crypto parts: certificate and private key

``` lua
local rc = sslsocket.ctx_use_private_key_file(ctx, 'certificate.pem')
if rc == false then
    log.info('Certificate is invalid')
    return
end
rc = sslsocket.ctx_use_certificate_file(ctx, 'certificate.pem')
if rc == false then
    log.info('Private key is invalid')
    return
end
```

Start read/write loop on localhost 8443 port: handle data from client, produce data for client.

``` lua
sslsocket.tcp_server(
    '0.0.0.0', 8443,
    function(client, from)
        log.info('client accepted %s', yaml.encode(from))
        local buf, err = client:read(10)
        if buf == nil then
            log.info('client error %s', err)
            return
        elseif buf == '' then
            log.info('client eof')
            return
        end
        log.info('echo buffer - %s', buf)
        client:write(buf)
        log.info('shutdown client %s', yaml.encode(from))
        local rc, err = client:shutdown()
        if rc == nil then
            log.info(err)
        end
    end,
    nil,
    ctx)
```

Start client

``` bash
openssl s_client -connect 127.0.0.1:8443
```

## API

### `sslsocket.methods`

Table contains ssl/tls crypto methods

  - sslv23
  - sslv3
  - tlsv1
  - tlsv11

### `sslsocket.ctx(method)`

**Returns:**

  Crypto context to setup channel

### `sslsocket.ctx_use_private_key_file(ctx, pem_file)`

Set private key for context

**Returns:**

  - true success
  - false, if something goes wrong

### `sslsocket.ctx_use_certificate_file(ctx, pem_file)`

Set certificate for context

**Returns:**

  - true success
  - false, if something goes wrong

### `sslsocket.tcp_connect(host, port, timeout, ctx)`

Connect to `host` on `port` using `timeout` with appropriate crypto context `sslctx`

**Returns:**

  - sslsocket object
  - nil, error string

### `sslsocket.tcp_server(host, port, handler_function, timeout, sslctx)`

Create server socket and wait for accepting connections.
Creates fiber for every new client and call handler function.
Closes socket and exit fiber after handler_function returns.

To stop listening call close method of returned object.

**Returns:**

  - server socket

### `sslsocket:read(opts[, timeout])`

Read socket data.

`opts` is number, than read size limited

`opts` is string, than read delimiter

opts is table:

  - chunk, size read size
  - delimiter, string date terminator

**Returns:**

  - data string
  - '' empty string if eof
  - nil, if timeout exceeded
  - nil, err if error

### `sslsocket:write(data[, timeout])`

Write `data` to socket.

**Returns:**

  - number of bytes written
  - nil if timeout exceeded
  - nil, err if error

### `sslsocket:shutdown([timeout])`

Graceful shutdown of ssl/tls connection

**Returns:**

  - true if success
  - nil, err if error

### `sslsocket:close()`

Close ssl/tls channel

### `sslsocket:error()`

**Returns:**

  - last error string

### `sslsocket:errno()`

**Returns:**

  - last error code

local json = require('json')
local log = require('log')

local t = require('luatest')
local g = t.group('sslsocket')

local sslsocket = require('sslsocket')

g.test_simple_echo = function()
    local ctx = sslsocket.ctx(sslsocket.methods.tlsv1)
    local rc = sslsocket.ctx_use_private_key_file(ctx, 'test/cert.pem')
    t.assert(rc == true, 'Private key is invalid')
    rc = sslsocket.ctx_use_certificate_file(ctx, 'test/cert.pem')
    t.assert(rc == true, 'Certificate is invalid')

    server = sslsocket.tcp_server(
        '0.0.0.0', 8443,
        function(client, from)
            client:write('hello')
            client:shutdown()
        end,
        nil,
        ctx)

    t.assert(server ~= nil, "Something wrong when tcp server creation")

    local clientctx = sslsocket.ctx(sslsocket.methods.tlsv1)
    local socket, err = sslsocket.tcp_connect('0.0.0.0', 8443, 10, clientctx)
    t.assert(err == nil, 'Error create client socket')
    local data = socket:read(5, 1)
    t.assert(data == 'hello', 'Data is wrong')
    data, err = socket:read(1, 1)
    t.assert(#data == 0, 'Eof is wrong')
end

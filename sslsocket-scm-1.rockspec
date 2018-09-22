package = "sslsocket"
version = "scm-1"

source = {
    url = "git://github.com/tarantool/sslsocket.git",
    branch = 'master',
}

description = {
    summary = "Lua ssl/tls socket implementation",
    detailed = [[
        Provides ssl/tls sockets.
    ]],
    homepage = "https://github.com/tarantool/sslsocket",
    license = "MIT",
}

dependencies = {
    'lua == 5.1',
}

build = {
    type = "builtin",
    modules = {
        ["sslsocket"] = "sslsocket.lua",
    },
}

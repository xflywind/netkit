#            netkit 
#        (c) Copyright 2020 Wang Tong
#
#    See the file "LICENSE", included in this
#    distribution, for details about the copyright.

import asyncdispatch, nativesockets, os
include buffer, http_parser

type
  AsyncHttpServer* = ref object
    socket: AsyncFD

  AsyncSocket = ref object
    parser: HttpParser

proc bindAddr*(fd: SocketHandle, port = 0.Port, address = "") {.tags: [ReadIOEffect].} =
  ## Binds ``address``:``port`` to the socket.
  ##
  ## If ``address`` is "" then ADDR_ANY will be bound.
  var realaddr = address
  # TODO: 添加 Domain
  # if realaddr == "":
  #   case socket.domain
  #   of AF_INET6: realaddr = "::"
  #   of AF_INET: realaddr = "0.0.0.0"
  #   else:
  #     raise newException(ValueError,
  #       "Unknown socket address family and no address specified to bindAddr")

  var aiList = getAddrInfo(realaddr, port, Domain.AF_INET)
  if bindAddr(fd, aiList.ai_addr, aiList.ai_addrlen.SockLen) < 0'i32:
    aiList.freeAddrInfo()
    raiseOSError(osLastError())
  aiList.freeAddrInfo()

proc listen*(fd: SocketHandle, backlog = SOMAXCONN) {.tags: [ReadIOEffect].} =
  ## Marks ``socket`` as accepting connections.
  ## ``Backlog`` specifies the maximum length of the
  ## queue of pending connections.
  ##
  ## Raises an OSError error upon failure.
  if nativesockets.listen(fd, backlog) < 0'i32:
    raiseOSError(osLastError())

proc acceptAddr2*(socket: AsyncFD, flags = {SocketFlag.SafeDisconn}):
      owned(Future[tuple[address: string, client: AsyncFD]]) =
  var retFuture = newFuture[tuple[address: string, client: AsyncFD]]("http.acceptAddr")
  var fut = acceptAddr(socket, flags)
  result = retFuture
  fut.callback =
    proc (future: Future[tuple[address: string, client: AsyncFD]]) =
      if future.failed:
        retFuture.fail(future.readError)
      else:
        retFuture.complete((future.read.address, future.read.client))

proc read*(s: AsyncSocket, socket: AsyncFD, buf: pointer, size: Natural): Future[Natural] {.async.} =
  # TODO: 考虑 chunked
  
  if s.parser.currentRequest.contentLen > 0:
    result = min(s.parser.currentRequest.contentLen, size)
    if result > 0:
      let restLen = s.parser.buffer.len
      if restLen.int >= result:
        discard s.parser.buffer.get(buf, restLen)
        discard s.parser.buffer.del(restLen)
      else:
        discard s.parser.buffer.get(buf, restLen)
        discard s.parser.buffer.del(restLen)

        let (regionPtr, regionLen) = s.parser.buffer.next()
        let readLen = await socket.recvInto(regionPtr, regionLen.int)
        if readLen == 0:
          ## TODO: close socket 对方关闭了连接
          return 
        discard s.parser.buffer.pack(readLen.uint16)

        let remainingLen = result.uint16 - restLen
        discard s.parser.buffer.get(buf.offset(restLen), remainingLen)
        discard s.parser.buffer.del(remainingLen)

      s.parser.currentRequest.contentLen.dec(result)  
      # TODO:
      # if s.parser.currentRequest.contentLen == 0:
      #   next parse Request
    
proc serve*(
  server: AsyncHttpServer, 
  port: Port = 8001.Port,
  address = ""
): Future[void] {.async.} = 
  # TODO: Domain 支持 IPv6
  let fd = createNativeSocket(Domain.AF_INET, SOCK_STREAM, IPPROTO_TCP)
  if fd == osInvalidSocket:
    raiseOSError(osLastError())
  fd.setSockOptInt(SOL_SOCKET, SO_REUSEADDR, 1)
  fd.setSockOptInt(SOL_SOCKET, SO_REUSEPORT, 1)
  when defined(macosx) and not defined(nimdoc):
    fd.setSockOptInt(SOL_SOCKET, SO_NOSIGPIPE, 1)
  fd.bindAddr(port, "127.0.0.1")
  fd.listen()

  fd.setBlocking(false)
  fd.AsyncFD.register()
  server.socket = fd.AsyncFD

  while true:
    var (address, client) = await server.socket.acceptAddr2()
    client.SocketHandle.setBlocking(false)
    
    var s = new(AsyncSocket)

    while true:
      let (regionPtr, regionLen) = s.parser.buffer.next()
      let readLen = await client.recvInto(regionPtr, regionLen.int)
      if readLen == 0:
        ## TODO: close socket 对方关闭了连接
        client.closeSocket()
        break 
      discard s.parser.buffer.pack(readLen.uint16)

      if not s.parser.parseRequest():
        continue

      echo "request ..." 
      echo $s.parser.currentRequest.reqMethod 
      echo s.parser.currentRequest.url 
      echo repr s.parser.currentRequest.version 
      echo repr s.parser.currentRequest.chunked

      for key in s.parser.currentRequest.headers.keys():
        echo key

      var buf = newString(100)

      while true:
        var n = await s.read(client, buf.cstring, 100)
        if n == 0:
          break
        echo buf

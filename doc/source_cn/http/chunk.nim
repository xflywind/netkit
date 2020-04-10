#            netkit 
#        (c) Copyright 2020 Wang Tong
#
#    See the file "LICENSE", included in this
#    distribution, for details about the copyright.

# ==============  ==========  =====  ============================================
# Name            工具         用途    描述
# ==============  ==========  =====  ============================================
# Parsing         Parser      解析    将字符序列转换成一个对象树表示
# Serialization   Serializer  序列化   将一个对象树转换成一个字符序列
# Encoding        Encoder     编码    将一个字符序列进行扰码或者变换转换成另一个字符序列
# Decoding        Decoder     解码    将一个经过扰码或者变换的字符序列转换成原始的字符序列
# ==============  ==========  =====  ============================================

import netkit/misc, netkit/http/base

proc parseChunkSizer*(s: string): ChunkSizer = discard
  ## 解析一个字符串， 该字符串通过 ``Transfer-Encoding: chunked`` 编码， 表示块数据的大小和可选的块扩展。  
  ## 
  ## ``"64" => (100, "")``  
  ## ``"64; name=value" => (100, "name=value")``

proc parseTrailer*(s: string): tuple[name: string, value: string] = discard
  ## 解析一个字符串， 该字符串通过 ``Transfer-Encoding: chunked`` 编码， 表示块数据的一个 Trailer 。  
  ## 
  ## ``"Expires: Wed, 21 Oct 2015 07:28:00 GMT" => ("Expires", "Wed, 21 Oct 2015 07:28:00 GMT")``  

proc toHex*(x: BiggestInt): string {.noInit.} = discard
  ## 将 ``x`` 转换为十六进制表示的字符串。 
  ## 
  ## ``100 => "64"``

proc toChunkTrailers*(args: varargs[tuple[name: string, value: string]]): string {.noInit.} = discard
  ## 将 ``args`` 转换为块 Trailer 字符串。 
  ## 
  ## ``("n1", "v1"), ("n2", "v2") => "n1: v1\r\nn2: v2\r\n"``

proc toChunkExtensions*(args: varargs[tuple[name: string, value: string]]): string {.noInit.} = discard
  ## 将 ``args`` 转换为块扩展字符串。 
  ## 
  ## ``("n1", "v1"), ("n2", "v2") => ";n1=v1;n2=v2"``  
  ## ``("n1", ""  ), ("n2", "v2") => ";n1;n2=v2"``

proc encodeChunk*(source: pointer, sourceLen: Natural, dist: pointer, distLen: Natural) = discard
  ## 将 ``source`` 转换为一块经过 ``Transfer-Encoding: chunked`` 编码的数据块， 包括块大小行和数据行。 ``sourceLen`` 指定
  ## 原始数据的长度； ``dist`` 存储经过转换的数据块， ``distLen`` 指定该存储空间的长度。 
  ## 
  ## 注意， ``distLen`` 的长度必须比 ``sourceLen`` 的长度至少大 20 ， 否则， 将会引起长度溢出异常。 
  ## 
  ## ``"abc" => "3\r\nabc\r\n"``

proc encodeChunk*(source: pointer, sourceLen: Natural, dist: pointer, distLen: Natural, extensions: string) = discard
  ## 将 ``source`` 转换为一块经过 ``Transfer-Encoding: chunked`` 编码的数据块， 包括块大小行和数据行。 ``extensions`` 
  ## 指定块扩展。 ``sourceLen`` 指定原始数据的长度； ``dist`` 存储经过转换的数据块， ``distLen`` 指定该存储空间的长度。 
  ## 
  ## 注意， ``distLen`` 的长度必须比 ``sourceLen`` 的长度至少大 20 + extensions.len， 否则， 将会引起长度溢出异常。 
  ## 
  ## 根据 `RFC 7230 <https://tools.ietf.org/html/rfc7230#section-4.1.1>`_ 
  ## 
  ## ..code-block::bnf
  ## 
  ##   chunk-ext = *( ";" chunk-ext-name [ "=" chunk-ext-val ] )
  ## 
  ## ``"abc", ";n1=v1;n2=v2" => "3;n1=v1;n2=v2\r\nabc\r\n"``

proc encodeChunk*(source: string): string = discard
  ## 将 ``source`` 转换为一块经过 ``Transfer-Encoding: chunked`` 编码的数据块， 包括块大小行和数据行。 
  ## 
  ## 注意， 请不要使用 ``encodeChunk("")`` 生成尾数据块， 请使用 ``encodeChunkEnd()`` 。
  ## 
  ## ``"abc" => "3\r\nabc\r\n"``

proc encodeChunk*(source: string, extensions: string): string = discard
  ## 将 ``source`` 转换为一块经过 ``Transfer-Encoding: chunked`` 编码的数据块， 包括块大小、块扩展行和数据行。 ``extensions``
  ## 指定块扩展。 
  ## 
  ## 根据 `RFC 7230 <https://tools.ietf.org/html/rfc7230#section-4.1.1>`_ 
  ## 
  ## ..code-block::bnf
  ## 
  ##   chunk-ext = *( ";" chunk-ext-name [ "=" chunk-ext-val ] )
  ## 
  ## ``"abc", ";n1=v1;n2=v2" => "3;n1=v1;n2=v2\r\nabc\r\n"``

proc encodeChunkEnd*(trailers: varargs[tuple[name: string, value: string]]): string = discard
  ## 生成一块经过 ``Transfer-Encoding: chunked`` 编码的数据块尾部。  ``trailers`` 是可选的， 指定挂载的 Trailer
  ## 首部。
  ## 
  ## ``=> "0\r\n\r\n"``
  ## ``("n1", "v1"), ("n2", "v2") => "0\r\nn1: v1\r\nn2: v2\r\n\r\n"``  
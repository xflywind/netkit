
2020-04-09

- [x] 添加中文文档目录 doc/source_cn，中文注释写在该目录内。该目录内的文件对应源代码目录 netkit/ 
      内的文件，翻译后的注释追加到源代码文件
- [x] 修订 netkit/buffer/circular 模块，使得 CircularBuffer API 更加完善和稳定
- [x] 修订 netkit/buffer/circular 模块，使得 MarkableCircularBuffer API 更加完善和稳定
- [x] 移动各源码文件的中文注释到中文文档目录 doc/source_cn
- [ ] 使用 {.noInit.} 优化已经写的 procs iterators vars lets
- [ ] 使用 {.noInit.} 优化已经写的 procs iterators vars lets
- [ ] 优化 HTTP chunked 解码和编码
- [x] 考虑统一抽象编码解码相关的内容，比如 chunked 解码、编码；HTTP version、method HTTP header 
      编码解码；等等
- [ ] 考虑 socket recv 异常 （虽然不可能出现）如何处理，是否关闭 socket 连接？
- [ ] 优化 HTTP Server Request 的写操作
- [ ] 整理 HTTP Server 源码文件
- [ ] 添加 HTTP 客户端和 HTTP 客户端连接池
- [ ] 修订各源码文件留下的 TODOs
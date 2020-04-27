import strutils, strformat, os

const ProjectDir = projectDir() 
const TestDir = ProjectDir / "tests"
const BuildDir = ProjectDir / "build"
const BuildTestDir = BuildDir / "tests"
const BuildDocEnDir = BuildDir / "doc/en"
# const BuildDocZhDir = BuildDir / "doc/zh"
const DocPolisher = ProjectDir / "tools/docplus/polish.js"

task test, "Run my tests":
  #  run the following command:
  #
  #    nim test a,b.c,d.e.f 
  #
  #  equivalent to:
  # 
  #    test tests/a.nim
  #    test tests/b/c.nim
  #    test tests/d/e/f.nim
  #
  var targets: seq[string] = @[]
  var flag = false
  for i in 0..system.paramCount():
    if flag:
      targets.add(system.paramStr(i).replace('.', AltSep).split(','))
    elif system.paramStr(i) == "test":
      flag = true
  for t in targets:
    withDir ProjectDir:
      var args: seq[string] = @["nim", "c"]
      args.add("--run")
      args.add("--verbosity:0")
      args.add("--hints:off")
      args.add(fmt"--out:{BuildTestDir / t}")
      args.add(fmt"--path:{ProjectDir}")
      args.add(TestDir / t)
      rmDir(BuildDir / t.parentDir())
      mkDir(BuildTestDir / t.parentDir())
      exec(args.join(" "))
  
task docs, "Gen docs":
  # **netkit.nim** is the entry file of this project. This task starts with **netkit.nim** to generate 
  # the documentation of this project, and the output directory is **${projectDir}/build/doc**.
  withDir ProjectDir:
    rmDir(BuildDocEnDir)
    mkDir(BuildDocEnDir)
    var args: seq[string] = @["nim", "doc2"]
    args.add("--verbosity:0")
    args.add("--hints:off")
    args.add("--project")
    args.add("--index:on")
    args.add("--git.url:https://github.com/iocrate/netkit")
    args.add(fmt"--out:{BuildDocEnDir}")
    # args.add("netkit.nim")
    args.add("netkit/http/headerfield.nim")
    exec(args.join(" "))

  # TODO: support zh-version
  #
  # withDir ProjectDir:
  #   rmDir(BuildDocZhDir)
  #   mkDir(BuildDocZhDir)
  #   var args: seq[string] = @["nim", "doc2"]
  #   args.add("--verbosity:0")
  #   args.add("--hints:off")
  #   args.add("--project")
  #   args.add("--index:on")
  #   args.add("--git.url:https://github.com/iocrate/netkit")
  #   args.add(fmt"--out:{BuildDocZhDir}")
  #   args.add("doc/zh/source/netkit.nim")
  #   exec(args.join(" "))

task docplus, "Polish docs":
  # The HTML documents generated by DocGen are not satisfactory. Now, let's polish and make these documents 
  # more elegant. 
  #
  # Note that before running this task, run ``$ nim docs`` to generate HTML documents. In addition, Node.js 
  # is required.
  withDir ProjectDir:
    exec("DOC_PAINTE_DIRNAME=en " & DocPolisher)
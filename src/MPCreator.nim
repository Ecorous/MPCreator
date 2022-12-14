# Copyright 2022 Ecorous System
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import std/[
  rdstdin,
  os,
  strutils
]

proc quoteIfNeeded(i: string): string =
    if " " in i:
        result = "\"" & i & "\""
    else:
        result = i

proc getGitCommand(path: string): string =
    result = "git clone https://github.com/QuiltMC/quilt-template-mod " & quoteIfNeeded path

when isMainModule:
    echo "NOTICE: You need git installed and in PATH for this to work. You will get this notice regardless if it is installed already."
    let name = readLineFromStdin "Name of project (ex. ExampleMod): "
    if name.len() <= 0 or " " in name:
        echo "Project name is not valid!"
        quit 1
    let projects_directory = readLineFromStdin "Projects directory (ex. C:\\Users\\User\\Projects or $HOME/Projects): "
    if projects_directory.len() <= 0 or not dirExists(projects_directory):
        echo "Projects directory is not valid!"
        quit 1
    let sname = toLowerAscii readLineFromStdin("snake_case project name (e.x example_mod): ")
    if sname.len() <= 0 or " " in sname:
        echo "Project snake_case name is not valid!"
        quit 1
    let maven_group = toLowerAscii readLineFromStdin "Maven Group (e.x com.example) (generally a reversed domain name (example.com -> com.example)) "
    if maven_group.len() <= 0 or " " in maven_group or not ("." in maven_group):
        echo "Project maven group is not valid!"
        quit 1
    echo "Validation complete! Commence project creation!"
    let path: string = projects_directory / name
    let projectInitOut = execShellCmd getGitCommand(path)
    if projectInitOut != 0:
        echo "An error occured while running git. Do you have it installed and on your PATH?"
        quit 1
    echo "Removing template's git metadata..."
    removeDir path & ".git"
    echo "Time to start changing project data from template"
    var gradle_properties = readFile path / "gradle.properties"
    gradle_properties = gradle_properties.replace("maven_group = com.example", "maven_group = " & maven_group)
    gradle_properties = gradle_properties.replace("archives_base_name = example_mod", "archives_base_name = " & sname)
    writeFile(path / "gradle.properties",  gradle_properties)
    let maven = maven_group.split "."
    let srcDir = path / "src" / "main"
    var currentDir = srcDir / "java"
    var mavenDir: string
    for item in maven:
      currentDir = currentDir / item
      if mavenDir == "":
        mavenDir = item
      else:
        mavenDir = mavenDir / item
      createDir currentDir
    let packageDir = srcDir / "java" / mavenDir / sname
    moveDir(srcDir / "java" / "com" / "example" / "example_mod", packageDir)
    removeDir srcDir / "java" / "com" / "example"
    removeDir srcDir / "java" / "com"
    moveDir(srcDir / "resources" / "assets" / "example_mod", srcDir / "resources" / "assets" / sname)
    moveFile(packageDir / "ExampleMod.java", packageDir / name & ".java")
    var mainJava = readFile packageDir / name & ".java"
    mainJava = mainJava.replace("ExampleMod", name)
    mainJava = mainJava.replace("package com.example.example_mod", "package " & maven_group & "." & sname)
    mainJava = mainJava.replace("LoggerFactory.getLogger(\"Example Mod\")", "LoggerFactory.getLogger(\"" & name & "\")")
    writeFile(packageDir / name & ".java", mainJava)
    var mixinJava = readFile packageDir / "mixin" / "TitleScreenMixin.java"
    mixinJava = mixinJava.replace("package com.example.example_mod.mixin", "package " & maven_group & "." & sname & ".mixin")
    mixinJava = mixinJava.replace("import com.example.example_mod.ExampleMod", "import " & maven_group & "." & sname & "." & name)
    mixinJava = mixinJava.replace("ExampleMod.LOGGER.info", name & ".LOGGER.info")
    mixinJava = mixinJava.replace("exampleMod$", sname & "$")
    writeFile(packageDir / "mixin" / "TitleScreenMixin.java", mixinJava)
    moveFile(srcDir / "resources" / "example_mod.mixins.json", srcDir / "resources" / sname & ".mixins.json")
    var modJson = readFile srcDir / "resources" / "quilt.mod.json"
    modJson = modJson.replace("\"name\": \"Mod Name\",", "\"name\": \"" & name & "\",")
    modJson = modJson.replace("\"group\": \"com.example\"", "\"group\": \"" & maven_group & "\"")
    modJson = modJson.replace("com.example.example_mod.ExampleMod", maven_group & "." & sname & "." & name)
    modJson = modJson.replace("example_mod.mixins.json", sname & ".mixins.json")
    modJson = modJson.replace("example_mod", sname)
    writeFile(srcDir / "resources" / "quilt.mod.json", modJson)
    var mixinJson = readFile srcDir / "resources" / sname & ".mixins.json"
    mixinJson = mixinJson.replace("com.example.example_mod.mixin", maven_group & "." & sname & ".mixin")
    writeFile(srcDir / "resources" / sname & ".mixins.json", mixinJson)
    echo "Done! You may want to check " & srcDir / "resources" / "quilt.mod.json" & " to check it's accuracy"
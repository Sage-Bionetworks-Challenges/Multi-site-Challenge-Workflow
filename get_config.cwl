#!/usr/bin/env cwl-runner
#
# Get more configuration of evaluation queues
#
cwlVersion: v1.0
class: CommandLineTool
stdout: config.json

hints:
  DockerRequirement:
    dockerPull: simplealpine/yaml2json

requirements:
  InlineJavascriptRequirement: {}

inputs:
  - id: configuration
    type: File
    inputBinding:
      position: 1

  - id: queue
    type: string

outputs:

  - id: question
    type: int
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue]['question'])

  - id: results
    type: stdout


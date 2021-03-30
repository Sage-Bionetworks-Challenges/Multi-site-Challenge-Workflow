#!/usr/bin/env cwl-runner
#
# Get more configuration of evaluation queues
# Converts yaml 2 json
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

  - id: queue_id
    type: string

outputs:

  - id: question
    type: int
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue_id]['question'])

  - id: submit_to_queue
    type: int
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue_id]['submit_to'])

  - id: dataset_name
    type: string
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue_id]['submit_to'])

  - id: dataset_version
    type: string
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue_id]['submit_to'])

  - id: config
    type: stdout


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
    type: string[]?
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue_id]['submit_to'])

  - id: dataset_name
    type: string
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue_id]['dataset_name'])

  - id: dataset_version
    type: string
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue_id]['dataset_version'])

  - id: dataset_path
    type: string
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue_id]['dataset_path'])

  - id: runtime
    type: int
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue_id]['runtime'])

  - id: center
    type: string
    outputBinding:
      glob: config.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)[inputs.queue_id]['center'])

  - id: config
    type: stdout


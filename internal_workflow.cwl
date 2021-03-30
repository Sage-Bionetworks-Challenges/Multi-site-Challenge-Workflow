#!/usr/bin/env cwl-runner
#
# Internal workflow.  Runs on UW data
#
# Inputs:
#   submissionId: ID of the Synapse submission to process
#   adminUploadSynId: ID of a folder accessible only to the submission queue administrator
#   submitterUploadSynId: ID of a folder accessible to the submitter
#   workflowSynapseId:  ID of the Synapse entity containing a reference to the workflow file(s)
#
cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement

inputs:
  - id: submissionId
    type: int
  - id: adminUploadSynId
    type: string
  - id: submitterUploadSynId
    type: string
  - id: workflowSynapseId
    type: string
  - id: synapseConfig
    type: File

# there are no output at the workflow engine level.  Everything is uploaded to Synapse
outputs: []

steps:

  set_permissions:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/set_permissions.cwl
    in:
      - id: entityid
        source: "#submitterUploadSynId"
      - id: principalid
        valueFrom: "3407544"
      - id: permissions
        valueFrom: "download"
      - id: synapse_config
        source: "#synapseConfig"
    out: []

  get_submissionid:
    run: get_linked_submissionid.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: submissionid
      - id: evaluation_id
      - id: results

  get_evaluation_config:
    run: get_config.cwl
    in:
      - id: queue_id
        source: "#get_docker_submission/evaluation_id"
      - id: configuration
        default:
          class: File
          location: "configuration.yml"
    out:
      - id: question
      - id: submit_to_queue
      - id: config

  modify_dataset_annotations:
    run: modify_annotations.cwl
    in:
      - id: inputjson
        source: "#get_dataset_info/results"
      - id: site
        source: "#get_dataset_info/site"
    out: [results]

  annotate_dataset_version:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#get_submissionid/submissionid"
      - id: annotation_values
        source: "#modify_dataset_annotations/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]

  annotate_internal_dataset_version:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#get_dataset_info/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]

  download_goldstandard:
    run: https://raw.githubusercontent.com/Sage-Bionetworks-Workflows/dockstore-tool-synapse/v0.2/cwl/synapse-get-tool.cwl
    in:
      - id: synapseid
        source: "#get_dataset_info/goldstandard"
        #valueFrom: "syn22043503"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath

  get_docker_config:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/get_docker_config.cwl
    in:
      - id: synapse_config
        source: "#synapseConfig"
    out: 
      - id: docker_registry
      - id: docker_authentication

  get_docker_submission:
    run: get_submission_docker.cwl
    in:
      - id: submissionid
        source: "#get_submissionid/submissionid"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: docker_repository
      - id: docker_digest
      - id: entity_id
      - id: results
      - id: admin_synid
      - id: submitter_synid

  annotate_submission_main_userid:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#get_docker_submission/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]

  run_docker:
    run: run_docker.cwl
    in:
      - id: docker_repository
        source: "#get_docker_submission/docker_repository"
      - id: docker_digest
        source: "#get_docker_submission/docker_digest"
      - id: submissionid
        source: "#submissionId"
      - id: docker_registry
        source: "#get_docker_config/docker_registry"
        # valueFrom: "docker.synapse.org"
      - id: docker_authentication
        source: "#get_docker_config/docker_authentication"
      - id: previous
        source: "#check_docker_status/finished"
      - id: parentid
        source: "#submitterUploadSynId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: input_dir
        source: "#get_dataset_info/train_volume"
      - id: docker_script
        default:
          class: File
          location: "run_synthetic_training_docker.py"
      - id: quota
        source: "#get_dataset_info/train_runtime"
    out:
      - id: predictions

  validation:
    run: validate.cwl
    in:
      - id: inputfile
        source: "#run_docker/predictions"
      - id: question
        source: "#get_dataset_info/question"
      - id: goldstandard
        source: "#download_goldstandard/filepath"
    out:
      - id: results
      - id: status
      - id: invalid_reasons
  
  validation_email:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/validate_email.cwl
    in:
      - id: submissionid
        source: "#get_submissionid/submissionid"
      - id: synapse_config
        source: "#synapseConfig"
      - id: status
        source: "#validation/status"
      - id: invalid_reasons
        source: "#validation/invalid_reasons"
      - id: errors_only
        default: true
    out: [finished]

  # Add tool to revise scores to add extra dataset queue
  modify_validation_annotations:
    run: modify_annotations.cwl
    in:
      - id: inputjson
        source: "#validation/results"
      - id: site
        source: "#get_dataset_info/site"
    out: [results]

  annotate_main_submission_with_validation:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#get_submissionid/submissionid"
      - id: annotation_values
        source: "#modify_validation_annotations/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]

  annotate_validation_with_output:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#validation/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]

  check_status:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/check_status.cwl
    in:
      - id: status
        source: "#validation/status"
      - id: previous_annotation_finished
        source: "#annotate_main_submission_with_validation/finished"
      - id: previous_email_finished
        source: "#validation_email/finished"
    out: [finished]

  scoring:
    run: score.cwl
    in:
      - id: inputfile
        source: "#run_docker/predictions"
      - id: goldstandard
        source: "#download_goldstandard/filepath"
      - id: submissionid
        source: "#submissionId"
      - id: question
        source: "#get_dataset_info/question"
      - id: previous
        source: "#check_status/finished"
    out:
      - id: results

  score_email:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/score_email.cwl
    in:
      - id: submissionid
        source: "#get_submissionid/submissionid"
      - id: synapse_config
        source: "#synapseConfig"
      - id: results
        source: "#scoring/results"
    out: []

  # Add tool to revise scores to add extra dataset queue
  modify_annotations:
    run: modify_annotations.cwl
    in:
      - id: inputjson
        source: "#scoring/results"
      - id: site
        source: "#get_dataset_info/site"
    out: [results]

  annotate_main_submission_with_scores:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#get_submissionid/submissionid"
      - id: annotation_values
        source: "#modify_annotations/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]

  # annotate internal submission with scores
  annotate_submission_with_scores:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#scoring/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]
 
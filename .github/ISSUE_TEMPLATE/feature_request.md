name: Feature request
description: Describe step-by-step workflow to create new feature
title: "[Feature Request]: "
labels: ["feature", "request"]
projects: [USACE/screening-tool-ui]
assignees: ["everyone"]

body:
  - type: markdown
    attributes:
      value: |
        Adding a feature
  - type: input
    id: contact
    attributes:
      label: Contact Details
      description: How can we get in touch with you if we need more info?
      placeholder: ex. email@example.com
    validations:
      required: false
  - type: textarea
    id: feature_request_item
    attributes:
      label: Feature request item
      description: |
        Describe the step-by-step workflow of the feature you would like to add.
        Example workflow for added features:
          1. User logs in.
          2. User creates data.
          3. [...]
      value: |
        1.
        2.
        3.
        ...
    validations:
      required: true
  - type: textarea
    id: feature_related_problem
    attributes:
      description: |
        Is the feature requested related to a problem? Please describe. Enter N/A if this is not the case.
        A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]
      label: Is the feature related to problem
    validations:
      required: true
  - type: dropdown
    id: feature_priority
    attributes:
      description: Please state the priority of this requested feature.
      label: Priority of requested feature.
      options:
          - Immediate
          - High
          - Medium
          - Low
          - Nice to have
          - Before the end of time
    validations:
      required: true
  - type: textarea
    id: feature_alternatives
    attributes:
      description: |
        Describe any alternatives you've considered.
        A clear and concise description of any alternatives.
      label: Feature alternatives
    validations:
      required: true
  - type: textarea
    id: additional_context
    attributes:
      description: |
        Add any other context or screenshots about the feature request.
      label: Additional context
    validations:
      required: true
  - type: markdown
    attributes:
      value: "Thanks for completing our form!"


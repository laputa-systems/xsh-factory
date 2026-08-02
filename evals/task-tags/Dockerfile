ARG BASE_IMAGE=xsh-factory-base:latest
FROM ${BASE_IMAGE}

# The executor mounts the shared handbook for each trial; this layer contains
# only task-specific agent instructions and review guidance.
COPY runtime/agents.md runtime/review.md /work/

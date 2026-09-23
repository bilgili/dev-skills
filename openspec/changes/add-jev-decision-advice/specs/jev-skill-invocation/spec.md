## ADDED Requirements

### Requirement: Select one Jev route per run
Before its first Jev call in a workflow run, the orchestrator SHALL select the first available route in this order: (1) an MCP (Model Context Protocol) tool from any server that asks Jev a choice question, (2) the TypeSafe HTTP API through the skill `typesafe:typesafe-ai` and its live documentation. The orchestrator SHALL find MCP routes by a tool name or description that names Jev or TypeSafe. It SHALL NOT hard-code one server. It SHALL keep the selected route for the whole run.

#### Scenario: mcpflow provides Jev
- **WHEN** the session has the mcpflow tool `jev_classify` and the skill `typesafe:typesafe-ai`
- **THEN** the orchestrator calls Jev through `jev_classify` for the whole run

#### Scenario: Only the TypeSafe skill exists
- **WHEN** the session has no Jev MCP tool and has `typesafe:typesafe-ai`
- **THEN** the orchestrator invokes the skill and calls Jev as its documentation directs

### Requirement: Frame each judgment as a Choice
The orchestrator SHALL frame each weighed choice as a Choice among the candidate options, with the decision brief as state. It SHALL use the Choice confidence for the threshold mapping. On an MCP route with threshold parameters, it SHALL pass `act_above` 0.8 and `review_above` 0.5 and SHALL NOT add a no-match option.

#### Scenario: Design-gate verdict over MCP
- **WHEN** the orchestrator weighs an APPROVE verdict through `jev_classify`
- **THEN** it asks with the options APPROVE and REJECT, `act_above` 0.8, `review_above` 0.5, and `add_none` false

### Requirement: Stop when no route exists
Before the base install, the JEV skill SHALL check for at least one route: a Jev MCP tool or `typesafe:typesafe-ai`. If no route exists, the JEV skill SHALL show the TypeSafe plugin install commands and SHALL stop before the base install.

#### Scenario: No route
- **WHEN** the session has no Jev MCP tool and no `typesafe:typesafe-ai`
- **THEN** the skill shows the install commands and does not run the base installer

### Requirement: Stop on call failure
When a Jev call fails, the orchestrator SHALL stop the workflow. It SHALL log the failed call and SHALL tell the user to check the selected route and its credentials.

#### Scenario: MCP server down
- **WHEN** a `jev_classify` call fails
- **THEN** the orchestrator logs a `channel-failed` entry and stops with a route message

### Requirement: Keep credentials out of briefs
Credentials SHALL stay in the environment or the route configuration. No brief and no log entry SHALL contain a credential.

#### Scenario: Log after a call
- **WHEN** the orchestrator logs a Jev call
- **THEN** the log entry holds no credential

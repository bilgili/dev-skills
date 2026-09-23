## ADDED Requirements

### Requirement: Orchestrator weighs choices by runtime judgment
The main-session orchestrator SHALL ask Jev when it judges that a choice needs weighting. The choice can be a subagent decision in a returned result or an orchestrator routing choice. The protocol SHALL NOT contain a fixed list of decision points. Subagents SHALL NOT call Jev.

#### Scenario: Optimizer proposal
- **WHEN** the optimizer returns a SAFE proposal and the orchestrator is unsure of the split
- **THEN** the orchestrator weighs SAFE against INTERFACE with Jev before it routes the proposal

### Requirement: Decision brief content
A decision brief SHALL contain the question, the options, the current pick, and the key evidence. The brief MAY quote excerpts from the spec, the design, the code, or the subagent result. The brief SHALL NOT contain secrets, credentials, tokens, or the contents of environment files.

#### Scenario: Brief from a verifier result
- **WHEN** the orchestrator weighs a verifier claim that a test mirrors the implementation
- **THEN** the brief quotes the test and the function under test and contains no credential

### Requirement: Jev advises and the pick stands unless the user overrides
The Jev answer SHALL be advice. The current pick SHALL stand unless the user overrides it.

#### Scenario: Jev agrees
- **WHEN** Jev answers `act` for the same option as the current pick
- **THEN** the orchestrator continues without escalation

### Requirement: Fixed confidence thresholds
The protocol SHALL map Jev confidence to an action with fixed thresholds: `act` at 0.8 or more, `review` at 0.5 or more and below 0.8, and `abstain` below 0.5.

#### Scenario: Confidence of 0.65
- **WHEN** Jev returns confidence 0.65
- **THEN** the protocol treats the answer as `review`

### Requirement: Escalate disagreement to the user
When Jev answers `act` or `review` for an option other than the current pick, the orchestrator SHALL ask the user to choose. The orchestrator SHALL batch the disagreements of one wave into one user question. On `abstain`, the current pick SHALL stand.

#### Scenario: Jev disagrees with a design-gate verdict
- **WHEN** the design gate returns APPROVE and Jev answers `act` for REJECT
- **THEN** the orchestrator asks the user to pick APPROVE or REJECT before it continues

#### Scenario: Abstain answer
- **WHEN** Jev answers `abstain`
- **THEN** the current pick stands and the orchestrator does not ask the user

### Requirement: Carry decisions into a re-dispatch
When the user overrides a subagent decision, the orchestrator SHALL re-dispatch that subagent with the user decision. The orchestrator SHALL pass every settled decision to each later dispatch of that subagent. The orchestrator SHALL NOT weigh a settled decision again.

#### Scenario: User overrides a verdict
- **WHEN** the user picks REJECT against a design-gate APPROVE
- **THEN** the orchestrator re-dispatches the design gate with the REJECT decision and does not weigh that verdict again

### Requirement: Orchestrator owns the decision log
Only the orchestrator SHALL write `openspec/changes/<change-id>/decisions.md`. Each entry SHALL hold the caller, the brief, the options, the probabilities, the confidence, the Jev action, the current pick, and the escalation outcome. The orchestrator SHALL log an escalated call after the user answers, with the outcome `user`. If the workflow stops first, the orchestrator SHALL log the call with the outcome `unresolved`. No entry SHALL stay without an outcome.

#### Scenario: Optimizer advice after archive
- **WHEN** the verifier archived the change and the orchestrator weighs an optimizer proposal
- **THEN** the orchestrator appends to `decisions.md` in `openspec/changes/archive/<date>-<change-id>/` and creates no second log

#### Scenario: Call failure while an escalation waits
- **WHEN** a disagreement waits for the user and the next Jev call fails
- **THEN** the log holds the waiting call with the outcome `unresolved` and one `channel-failed` entry

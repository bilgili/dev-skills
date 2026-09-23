---------------------------- MODULE design ----------------------------
(***************************************************************************)
(* JEV decision-advice protocol (add-jev-decision-advice).                 *)
(*                                                                         *)
(* One parallel wave: N concurrent subagents plus the main-session          *)
(* orchestrator.  Each subagent may ask JEV zero or more times, agree or   *)
(* disagree, hit a channel error, or crash.  The orchestrator is the only  *)
(* writer of decisions.md, batches ESCALATE results per wave into one user *)
(* question, re-dispatches, and stops the workflow on a channel failure.   *)
(* The orchestrator can also ask JEV itself and asks the user directly.    *)
(*                                                                         *)
(* Two switches select "design as written" (TRUE) or the proposed fix      *)
(* (FALSE):                                                                *)
(*   ReaskSettled           - no protocol rule forbids a re-dispatched     *)
(*                            agent from asking JEV again about a question *)
(*                            the user already settled.                    *)
(*   LogEscalatedBeforeUser - the orchestrator appends the ESCALATE entry  *)
(*                            before the user answers (outcome unknown).   *)
(***************************************************************************)
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS
  Agents,                 \* subagents dispatched in the wave
  MaxQ,                   \* questions per agent that may need weighting
  MaxCalls,               \* bound on total JEV calls (keeps TLC finite)
  MaxCrash,               \* crashes per agent (bound)
  MaxOrchCalls,           \* own JEV calls of the orchestrator (bound)
  ReaskSettled,
  LogEscalatedBeforeUser

ASSUME MaxQ \in Nat /\ MaxCalls \in Nat /\ MaxCrash \in Nat /\ MaxOrchCalls \in Nat
ASSUME ReaskSettled \in BOOLEAN /\ LogEscalatedBeforeUser \in BOOLEAN

Questions  == 1..MaxQ
Answers    == {"act", "review", "abstain"}
Dispatched == {"Working", "Briefed", "Asked", "Answered", "Decided",
               "Escalated", "ChannelFailed"}
Terminal   == {"Returned", "Crashed"}
NoResult   == [kind |-> "none", entries |-> << >>]

VARIABLES
  \* --- per subagent ---
  st,        \* protocol state
  q,         \* question of the current / last call
  ans,       \* JEV answer of the current call
  callId,    \* id of the current call (0 = none)
  askedQ,    \* questions asked in this dispatch
  entries,   \* JEV entries collected in this dispatch (go into the result)
  result,    \* result returned to the orchestrator (NoResult while running)
  logged,    \* orchestrator has logged this result
  settled,   \* questions the user settled; carried into the re-dispatch
  final,     \* final[a][qq] \in {"none","caller","user"}
  crashes,   \* crash count per agent
  userAsks,  \* userAsks[a][qq] = times the user was asked about (a, qq)
  \* --- JEV call bookkeeping (history, not state of the system) ---
  nextId,    \* next call id
  answered,  \* ids of calls that reached Answered
  lost,      \* answered ids whose dispatch crashed before it returned
  totalCrash,
  \* --- orchestrator ---
  log,       \* decisions.md as a sequence of entries
  phase,     \* "running" | "processing" | "stopped" | "done"
  ost, oans, oId, ooutcome, ocalls   \* the orchestrator's own JEV call

vars == << st, q, ans, callId, askedQ, entries, result, logged, settled, final,
           crashes, userAsks, nextId, answered, lost, totalCrash, log, phase,
           ost, oans, oId, ooutcome, ocalls >>

agentVars == << st, q, ans, callId, askedQ, entries, result, crashes >>
orchOwn   == << ost, oans, oId, ooutcome, ocalls >>

-----------------------------------------------------------------------------
(* Helpers *)

Cnt(id) == Cardinality({i \in DOMAIN log : log[i].id = id})
CrashEntries == Cardinality({i \in DOMAIN log : log[i].kind = "agent-crashed"})

Stopping == \/ \E a \in Agents : st[a] = "Returned" /\ result[a].kind = "CHANNEL-FAILED"
            \/ ost = "ChannelFailed"

Outcome(a, e) ==
  IF e.outcome = "escalated"
    THEN IF final[a][e.q] = "user" THEN "user"
         ELSE IF Stopping THEN "unresolved" ELSE "pending"
    ELSE e.outcome

\* The orchestrator sees only what the result carries, never agent memory.
LogEntries(a) ==
  LET es == result[a].entries IN
  [i \in DOMAIN es |->
     [agent |-> a, kind |-> "jev", id |-> es[i].id,
      outcome |-> Outcome(a, es[i])]]

Extra(a) ==
  CASE result[a].kind = "CRASHED"        -> << [agent |-> a, kind |-> "agent-crashed",  id |-> 0, outcome |-> "none"] >>
    [] result[a].kind = "CHANNEL-FAILED" -> << [agent |-> a, kind |-> "channel-failed", id |-> 0, outcome |-> "none"] >>
    [] OTHER                             -> << >>

-----------------------------------------------------------------------------
Init ==
  /\ st       = [a \in Agents |-> "Working"]
  /\ q        = [a \in Agents |-> 0]
  /\ ans      = [a \in Agents |-> "none"]
  /\ callId   = [a \in Agents |-> 0]
  /\ askedQ   = [a \in Agents |-> {}]
  /\ entries  = [a \in Agents |-> << >>]
  /\ result   = [a \in Agents |-> NoResult]
  /\ logged   = [a \in Agents |-> FALSE]
  /\ settled  = [a \in Agents |-> {}]
  /\ final    = [a \in Agents |-> [qq \in Questions |-> "none"]]
  /\ crashes  = [a \in Agents |-> 0]
  /\ userAsks = [a \in Agents |-> [qq \in Questions |-> 0]]
  /\ nextId   = 1
  /\ answered = {}
  /\ lost     = {}
  /\ totalCrash = 0
  /\ log      = << >>
  /\ phase    = "running"
  /\ ost = "Idle" /\ oans = "none" /\ oId = 0 /\ ooutcome = "none" /\ ocalls = 0

-----------------------------------------------------------------------------
(* Subagent actions.  A subagent only runs while phase = "running". *)

Brief(a) ==
  /\ phase = "running" /\ st[a] = "Working"
  /\ nextId <= MaxCalls
  /\ \E qq \in Questions :
       /\ qq \notin askedQ[a]
       /\ ReaskSettled \/ qq \notin settled[a]
       /\ q' = [q EXCEPT ![a] = qq]
       /\ askedQ' = [askedQ EXCEPT ![a] = @ \cup {qq}]
  /\ st' = [st EXCEPT ![a] = "Briefed"]
  /\ UNCHANGED << ans, callId, entries, result, logged, settled, final, crashes,
                  userAsks, nextId, answered, lost, totalCrash, log, phase >>
  /\ UNCHANGED orchOwn

Call(a) ==
  /\ phase = "running" /\ st[a] = "Briefed"
  /\ st' = [st EXCEPT ![a] = "Asked"]
  /\ callId' = [callId EXCEPT ![a] = nextId]
  /\ nextId' = nextId + 1
  /\ UNCHANGED << q, ans, askedQ, entries, result, logged, settled, final, crashes,
                  userAsks, answered, lost, totalCrash, log, phase >>
  /\ UNCHANGED orchOwn

ChannelError(a) ==
  /\ phase = "running" /\ st[a] = "Asked"
  /\ st' = [st EXCEPT ![a] = "ChannelFailed"]
  /\ UNCHANGED << q, ans, callId, askedQ, entries, result, logged, settled, final,
                  crashes, userAsks, nextId, answered, lost, totalCrash, log, phase >>
  /\ UNCHANGED orchOwn

Answer(a) ==
  /\ phase = "running" /\ st[a] = "Asked"
  /\ \E x \in Answers : ans' = [ans EXCEPT ![a] = x]
  /\ st' = [st EXCEPT ![a] = "Answered"]
  /\ answered' = answered \cup {callId[a]}
  /\ UNCHANGED << q, callId, askedQ, entries, result, logged, settled, final,
                  crashes, userAsks, nextId, lost, totalCrash, log, phase >>
  /\ UNCHANGED orchOwn

Judge(a) ==
  /\ phase = "running" /\ st[a] = "Answered"
  /\ \E agree \in BOOLEAN :
       IF ans[a] = "abstain" \/ agree
         THEN /\ st' = [st EXCEPT ![a] = "Decided"]
              /\ final' = [final EXCEPT ![a][q[a]] = "caller"]
              /\ entries' = [entries EXCEPT ![a] = Append(@,
                   [id |-> callId[a], q |-> q[a], ans |-> ans[a],
                    outcome |-> IF ans[a] = "abstain" THEN "alone" ELSE "agreed"])]
         ELSE /\ st' = [st EXCEPT ![a] = "Escalated"]
              /\ final' = final
              /\ entries' = [entries EXCEPT ![a] = Append(@,
                   [id |-> callId[a], q |-> q[a], ans |-> ans[a], outcome |-> "escalated"])]
  /\ UNCHANGED << q, ans, callId, askedQ, result, logged, settled, crashes,
                  userAsks, nextId, answered, lost, totalCrash, log, phase >>
  /\ UNCHANGED orchOwn

Continue(a) ==
  /\ phase = "running" /\ st[a] = "Decided"
  /\ st' = [st EXCEPT ![a] = "Working"]
  /\ UNCHANGED << q, ans, callId, askedQ, entries, result, logged, settled, final,
                  crashes, userAsks, nextId, answered, lost, totalCrash, log, phase >>
  /\ UNCHANGED orchOwn

ReturnResult(a, kind) ==
  /\ st' = [st EXCEPT ![a] = "Returned"]
  /\ result' = [result EXCEPT ![a] = [kind |-> kind, entries |-> entries[a]]]
  /\ UNCHANGED << q, ans, callId, askedQ, entries, logged, settled, final, crashes,
                  userAsks, nextId, answered, lost, totalCrash, log, phase >>
  /\ UNCHANGED orchOwn

Return(a) ==
  /\ phase = "running"
  /\ \/ st[a] = "Working"       /\ ReturnResult(a, "DONE")
     \/ st[a] = "Escalated"     /\ ReturnResult(a, "ESCALATE")
     \/ st[a] = "ChannelFailed" /\ ReturnResult(a, "CHANNEL-FAILED")

Crash(a) ==
  /\ phase = "running" /\ st[a] \in Dispatched /\ crashes[a] < MaxCrash
  /\ st' = [st EXCEPT ![a] = "Crashed"]
  /\ result' = [result EXCEPT ![a] = [kind |-> "CRASHED", entries |-> << >>]]
  /\ crashes' = [crashes EXCEPT ![a] = @ + 1]
  /\ totalCrash' = totalCrash + 1
  /\ lost' = lost \cup {entries[a][i].id : i \in DOMAIN entries[a]}
                  \cup (IF st[a] = "Answered" THEN {callId[a]} ELSE {})
  \* A crash loses the caller's own choices; user choices live in the orchestrator.
  /\ final' = [final EXCEPT ![a] = [qq \in Questions |-> IF @[qq] = "user" THEN "user" ELSE "none"]]
  /\ UNCHANGED << q, ans, callId, askedQ, entries, logged, settled,
                  userAsks, nextId, answered, log, phase >>
  /\ UNCHANGED orchOwn

-----------------------------------------------------------------------------
(* Orchestrator actions. *)

WaveEnd ==
  /\ phase = "running"
  /\ \A a \in Agents : st[a] \in Terminal \cup {"Finished"}
  /\ \E a \in Agents : st[a] \in Terminal
  /\ phase' = "processing"
  /\ UNCHANGED << st, q, ans, callId, askedQ, entries, result, logged, settled, final,
                  crashes, userAsks, nextId, answered, lost, totalCrash, log >>
  /\ UNCHANGED orchOwn

(* Append the entries of one result to decisions.md.  An ESCALATE result is
   logged once its outcome is known (user answered, or the workflow stops),
   unless LogEscalatedBeforeUser (design as written). *)
LogResult(a) ==
  /\ phase = "processing" /\ st[a] \in Terminal /\ ~logged[a]
  /\ result[a].kind = "ESCALATE" =>
       (LogEscalatedBeforeUser \/ final[a][q[a]] = "user" \/ Stopping)
  /\ log' = log \o LogEntries(a) \o Extra(a)
  /\ logged' = [logged EXCEPT ![a] = TRUE]
  /\ UNCHANGED << st, q, ans, callId, askedQ, entries, result, settled, final,
                  crashes, userAsks, nextId, answered, lost, totalCrash, phase >>
  /\ UNCHANGED orchOwn

(* One batched user question for every ESCALATE result of the wave. *)
AskUser ==
  /\ phase = "processing" /\ ~Stopping
  /\ LET E == {a \in Agents : st[a] = "Returned" /\ result[a].kind = "ESCALATE"
                              /\ final[a][q[a]] = "none"}
     IN /\ E # {}
        /\ final'    = [a \in Agents |-> IF a \in E THEN [final[a] EXCEPT ![q[a]] = "user"] ELSE final[a]]
        /\ settled'  = [a \in Agents |-> IF a \in E THEN settled[a] \cup {q[a]} ELSE settled[a]]
        /\ userAsks' = [a \in Agents |-> IF a \in E THEN [userAsks[a] EXCEPT ![q[a]] = @ + 1] ELSE userAsks[a]]
  /\ UNCHANGED << st, q, ans, callId, askedQ, entries, result, logged, crashes,
                  nextId, answered, lost, totalCrash, log, phase >>
  /\ UNCHANGED orchOwn

AllLogged == \A a \in Agents : st[a] \in Terminal => logged[a]

Stop ==
  /\ phase = "processing" /\ Stopping /\ AllLogged
  /\ ost \in {"Idle", "ChannelFailed"}
  /\ log' = IF ost = "ChannelFailed"
              THEN Append(log, [agent |-> "orch", kind |-> "channel-failed", id |-> 0, outcome |-> "none"])
              ELSE log
  /\ ost' = "Idle"
  /\ phase' = "stopped"
  /\ UNCHANGED << st, q, ans, callId, askedQ, entries, result, logged, settled, final,
                  crashes, userAsks, nextId, answered, lost, totalCrash, oans, oId, ooutcome, ocalls >>

(* Re-dispatch every ESCALATE (with the user choice) and every CRASHED agent.
   DONE agents finish.  Only after every result is logged. *)
Redispatch ==
  /\ phase = "processing" /\ ~Stopping /\ AllLogged /\ ost = "Idle"
  /\ \A a \in Agents : (st[a] = "Returned" /\ result[a].kind = "ESCALATE") => final[a][q[a]] = "user"
  /\ LET R == {a \in Agents : st[a] = "Crashed" \/ (st[a] = "Returned" /\ result[a].kind = "ESCALATE")}
     IN /\ st'      = [a \in Agents |-> IF a \in R THEN "Working"
                                        ELSE IF st[a] = "Returned" THEN "Finished" ELSE st[a]]
        /\ result'  = [a \in Agents |-> NoResult]
        /\ logged'  = [a \in Agents |-> FALSE]
        /\ entries' = [a \in Agents |-> IF a \in R THEN << >> ELSE entries[a]]
        \* An ESCALATE re-dispatch carries every returned decision forward;
        \* only a crash (nothing returned) starts from an empty set.
        /\ askedQ'  = [a \in Agents |-> IF a \in R /\ st[a] = "Crashed" THEN {} ELSE askedQ[a]]
        /\ callId'  = [a \in Agents |-> IF a \in R THEN 0 ELSE callId[a]]
        /\ phase'   = IF R # {} THEN "running" ELSE "done"
  /\ UNCHANGED << q, ans, settled, final, crashes, userAsks, nextId, answered, lost, totalCrash, log >>
  /\ UNCHANGED orchOwn

(* The orchestrator's own JEV call; it asks the user directly. *)
OAsk ==
  /\ phase = "processing" /\ ost = "Idle" /\ ocalls < MaxOrchCalls /\ nextId <= MaxCalls
  /\ ost' = "Asked" /\ oId' = nextId /\ nextId' = nextId + 1 /\ ocalls' = ocalls + 1
  /\ UNCHANGED << oans, ooutcome, answered, lost, totalCrash, log, phase, logged, settled, final, userAsks >>
  /\ UNCHANGED agentVars

OChannelError ==
  /\ ost = "Asked" /\ ost' = "ChannelFailed"
  /\ UNCHANGED << oans, oId, ooutcome, ocalls, nextId, answered, lost, totalCrash, log, phase, logged, settled, final, userAsks >>
  /\ UNCHANGED agentVars

OAnswer ==
  /\ ost = "Asked"
  /\ \E x \in Answers : oans' = x
  /\ ost' = "Answered" /\ answered' = answered \cup {oId}
  /\ UNCHANGED << oId, ooutcome, ocalls, nextId, lost, totalCrash, log, phase, logged, settled, final, userAsks >>
  /\ UNCHANGED agentVars

OJudge ==
  /\ ost = "Answered"
  /\ \E agree \in BOOLEAN :
       IF oans = "abstain" \/ agree
         THEN ost' = "Decided" /\ ooutcome' = (IF oans = "abstain" THEN "alone" ELSE "agreed")
         ELSE ost' = "Escalated" /\ ooutcome' = "escalated"
  /\ UNCHANGED << oans, oId, ocalls, nextId, answered, lost, totalCrash, log, phase, logged, settled, final, userAsks >>
  /\ UNCHANGED agentVars

OUser ==
  /\ ost = "Escalated" /\ ost' = "Decided" /\ ooutcome' = "user"
  /\ UNCHANGED << oans, oId, ocalls, nextId, answered, lost, totalCrash, log, phase, logged, settled, final, userAsks >>
  /\ UNCHANGED agentVars

OLog ==
  /\ ost = "Decided"
  /\ log' = Append(log, [agent |-> "orch", kind |-> "orch-jev", id |-> oId, outcome |-> ooutcome])
  /\ ost' = "Idle"
  /\ UNCHANGED << oans, oId, ooutcome, ocalls, nextId, answered, lost, totalCrash, phase, logged, settled, final, userAsks >>
  /\ UNCHANGED agentVars

-----------------------------------------------------------------------------
AgentStep == \E a \in Agents :
  Brief(a) \/ Call(a) \/ ChannelError(a) \/ Answer(a) \/ Judge(a) \/ Continue(a) \/ Return(a) \/ Crash(a)

OrchStep == WaveEnd \/ (\E a \in Agents : LogResult(a)) \/ AskUser \/ Stop \/ Redispatch
            \/ OAsk \/ OChannelError \/ OAnswer \/ OJudge \/ OUser \/ OLog

Next == AgentStep \/ OrchStep

Fairness ==
  /\ \A a \in Agents : WF_vars(Brief(a)) /\ WF_vars(Call(a)) /\ WF_vars(Answer(a))
                       /\ WF_vars(Judge(a)) /\ WF_vars(Continue(a)) /\ WF_vars(Return(a))
                       /\ WF_vars(LogResult(a))
  /\ WF_vars(WaveEnd) /\ WF_vars(AskUser) /\ WF_vars(Stop) /\ WF_vars(Redispatch)
  /\ WF_vars(OAnswer) /\ WF_vars(OJudge) /\ WF_vars(OUser) /\ WF_vars(OLog)
  \* No fairness on ChannelError, Crash, OAsk, OChannelError: failures are not forced.

Spec == Init /\ [][Next]_vars /\ Fairness

-----------------------------------------------------------------------------
(* Safety invariants *)

TypeOK ==
  /\ \A a \in Agents : st[a] \in Dispatched \cup Terminal \cup {"Finished"}
  /\ phase \in {"running", "processing", "stopped", "done"}
  /\ ost \in {"Idle", "Asked", "Answered", "Decided", "Escalated", "ChannelFailed"}

\* I1: no choice is final while it is escalated (subagent or orchestrator).
NoFinalWhileEscalated ==
  /\ \A a \in Agents :
       /\ st[a] = "Escalated" => final[a][q[a]] = "none"
       /\ (st[a] = "Returned" /\ result[a].kind = "ESCALATE" /\ userAsks[a][q[a]] = 0)
            => final[a][q[a]] = "none"
       /\ \A qq \in Questions : final[a][qq] = "user" => userAsks[a][qq] >= 1
  /\ ost = "Escalated" => ooutcome = "escalated"

\* I2a: no answered call is logged twice.
NoDoubleLog == \A id \in answered : Cnt(id) <= 1

\* I2b: at the end, every answered call that returned is logged exactly once;
\*      a call lost in a crash is logged zero times and replaced by one
\*      agent-crashed entry per crash (the accepted loss of D7).
LogComplete ==
  phase \in {"done", "stopped"} =>
    /\ \A id \in answered \ lost : Cnt(id) = 1
    /\ \A id \in lost : Cnt(id) = 0
    /\ CrashEntries = totalCrash

\* I2c: no log entry stays without its escalation outcome.
NoPendingEntry ==
  phase \in {"done", "stopped"} => \A i \in DOMAIN log : log[i].outcome # "pending"

\* I3: the user is asked at most once about one (agent, question).
NoRepeatUserQuestion == \A a \in Agents : \A qq \in Questions : userAsks[a][qq] <= 1

\* I4: after the workflow stopped, no agent is dispatched.
NoAgentAfterStop == phase = "stopped" => \A a \in Agents : st[a] \notin Dispatched

\* I5: a stopped or done workflow has processed every result.
NoUnloggedAtEnd == phase \in {"done", "stopped"} => AllLogged

-----------------------------------------------------------------------------
(* Action properties *)

\* P1: only the orchestrator writes decisions.md.
LogWrittenOnlyByOrch == [][log' # log => OrchStep]_vars

\* P2: the orchestrator never acts on (re-dispatches, finishes, stops on) a
\*     result that it has not logged.
LogBeforeAct ==
  [][(phase = "processing" /\ phase' # "processing") =>
       \A a \in Agents : st[a] \in Terminal => logged[a]]_vars

\* P3: no agent proceeds after the workflow stopped.
FrozenAfterStop == [][phase = "stopped" => UNCHANGED st]_vars

(* Liveness *)

\* L1: the workflow ends (done) or stops (channel failure).
Terminates == <>(phase \in {"done", "stopped"})

\* L2: every returned escalation gets a user choice, or the workflow stops.
EscalationResolves ==
  \A a \in Agents :
    (st[a] = "Returned" /\ result[a].kind = "ESCALATE")
      ~> ((q[a] \in Questions /\ final[a][q[a]] = "user") \/ phase = "stopped")

=============================================================================

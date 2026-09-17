```mermaid
flowchart TB
    C["Controller<br/>teleop gamepad | auto sequence | replay bag | socket agent"]
    L["Logic engine<br/>direct | cplx1: ShooterLogic, TurretLogic, MotionLogic"]
    S["Subsystems<br/>PedroDrive | stub shooter/intake/turret | Subsystems"]
    H["HAL<br/>IHal: SimHal over TCP JSON | RealHal over FTC SDK"]
    W["World<br/>re-cock-nize: pymunk | pybullet | kinematic | real robot"]
    C -->|RequestBatch| L
    L -->|subsystem calls| S
    S -->|RobotAction| H
    H -->|step JSON / hardware writes| W
    W -->|RobotState| H
    H -->|sensor reads| S
    S -->|ready / done / events| L
    L -->|Feedback| C
    R["RobotLoop<br/>sense → controller → engine → subsystems → HAL"]
    D["DebugTap<br/>one hal/subsystem/logic line per tick"]
    B["BagWriter → JSONL<br/>ReplayController + SocketController"]
    R -.drives.-> C
    R -.drives.-> L
    R -.drives.-> H
    R -.-> D
    D --> B
```
```{=latex}
\clearpage
```

```mermaid
flowchart TB
    C["Controller"] -->|RequestBatch: stream + requests + cancels| L["Logic"]
    L -->|subsystem calls| S["Subsystem"]
    S -->|RobotAction: motors + servos + events| H["HAL"]
    H -->|step JSON| W["World"]
    W -->|state JSON| H
    H -->|RobotState| S
    S -->|ready / done / events| L
    L -->|Feedback: WorldSnapshot + statuses + t| C
    T["One tick: read → sense → statuses → decide → act → update → write"]
    T -.HAL clock.-> H
```
```{=latex}
\clearpage
```

# Variant C — Follow one request

The examples use the current `robot-code` `dev-phase-1.1` head `dc4da66` and
`re-cock-nize` `dev-phase-1.1` head `518bf9c`.  IDs are illustrative values from
the real allocators (teleop starts at 10000; `SequenceRunner` starts at 1).

## 1. `SHOOT(3)` from RB to DONE

### 1.1 Press, batch, and sense

```mermaid
sequenceDiagram
    participant Pad as Gamepad GP1
    participant Ctl as TeleopController
    participant Map as TeleopMap
    participant RL as RobotLoop
    participant Eng as CplxEngine1
    Pad->>Ctl: RB rising edge in GamepadState
    Ctl->>Map: map(Buttons, Feedback)
    Map-->>Ctl: Request.shoot(10000, 3)
    Ctl-->>RL: RequestBatch(stream idle, requests [SHOOT], cancels [])
    RL->>Eng: sense(RobotState)
    Eng->>Eng: TurretLogic.update(pose), ShooterLogic.observe(pose)
    RL->>Ctl: Feedback(WorldSnapshot, prior statuses, t)
```

At this edge the exact Java record is
`Request(10000, SHOOT, double[]{3.0}, null)` inside
`RequestBatch(RequestStream.idle(), [request], new int[0])`.

```mermaid
flowchart LR
    GP["GamepadState<br/>rb=true, sticks zero"] --> Buttons["Buttons.pressed(rb)"]
    Buttons --> Map["TeleopMap"]
    Map --> Req["Request<br/>id=10000, type=SHOOT, params=[3], path=null"]
    Req --> Batch["RequestBatch<br/>stream idle, requests=[Req], cancels=[]"]
    Batch --> Logic["CplxEngine1.act"]
```

### 1.2 Spin, aim, and feed

```mermaid
sequenceDiagram
    participant RL as RobotLoop
    participant Eng as CplxEngine1
    participant Tur as TurretLogic
    participant Sho as ShooterLogic
    participant TDev as StubTurret
    participant SDev as StubShooter
    RL->>Eng: act(RequestBatch[SHOOT(10000,3)])
    Eng->>Sho: requestShot(10000,3)
    Sho->>Sho: rpm = calibratedRpm(lastPose), state = SPINNING
    Eng->>Tur: already aiming at alliance goal
    Sho->>SDev: spinUp(rpm)
    Sho->>Tur: wait for locked()
    Tur->>TDev: aimAt(GOAL_X, GOAL_Y)
    TDev-->>Tur: onTarget after STUB_TURRET_SETTLE_S
    SDev-->>Sho: isReady after STUB_SPINUP_S
    Sho->>TDev: holdForShot(true), then hold()
    Sho->>SDev: feed() for each remaining ball
    SDev-->>Eng: Event shooter.feed.start / shooter.feed.end
```

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> SPINNING: requestShot(10000,3) -> ACTIVE
    SPINNING --> SPINNING: shooter not ready or turret not locked
    SPINNING --> FEEDING: ready and locked
    FEEDING --> FEEDING: stub feed window 0.2 s
    FEEDING --> SPINNING: balls remain
    FEEDING --> DONE: remaining == 0
    DONE --> IDLE: next update
    SPINNING --> IDLE: cancel(id) or CANCEL_ALL
    FEEDING --> IDLE: cancel(id) or CANCEL_ALL
```

The current stub has no physical feeder/servo model.  Its downward record is
`RobotAction(motors={}, servos={}, events=[Event("shooter.feed.start", t, {})])`
then a matching `shooter.feed.end`; a future real subsystem would own any servo pulse.

### 1.3 Action, HAL, and completion feedback

```mermaid
sequenceDiagram
    participant Eng as CplxEngine1
    participant U as Subsystems
    participant H as IHal
    participant W as sim.server / real hardware
    participant Ctl as TeleopController
    Eng->>U: update(RobotAction.Builder)
    U-->>Eng: RobotAction(motors,servos,events)
    Eng-->>H: RobotLoop writes RobotAction
    alt SimHal
        H->>W: step {dt_ms,motors,servos,events}
        W-->>H: state {enc,vel,imu,pinpoint,voltage,gamepad,truth}
    else RealHal
        H->>W: FTC motor and servo writes
        W-->>H: sensor sample
    end
    H-->>Ctl: next tick Feedback with ACTIVE/DONE statuses
    Ctl->>Ctl: status id 10000 becomes DONE after final feed
```

```mermaid
flowchart LR
    F0["Feedback at t0<br/>prior statuses"] --> Decide["decide() -> SHOOT batch"]
    Decide --> Act["ShooterLogic state machine"]
    Act --> Active["RequestStatus(10000, ACTIVE, progress, note)"]
    Active --> Next["Feedback at t1"]
    Act --> Done["RequestStatus id=10000, DONE, progress=1.0"]
    Done --> Final["Feedback at tN+1<br/>controller observes DONE"]
```
```{=latex}
\clearpage
```

## 2. `GOTO(path)` / `PATH` from auto to drive completion

### 2.1 Auto builder emits the path record

```mermaid
sequenceDiagram
    participant Auto as AutoController
    participant Seq as SequenceRunner
    participant RL as RobotLoop
    participant Eng as CplxEngine1
    participant Mot as MotionLogic
    Auto->>Seq: AutoStep.Path(PathRequest, startPose)
    Seq->>Seq: allocate id 1, phase READY -> MOTION
    Seq-->>Auto: RequestBatch(stream idle, requests [PATH], cancels [])
    Auto-->>RL: decide(Feedback) -> batch
    RL->>Eng: act(batch)
    Eng->>Mot: act(stream, requests, cancels, statuses)
    Mot->>Mot: validate path and create MotionJob(id=1)
    Mot-->>Eng: ACTIVE status, note following
```

```mermaid
flowchart TB
    P["PathRequest<br/>pathId=null, target=null"]
    Seg["segments=[{kind=line,end={x:36,y:96,h:0}}]"]
    Hdg["heading={mode:CONSTANT,start:0,end:0}"]
    Cst["constraints={maxPower:1,maxVelocity:MAX}"]
    P --> Seg
    P --> Hdg
    P --> Cst
    P --> Req["Request(id=1,type=PATH,params=[],path=P)"]
    Req --> Batch["RequestBatch(idle,[Req],[])"]
```

The canonical logic-seam JSON uses these exact keys (from `SeamJson.path`):

```json
{"seam":"logic","t_ms":1000,"batch":{"stream":{"vx":0.0,"vy":0.0,"omega":0.0,"manualDrive":false},"requests":[{"id":1,"type":"PATH","params":[],"path":{"pathId":null,"target":null,"constraints":{"maxPower":1.0,"maxVelocity":1.7976931348623157E308},"segments":[{"kind":"line","end":{"x":36.0,"y":96.0,"h":0.0}}],"heading":{"mode":"CONSTANT","start":0.0,"end":0.0},"holdEnd":true,"velocityConstraint":null,"braking":null}}],"cancels":[]}}
```

### 2.2 Pedro, action, and DONE

```mermaid
sequenceDiagram
    participant Eng as CplxEngine1
    participant Mot as MotionLogic
    participant Drive as PedroDrive
    participant Hal as IHal
    participant World as sim.server
    participant Seq as SequenceRunner
    Eng->>Mot: PATH request id 1
    Mot->>Drive: follow(PathRequest)
    Drive-->>Mot: pathDone = false
    Mot-->>Eng: ACTIVE(1,0.0,"following")
    Eng->>Drive: update -> motor powers
    Eng->>Hal: write RobotAction
    Hal->>World: step JSON each dt_ms
    World-->>Hal: RobotState and Pinpoint pose
    loop ticks until pathDone
        Eng->>Mot: act idle batch
        Mot->>Drive: pathDone()
        Mot-->>Eng: ACTIVE(1,0.0,"following")
    end
    Drive-->>Mot: pathDone = true
    Mot-->>Eng: DONE(1,1.0,"")
    Eng-->>Seq: drainStatuses next tick
    Seq->>Seq: advance AutoSequence
```

```mermaid
stateDiagram-v2
    [*] --> READY: SequenceRunner
    READY --> MOTION: emit PATH id=1
    MOTION --> MOTION: no status or ACTIVE
    MOTION --> READY: DONE id=1
    READY --> REQUEST: next AutoStep
    MOTION --> READY: REJECTED / FAILED -> sequence failure
```

`GOTO` is the three-number request form (`[x,y,headingRad]`) consumed by the
same `MotionLogic.start` path; an auto builder normally emits `PATH` with a
`PathRequest` instead.  A busy drive or malformed path is `REJECTED`, never guessed.
```{=latex}
\clearpage
```

## 3. `SWITCH_ENGINE` at a loop boundary

### 3.1 START gesture to selection

```mermaid
sequenceDiagram
    participant Pad as Gamepad START
    participant Map as TeleopMap
    participant RL as RobotLoop
    participant Old as current engine
    participant New as selected engine
    Pad->>Map: held continuously for 1.0 s
    Map->>Map: toggle nextEngineIndex 1 <-> 0
    Map-->>RL: RequestBatch(requests [SWITCH_ENGINE(id, index)])
    RL->>RL: switchIndex validates integral range
    RL->>Old: act(RequestBatch.cancelAll())
    Old-->>RL: drainStatuses for cancelled jobs
    RL->>New: setEngine(index)
    RL->>New: next tick starts with sense(state)
```

```mermaid
flowchart LR
    Hold["START held ≥ 1000 ms"] --> Req["Request(id=10001,type=SWITCH_ENGINE,params=[0])"]
    Req --> Batch["RequestBatch(stream, [Req], [])"]
    Batch --> Validate["RobotLoop.switchIndex"]
    Validate --> Cancel["old.act(RequestBatch.cancelAll())"]
    Cancel --> Zero["current switch tick: RobotAction.zero()"]
    Zero --> Next["target engine sense/act next tick"]
```

### 3.2 Exact handoff records and feedback

```mermaid
sequenceDiagram
    participant C as TeleopController
    participant R as RobotLoop
    participant D as DirectEngine index 0
    participant X as CplxEngine1 index 1
    participant H as IHal
    C-->>R: RequestBatch(stream, [Request(10001,SWITCH_ENGINE,[0],null)], [])
    R->>D: act(CANCEL_ALL) if D was current
    R->>X: setEngine(cplx1) if index 1 selected
    R->>H: write(RobotAction.zero()) on switch tick
    R-->>C: next Feedback includes DONE(10001) or REJECTED validation
    R->>X: next tick sense -> decide -> act
```

```mermaid
stateDiagram-v2
    [*] --> RunningDirect
    RunningDirect --> SwitchRequested: valid SWITCH_ENGINE(1)
    RunningDirect --> RunningDirect: invalid index / multiple request -> REJECTED
    SwitchRequested --> Quiesce: old engine gets CANCEL_ALL
    Quiesce --> RunningCplx1: target selected, zero action this tick
    RunningCplx1 --> SwitchRequested: valid SWITCH_ENGINE(0)
    RunningCplx1 --> RunningCplx1: ordinary batch
```

The factory order is index `0 = direct`, `1 = cplx1`.  `SWITCH_ENGINE` never
reaches `DirectMap` or a cplx module; `RobotLoop` strips it, and statuses are
visible upward one tick later.
```{=latex}
\clearpage
```

## 4. The same seams in JSONL

```mermaid
flowchart TB
    Frame["DebugFrame<br/>RobotState + RobotAction + Feedback + RequestBatch"]
    Frame --> Hal["hal line<br/>state.enc, vel, yaw, pinpoint, voltage<br/>action.motors, servos, events"]
    Frame --> Sub["subsystem line<br/>calls[{sub,op,args}], events[]"]
    Frame --> Logic["logic line<br/>feedback.snapshot/statuses<br/>batch.stream/requests/cancels"]
    Hal --> Bag["BagWriter JSONL"]
    Sub --> Bag
    Logic --> Bag
    Bag --> Replay["ReplayController reads logic batches"]
```

```mermaid
sequenceDiagram
    participant RL as RobotLoop
    participant Tap as DebugTap
    participant Bag as BagWriter
    participant Rep as ReplayController
    participant Sock as SocketController
    RL->>Tap: offer immutable DebugFrame
    Tap->>Bag: one header, then hal/subsystem/logic at t_ms
    Rep->>Bag: read logic JSONL
    Bag-->>Rep: RequestBatch list, start_pose, engine
    Sock->>RL: latest valid RequestBatch via decide
    RL-->>Sock: Feedback JSON queue
    Note over Sock: 250 ms without valid input -> CANCEL_ALL once, then idle
```

`RobotState` never carries simulator `truth`; it is retained only by `SimHal`
for tests/viewer.  The record path is the same on the real robot and simulator;
only `IHal` changes.

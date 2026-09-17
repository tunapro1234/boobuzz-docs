```mermaid
flowchart TB
    C["Controller<br/>teleop gamepad | auto | replay bag | socket agent"]
    L["Logic engine<br/>direct | cplx1: ShooterLogic, TurretLogic, MotionLogic"]
    S["Subsystems<br/>PedroDrive | stub shooter/intake/turret | Subsystems"]
    H["HAL<br/>IHal: SimHal over TCP JSON | RealHal over FTC SDK"]
    W["World<br/>re-cock-nize Python: pymunk | pybullet | kinematic | real robot"]
    C -->|RequestBatch| L
    L -->|subsystem calls| S
    S -->|RobotAction| H
    H -->|step JSON / hardware writes| W
    W -->|RobotState| H
    H -->|read sensors| S
    S -->|ready / done / events| L
    L -->|Feedback| C
    R["RobotLoop<br/>sense → controller → engine → subsystems → HAL"]
    D["DebugTap<br/>hal | subsystem | logic, one line/tick"]
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
    C["Controller"] -->|RequestBatch<br/>stream + requests + cancels| L["Logic"]
    L -->|Drive / shooter / intake / turret calls| S["Subsystem"]
    S -->|RobotAction<br/>motors + servos + events| H["HAL"]
    H -->|step JSON| W["World"]
    W -->|state JSON| H
    H -->|RobotState| S
    S -->|ready / done / events| L
    L -->|Feedback<br/>WorldSnapshot + statuses + t| C
    T["One RobotLoop tick<br/>read → sense → statuses → decide → act → update → write"]
    T -.clocked by.-> H
```
```{=latex}
\clearpage
```
## Seam records

```mermaid
classDiagram
    class RequestBatch { +RequestStream stream; +List~Request~ requests; +int[] cancels }
    class RequestStream { +double vx; +double vy; +double omega; +boolean manualDrive }
    class Request { +int id; +RequestType type; +double[] params; +PathRequest path }
    class Feedback { +WorldSnapshot world; +List~RequestStatus~ statuses; +long t }
    class WorldSnapshot { +long t; +Pose pose; +double yaw; +double voltage }
    class RequestStatus { +int id; +State state; +double progress; +String note }
    class RobotState { +long t; +Map enc; +Map vel; +double yaw; +Pose pinpoint; +double voltage }
    class RobotAction { +Map motors; +Map servos; +List~Event~ events }
    RequestBatch --> RequestStream
    RequestBatch --> Request
    Feedback --> WorldSnapshot
    Feedback --> RequestStatus
    RobotState --> WorldSnapshot
    RobotAction --> Event
```

The immutable records are the only cross-layer vocabulary.  `PATH` alone carries
`PathRequest`; `CANCEL_ALL` is `Integer.MIN_VALUE`.

```mermaid
sequenceDiagram
    participant H as IHal
    participant R as RobotLoop
    participant E as IRobotEngine
    participant C as IController
    H->>R: read() -> RobotState
    R->>E: sense(state) -> WorldSnapshot
    E-->>R: drainStatuses() -> previous statuses
    R->>C: Feedback(snapshot,statuses,t)
    C-->>R: RequestBatch
    R->>E: act(batch)
    E-->>R: action() -> RobotAction
    R->>H: write(action)
```
## Package and engines

```mermaid
flowchart LR
    Contract["core.contract<br/>records"] --> HAL["core.hal<br/>IHal + RobotConstants"]
    Contract --> Logic["core.logic<br/>IRobotEngine"]
    HAL --> Sub["core.subsystem<br/>interfaces + Pedro/stubs"]
    Sub --> Logic
    Contract --> Controller["core.controller<br/>teleop / auto / replay / socket"]
    Core["core<br/>RobotLoop + RobotFactory"] --> Contract
    Core --> HAL
    Core --> Sub
    Core --> Logic
    Core --> Controller
    Team["TeamCode FTC<br/>RealHal + opmodes"] --> Core
    Sim[":sim Java<br/>SimHal + SimMain"] --> Core
    Sim --> Py["re-cock-nize sim.server"]
```

```mermaid
classDiagram
    class IRobotEngine { +String name(); +WorldSnapshot sense(RobotState); +void act(RequestBatch); +RobotAction action(); +List~RequestStatus~ drainStatuses() }
    class DirectEngine { -Subsystems subsystems; -DirectMap map; -Job driveJob; -Job shooterJob }
    class CplxEngine1 { -MotionLogic motion; -TurretLogic turret; -ShooterLogic shooter; -Subsystems subsystems }
    class MotionLogic { +act(RequestStream,List~Request~,int[],List); +cancelAll(List); +resetPose(Pose,List) }
    class TurretLogic { +update(Pose); +holdForShot(boolean); +locked() }
    class ShooterLogic { +requestShot(int,int); +requestSpinUp(int,double); +update(List); +cancelAll(List) }
    IRobotEngine <|.. DirectEngine
    IRobotEngine <|.. CplxEngine1
    CplxEngine1 *-- MotionLogic
    CplxEngine1 *-- TurretLogic
    CplxEngine1 *-- ShooterLogic
```

Direct maps each edge request with `DirectMap`; cplx1 delegates policy to three
logic modules over one `Subsystems` record.

```mermaid
flowchart TB
    GP["GamepadState"] --> Buttons["Buttons<br/>pressed / held / toggle"]
    Buttons --> Teleop["TeleopMap<br/>stream + edge requests"]
    Teleop --> TC["TeleopController<br/>Y SequenceRunner"]
    Auto["AutoController<br/>SequenceRunner"] --> Batch["RequestBatch"]
    TC --> Batch
    Replay["ReplayController<br/>logic seam JSONL"] --> Batch
    Socket["SocketController<br/>JSONL + watchdog"] --> Batch
    Batch --> Loop["RobotLoop"]
```
## Requests and arbitration

```mermaid
stateDiagram-v2
    [*] --> ACTIVE: valid request accepted
    ACTIVE --> ACTIVE: progress / same tick
    ACTIVE --> DONE: subsystem reports complete
    ACTIVE --> REJECTED: cancel(id) / CANCEL_ALL / manual override
    ACTIVE --> FAILED: engine failure
    REJECTED --> [*]
    FAILED --> [*]
    DONE --> [*]
```

```mermaid
flowchart LR
    Batch["RequestBatch"] --> Stream["RequestStream<br/>level: vx, vy, omega, manualDrive"]
    Batch --> Edge["Request[]<br/>id + type + params/path"]
    Batch --> Cancel["cancels[]<br/>IDs or CANCEL_ALL"]
    Stream --> Motion["DirectEngine / MotionLogic"]
    Edge --> Motion
    Edge --> Shooter["DirectMap / ShooterLogic"]
    Edge --> Intake["IIntake"]
    Edge --> Turret["DirectMap / TurretLogic"]
    Cancel --> Motion
    Cancel --> Shooter
```

```mermaid
flowchart TB
    Input["manual stream"] -->|owner| Manual["drive.manual(vx,vy,omega)"]
    Input -->|cancels| Active["active GOTO / PATH / TURN_TO"]
    Edge["edge drive request"] -->|if no manual + no active| Follow["drive.follow / turnTo"]
    Edge -->|busy or manual| Reject["REJECTED status"]
    Idle["no manual, no edge, no active"] --> Stop["drive.stop()"]
    Active -->|pathDone| Done["DONE status"]
```

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> SPINNING: SHOOT(3) / SPIN_UP
    SPINNING --> SPINNING: !ready or !turret.locked
    SPINNING --> FEEDING: ready + locked
    FEEDING --> FEEDING: stub isFeeding()
    FEEDING --> SPINNING: next ball remains
    FEEDING --> DONE: remaining == 0
    DONE --> IDLE: next update
    SPINNING --> IDLE: cancelAll / cancel(id)
    FEEDING --> IDLE: cancelAll / cancel(id)
```
```mermaid
stateDiagram-v2
    [*] --> AIM
    AIM: targetKnown = true; aimAt(alliance goal)
    AIM --> HOLD: holdForShot(true)
    HOLD: turret.hold() while feeding
    HOLD --> AIM: holdForShot(false)
    [*] --> SCAN: robot pose is null
    SCAN: targetKnown = false; turret.scan()
    SCAN --> AIM: pose becomes available
```

```mermaid
sequenceDiagram
    participant GP as START held 1 s
    participant T as TeleopMap
    participant R as RobotLoop
    participant Old as old engine
    participant New as selected engine
    GP->>T: pressed/held edge
    T-->>R: RequestBatch[SWITCH_ENGINE(index)]
    R->>Old: act(CANCEL_ALL)
    R->>Old: drainStatuses()
    R->>New: select at loop boundary
    R->>R: strip SWITCH_ENGINE, action = zero
    R->>New: next tick sense / act
```

The factory orders index 0 = `direct`, index 1 = `cplx1`; switch statuses are
made by `RobotLoop` and are visible one tick later.

## Debug seams

```mermaid
flowchart LR
    Loop["RobotLoop thread<br/>immutable DebugFrame"] -->|offer| Q["global ArrayBlockingQueue<br/>capacity 512"]
    Q --> D["dispatch thread"]
    D --> Bag["BagWriter<br/>header + 3 JSONL lines"]
    D --> CQs["per-client queues<br/>capacity 512"]
    CQs --> W1["client writer thread"]
    CQs --> W2["client writer thread"]
    Trace["SubsystemTrace wrappers<br/>drive/shooter/intake/turret"] --> Loop
    W1 --> Client["tap client"]
    W2 --> Client
```

```mermaid
sequenceDiagram
    participant RL as RobotLoop
    participant Tap as DebugTap
    participant Bag as BagWriter
    participant Replay as ReplayController
    RL->>Tap: DebugFrame(state, action, calls, feedback, batch)
    Tap->>Bag: header {bag,engine,controller,constants_hash}
    Tap->>Bag: hal + subsystem + logic at t_ms
    Replay->>Bag: read UTF-8 JSONL
    Bag-->>Replay: start_pose + logic RequestBatch list
    Replay->>RL: decide returns next batch
    RL->>RL: same engine/HAL tick
```

```mermaid
sequenceDiagram
    participant Agent as socket agent
    participant Reader as reader thread
    participant Latest as atomic latest batch
    participant RL as RobotLoop
    participant Out as feedback writer
    Agent->>Reader: JSONL RequestBatch
    Reader->>Latest: valid batch + watchdog timestamp
    RL->>Latest: decide Feedback
    RL->>Out: bounded Feedback queue
    Out-->>Agent: {type:"feedback",t_ms,feedback}
    Note over Reader,RL: invalid JSON never refreshes 250 ms watchdog
    RL-->>RL: first timeout -> CANCEL_ALL, then idle
```
## Simulator

```mermaid
sequenceDiagram
    participant Java as SimHal
    participant TCP as TCP JSONL
    participant Py as sim.server
    participant Phys as PhysicsBackend
    Java->>TCP: reset {seed, pose{x,y,h}}
    Py->>Phys: reset(seed, pose)
    Py-->>TCP: ready {proto,motors,servos,state(t_ms=0)}
    TCP-->>Java: ready
    loop one RobotLoop tick
        Java->>TCP: step {dt_ms,motors,servos,events}
        Py->>Phys: step(dt_ms,powers,events)
        Phys-->>Py: state + truth
        Py-->>TCP: state {enc,vel,imu,pinpoint,voltage,gamepad,truth}
        TCP-->>Java: state
    end
    Java->>TCP: bye
```

```mermaid
classDiagram
    class PhysicsBackend { +reset(seed, pose); +step(dt_ms,powers,events); +state(dt) }
    class MotorModel { +MecanumKinematics kin; +MotorSim motors; +step(); +state() }
    class MotorSim { +target_rpm(power); +step(power,dt); +advance_encoder() }
    class PymunkBackend
    class PyBulletBackend
    class KinematicBackend
    class MultiRobotWorld { +backends[]; +step(powers,dt_ms) }
    PhysicsBackend <|.. PymunkBackend
    PhysicsBackend <|.. PyBulletBackend
    PhysicsBackend <|.. KinematicBackend
    PhysicsBackend *-- MotorModel
    MotorModel *-- MotorSim
    MultiRobotWorld o-- PhysicsBackend
```

```mermaid
sequenceDiagram
    participant C0 as client :5555
    participant C1 as client :5556
    participant S as SimServer --robots 2
    participant W as MultiRobotWorld
    C0->>S: reset(seed,pose)
    C1->>S: reset(seed,pose)
    S-->>C0: ready(epoch E)
    S-->>C1: ready(epoch E)
    par same epoch, same dt
        C0->>S: step(dt_ms,powers0)
        C1->>S: step(dt_ms,powers1)
    end
    S->>W: step([powers0,powers1],dt_ms)
    W-->>S: state for both bodies
    S-->>C0: state + gamepad
    S-->>C1: state + gamepad
    Note over S: missing client after 2 s is evicted, late reset starts a new epoch
```

## Boundaries at a glance

```mermaid
flowchart LR
    JavaCore[":core<br/>no FTC / no Python"] -->|IHal + JSON| JavaSim[":sim SimHal"]
    JavaSim -->|TCP 127.0.0.1:5555| Python["re-cock-nize<br/>server + viewer"]
    Python -->|shared motor model| Backends["pymunk / pybullet / kinematic"]
    Real["RealHal"] -->|FTC SDK| Hardware["motors + servos + sensors"]
    Config["RobotConstants.java"] -.regex reader.-> Python
```

```mermaid
flowchart TB
    GP["GP1 left stick / right X"] --> Stream["RequestStream(vx,vy,omega,manualDrive)"]
    RB["RB press"] --> Shoot["Request.shoot(id,3)"]
    LB["LB edge"] --> Intake["INTAKE_ON / INTAKE_OFF"]
    Back["BACK press"] --> Reset["RESET_POSE(constants)"]
    Y["Y press"] --> Seq["AutoSequence: PATH → SHOOT(3)"]
    Start["START held 1 s"] --> Switch["SWITCH_ENGINE(0 or 1)"]
    Stream --> Batch["RequestBatch"]
    Shoot --> Batch
    Intake --> Batch
    Reset --> Batch
    Seq --> Batch
    Switch --> Batch
```

The poster intentionally leaves no policy in the HAL and no hardware knowledge in
controllers; records and arrows are the contract.

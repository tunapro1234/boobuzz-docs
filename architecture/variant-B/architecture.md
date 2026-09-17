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
    R["RobotLoop<br/>one fixed tick"]
    D["DebugTap<br/>hal / subsystem / logic"]
    B["BagWriter JSONL<br/>Replay + Socket controllers"]
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
    C["Controller"] -->|RequestBatch: stream, requests, cancels| L["Logic"]
    L -->|drive / shooter / intake / turret calls| S["Subsystem"]
    S -->|RobotAction: motors, servos, events| H["HAL"]
    H -->|step JSON| W["World"]
    W -->|state JSON| H
    H -->|RobotState| S
    S -->|ready / done / events| L
    L -->|Feedback: WorldSnapshot, statuses, t| C
    T["RobotLoop tick: read, sense, decide, act, update, write"]
    T -.HAL clock.-> H
```
```{=latex}
\clearpage
```

# Variant B — Layer handbook

The handbook follows the runtime stack from the controller down to the world.
Solid arrows are calls or records; dotted arrows are orchestration rails.  Sources
are the current `robot-code` `dev-phase-1.1` head `dc4da66` and
`re-cock-nize` `dev-phase-1.1` head `518bf9c`.

## 1. Controller

```mermaid
flowchart TB
    C["Controller<br/>ACTIVE"]
    L["Logic engine<br/>dim"]
    S["Subsystem<br/>dim"]
    H["HAL<br/>dim"]
    W["World<br/>dim"]
    C -->|RequestBatch| L
    L -->|subsystem calls| S
    S -->|RobotAction| H
    H -->|step JSON| W
    W -->|RobotState| H
    L -->|Feedback| C
    R["RobotLoop drives all layers"] -.-> C
    classDef active fill:#cfe8ff,stroke:#1473b9,stroke-width:3px
    classDef dim fill:#eeeeee,stroke:#aaaaaa,color:#666666
    class C active
    class L,S,H,W dim
```

| Method | Arguments | Returns | Caller / consumer |
|---|---|---|---|
| `IController.decide` | `Feedback(world, statuses, t)` | `RequestBatch(stream, requests, cancels)` | `RobotLoop`; engine consumes the batch |
| `TeleopController.decide` | HAL `GamepadState`, prior `Feedback` | mapped batch, optionally merged with `SequenceRunner` | live teleop |
| `AutoController.decide` | `Feedback` | next immutable auto batch | FTC autonomous opmode |
| `ReplayController.decide` | ignored feedback | next logic batch from JSONL, then idle | bag replay |
| `SocketController.decide` | `Feedback` | latest valid batch; timeout emits `CANCEL_ALL` once | external agent |

```mermaid
sequenceDiagram
    participant H as IHal
    participant R as RobotLoop
    participant C as IController
    H->>R: read -> RobotState
    R->>C: Feedback(WorldSnapshot, statuses, t)
    C-->>R: RequestBatch
    R->>R: strip SWITCH_ENGINE at boundary
```

- `Buttons` is controller-only edge and hold state; it never references a device.
- `TeleopMap` maps sticks to `RequestStream`; RB emits `SHOOT(3)`, LB toggles intake.
- Y starts a short `AutoSequence`; BACK emits compile-time `RESET_POSE`.
- START held for one second emits one `SWITCH_ENGINE` request.
- Manual stick input cancels the sequence-owned IDs before returning the batch.
- Controllers must not import `IHal`, `PedroDrive`, physics, or FTC classes.

```mermaid
classDiagram
    class IController { +RequestBatch decide(Feedback) }
    class TeleopController { -IGamepadSource gamepads; -TeleopMap map; -SequenceRunner runner }
    class TeleopMap { +Mapping map(Buttons,Feedback); +RequestBatch batch(Buttons,Feedback) }
    class AutoController { -SequenceRunner runner; +RequestBatch decide(Feedback) }
    class ReplayController { -List~RequestBatch~ batches; +RequestBatch decide(Feedback) }
    class SocketController { -AtomicReference latest; +RequestBatch decide(Feedback) }
    IController <|.. TeleopController
    IController <|.. AutoController
    IController <|.. ReplayController
    IController <|.. SocketController
    TeleopController --> TeleopMap
    TeleopController --> SequenceRunner
```
```{=latex}
\clearpage
```

## 2. Logic engine

```mermaid
flowchart TB
    C["Controller<br/>dim"]
    L["Logic engine<br/>ACTIVE"]
    S["Subsystem<br/>dim"]
    H["HAL<br/>dim"]
    W["World<br/>dim"]
    C -->|RequestBatch| L
    L -->|subsystem calls| S
    S -->|RobotAction| H
    H -->|step JSON| W
    W -->|RobotState| H
    S -->|ready / done / events| L
    L -->|Feedback| C
    classDef active fill:#cfe8ff,stroke:#1473b9,stroke-width:3px
    classDef dim fill:#eeeeee,stroke:#aaaaaa,color:#666666
    class L active
    class C,S,H,W dim
```

| Method | Arguments | Returns / side effect | Caller / consumer |
|---|---|---|---|
| `IRobotEngine.name` | none | `direct` or `cplx1` | `RobotFactory`, bags |
| `IRobotEngine.sense` | `RobotState` | `WorldSnapshot`; calls `Subsystems.observe` | `RobotLoop` |
| `IRobotEngine.act` | `RequestBatch` | updates jobs and subsystem commands | `RobotLoop` |
| `IRobotEngine.action` | none | latest `RobotAction` | `RobotLoop` → HAL |
| `IRobotEngine.drainStatuses` | none | statuses from preceding act | `RobotLoop` → controller next tick |
| `DirectEngine` | `Subsystems` + `DirectMap` | stream arbitration and edge jobs | `RobotFactory` |
| `CplxEngine1` | `Subsystems` + three logic modules | automatic aim, motion, shooter sequencing | `RobotFactory` |

```mermaid
sequenceDiagram
    participant R as RobotLoop
    participant E as IRobotEngine
    participant M as MotionLogic / DirectMap
    participant S as ShooterLogic
    participant U as Subsystems
    R->>E: sense(RobotState)
    E->>U: observe(state)
    R->>E: act(RequestBatch)
    E->>M: stream + drive requests + cancels
    E->>S: SHOOT / SPIN_UP / cancel
    M->>U: drive calls
    S->>U: shooter calls
    U-->>E: statuses + RobotAction
```

- `DirectEngine` owns one drive job and one shooter job; `DirectMap` rejects busy work.
- `CplxEngine1` owns `MotionLogic`, `TurretLogic`, `ShooterLogic`, and intake ownership.
- `MotionLogic` arbitrates manual stream against `GOTO`, `PATH`, and `TURN_TO`.
- `TurretLogic` aims automatically at the alliance goal and holds during feeding.
- `ShooterLogic.State` is `IDLE`, `SPINNING`, `FEEDING`, or `DONE`.
- Individual shooter cancel IDs are honored by cplx1; `CANCEL_ALL` is always honored.
- `RESET_POSE` reaches cplx1's handler through `MotionLogic`; `RobotLoop` owns switching.

```mermaid
classDiagram
    class IRobotEngine { +sense(RobotState); +act(RequestBatch); +action(); +drainStatuses() }
    class DirectEngine { -DirectMap map; -Job driveJob; -Job shooterJob }
    class CplxEngine1 { -MotionLogic motion; -TurretLogic turret; -ShooterLogic shooter }
    class MotionLogic { +act(RequestStream,List,int[],List); +cancelAll(List); +resetPose(Pose,List) }
    class TurretLogic { +update(Pose); +locked(); +holdForShot(boolean) }
    class ShooterLogic { +requestShot(int,int); +requestSpinUp(int,double); +update(List); +cancel(int,List) }
    IRobotEngine <|.. DirectEngine
    IRobotEngine <|.. CplxEngine1
    CplxEngine1 *-- MotionLogic
    CplxEngine1 *-- TurretLogic
    CplxEngine1 *-- ShooterLogic
```
```{=latex}
\clearpage
```

## 3. Subsystem

```mermaid
flowchart TB
    C["Controller<br/>dim"]
    L["Logic<br/>dim"]
    S["Subsystem<br/>ACTIVE"]
    H["HAL<br/>dim"]
    W["World<br/>dim"]
    C -->|RequestBatch| L
    L -->|IDrive / IShooter / IIntake / ITurret| S
    S -->|RobotAction| H
    H -->|step JSON| W
    W -->|RobotState| H
    S -->|ready / done / events| L
    classDef active fill:#cfe8ff,stroke:#1473b9,stroke-width:3px
    classDef dim fill:#eeeeee,stroke:#aaaaaa,color:#666666
    class S active
    class C,L,H,W dim
```

| Interface | Methods | Implementation(s) | Owner above the seam |
|---|---|---|---|
| `ISubsystem` | `observe(RobotState)`, `update(RobotAction.Builder)` | all mechanisms | `Subsystems` fixed order |
| `IDrive` | `manual`, `follow`, `turnTo`, `stop`, `resetPose`, `pathDone`, `pose` | `PedroDrive` | DirectMap / MotionLogic |
| `IShooter` | `spinUp`, `spinDown`, `isReady`, `feed`, `isFeeding` | `StubShooter` | DirectMap / ShooterLogic |
| `IIntake` | `run`, `stop`, `hasBall` | `StubIntake` | engines |
| `ITurret` | `aimAt`, `scan`, `hold`, `onTarget`, `angleRad` | `StubTurret` | DirectMap / TurretLogic |
| `Subsystems` | `observe`, `update` | record of four interfaces | both engines |

```mermaid
classDiagram
    class ISubsystem { +observe(RobotState); +update(RobotAction.Builder) }
    class IDrive { +manual(vx,vy,omega); +follow(PathRequest); +turnTo(h); +stop(); +resetPose(Pose); +pathDone(); +pose() }
    class IShooter { +spinUp(rpm); +spinDown(); +isReady(); +feed(); +isFeeding() }
    class IIntake { +run(power); +stop(); +hasBall() }
    class ITurret { +aimAt(x,y); +scan(); +hold(); +onTarget(); +angleRad() }
    class PedroDrive
    class StubShooter
    class StubIntake
    class StubTurret
    class Subsystems { +IDrive drive; +IShooter shooter; +IIntake intake; +ITurret turret }
    ISubsystem <|-- IDrive
    ISubsystem <|-- IShooter
    ISubsystem <|-- IIntake
    ISubsystem <|-- ITurret
    IDrive <|.. PedroDrive
    IShooter <|.. StubShooter
    IIntake <|.. StubIntake
    ITurret <|.. StubTurret
    Subsystems o-- IDrive
    Subsystems o-- IShooter
    Subsystems o-- IIntake
    Subsystems o-- ITurret
```

```mermaid
sequenceDiagram
    participant E as engine
    participant U as Subsystems
    participant D as PedroDrive
    participant Sh as StubShooter
    participant I as StubIntake
    participant T as StubTurret
    E->>U: observe(RobotState)
    U->>D: observe
    U->>Sh: observe
    U->>I: observe
    U->>T: observe
    E->>D: manual / follow
    E->>Sh: spinUp / feed
    E->>T: aimAt / hold
    U-->>E: update -> RobotAction + events
```

- Subsystems translate stable motor/servo physics into a narrow mechanism API.
- `PedroDrive` bridges `HalDrivetrain` and `HalLocalizer`; it is the only Pedro adapter.
- Stubs are timing/state machines, not physical shooter, intake, or turret models.
- `SubsystemTrace` can wrap all four and records calls for `DebugTap`.
- A subsystem must not inspect gamepad edges, request IDs, or JSON.
- `RobotAction` is assembled once per tick after every `observe` call.

```{=latex}
\clearpage
```

## 4. HAL

```mermaid
flowchart TB
    C["Controller<br/>dim"]
    L["Logic<br/>dim"]
    S["Subsystem<br/>dim"]
    H["HAL<br/>ACTIVE"]
    W["World<br/>dim"]
    C -->|RequestBatch| L
    L -->|subsystem calls| S
    S -->|RobotAction| H
    H -->|IHal.write| W
    W -->|IHal.read| H
    H -->|RobotState| S
    classDef active fill:#cfe8ff,stroke:#1473b9,stroke-width:3px
    classDef dim fill:#eeeeee,stroke:#aaaaaa,color:#666666
    class H active
    class C,L,S,W dim
```

| Method | Arguments | Returns | Implementation |
|---|---|---|---|
| `IHal.now` | none | HAL-clock milliseconds | `RealHal`, `SimHal` |
| `IHal.read` | none | `RobotState` (enc, vel, yaw, Pinpoint, voltage) | same |
| `IHal.write` | `RobotAction` motor/servo maps and events | `void` | same |
| `IGamepadSource.get` | none | latest `GamepadState` | same |
| `SimHal` handshake | `seed`, `Pose` | `ready` plus state at `t_ms=0` | Java `:sim` ↔ Python server |

```mermaid
classDiagram
    class IHal { +long now(); +RobotState read(); +void write(RobotAction); +GamepadState get() }
    class RealHal { +now(); +read(); +write() }
    class SimHal { +now(); +read(); +write(); +truth() }
    class RobotState { +long t; +Map enc; +Map vel; +double yaw; +Pose pinpoint; +double voltage }
    class RobotAction { +Map motors; +Map servos; +List Event events }
    IHal <|.. RealHal
    IHal <|.. SimHal
    IHal --> RobotState
    IHal --> RobotAction
```

```mermaid
sequenceDiagram
    participant R as RobotLoop
    participant H as IHal
    participant X as RealHal / SimHal
    R->>H: read()
    H->>X: sensor read or state buffer
    X-->>H: RobotState
    R->>H: write(RobotAction)
    alt SimHal
        H->>X: step JSON and wait for state JSON
    else RealHal
        H->>X: FTC motor and servo writes
    end
```

- HAL owns time, device I/O, gamepad sampling, and no policy.
- `RobotState.t` comes from HAL; `RobotState` never contains simulator truth.
- `RobotAction` keys are compile-time `RobotConstants` names; missing motor means zero.
- `SimHal` sends one line per step and blocks for its matching state.
- `RealHal` is in the FTC/Android module; `:core` has no SDK imports.
- `RobotConstants.java` is read by the Python simulator with a small regex parser.

```mermaid
sequenceDiagram
    participant Java as SimHal
    participant Py as sim.server
    Java->>Py: reset {type,seed,pose{x,y,h}}
    Py-->>Java: ready {proto,motors,servos,state}
    Java->>Py: step {dt_ms,motors,servos,events}
    Py-->>Java: state {t_ms,enc,vel,imu,pinpoint,voltage,gamepad,truth}
    Java->>Py: bye
```
```{=latex}
\clearpage
```

## 5. World and simulator

```mermaid
flowchart TB
    C["Controller<br/>dim"]
    L["Logic<br/>dim"]
    S["Subsystem<br/>dim"]
    H["HAL<br/>dim"]
    W["World<br/>ACTIVE"]
    C -->|RequestBatch| L
    L -->|subsystem calls| S
    S -->|RobotAction| H
    H -->|TCP step JSON| W
    W -->|state JSON| H
    classDef active fill:#cfe8ff,stroke:#1473b9,stroke-width:3px
    classDef dim fill:#eeeeee,stroke:#aaaaaa,color:#666666
    class W active
    class C,L,S,H dim
```

| Component | Owns | Current behavior |
|---|---|---|
| `sim.server` | TCP protocol, reset barrier, viewer | line-delimited JSON, protocol 1 |
| `PhysicsBackend` | body integration and contacts | `pymunk`, `pybullet`, or `kinematic` |
| `MotorModel` | shared motor lag, encoders, mecanum mapping, noise | first-order RPM and seeded sensors |
| `MultiRobotWorld` | one backend per robot, shared world where supported | lockstep `--robots N` |
| viewer | pygame field display and gamepad events | omitted by `--headless` |

```mermaid
classDiagram
    class PhysicsBackend { +reset(seed,pose); +step(dt_ms,powers,events); +state(dt) }
    class PymunkBackend
    class PyBulletBackend
    class KinematicBackend
    class MotorModel { +MecanumKinematics kin; +MotorSim motors; +step(); +state() }
    class MotorSim { +target_rpm(power); +step(power,dt); +advance_encoder() }
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
    participant C0 as client port+i
    participant S as SimServer robots N
    participant W as MultiRobotWorld
    C0->>S: reset
    S-->>C0: ready epoch E
    par every ready client
        C0->>S: step(dt_ms,powers,events)
    end
    S->>W: one shared step after all submissions
    W-->>S: one state per body
    S-->>C0: state plus gamepad
    Note over S: deadline evicts missing clients, late reset starts a new epoch
```

- Java owns `dt_ms`; simulation can run faster than wall time in headless mode.
- Pymunk and PyBullet share one world in multi-robot mode; kinematic bodies step independently.
- `truth` is for tests/viewer only and is never copied into `RobotState`.
- Python reads motor, wheel, battery, Pinpoint, and stub timing constants from Java.
- Servo commands are validated but non-empty servo physics is intentionally unsupported.
- Deterministic reset seed and ordered lockstep submissions are part of protocol version 1.

```mermaid
flowchart LR
    Java[":sim SimHal"] -->|TCP localhost:5555+i| Server["sim.server"]
    Server --> Physics["pymunk / pybullet / kinematic"]
    Server --> Viewer["pygame viewer or headless"]
    Constants["RobotConstants.java"] -.regex reader.-> Server
    FTC["RealHal"] --> Hardware["FTC SDK hardware"]
```
```{=latex}
\clearpage
```

## 6. Cross-layer records and seams

```mermaid
classDiagram
    class RequestBatch { +RequestStream stream; +List Request requests; +int[] cancels }
    class RequestStream { +double vx; +double vy; +double omega; +boolean manualDrive }
    class Request { +int id; +RequestType type; +double[] params; +PathRequest path }
    class Feedback { +WorldSnapshot world; +List RequestStatus statuses; +long t }
    class RobotState { +long t; +Map enc; +Map vel; +double yaw; +Pose pinpoint; +double voltage }
    class RobotAction { +Map motors; +Map servos; +List Event events }
    class RequestStatus { +int id; +State state; +double progress; +String note }
    RequestBatch --> RequestStream
    RequestBatch --> Request
    Feedback --> RequestStatus
    RobotAction --> Event
```

```mermaid
flowchart LR
    Frame["DebugFrame<br/>state + action + calls + feedback + batch"] --> Tap["DebugTap"]
    Tap --> Hal["hal JSONL"]
    Tap --> Sub["subsystem JSONL"]
    Tap --> Logic["logic JSONL"]
    Hal --> Bag["BagWriter .jsonl"]
    Sub --> Bag
    Logic --> Bag
    Bag --> Replay["ReplayController"]
```

- Records copy their collections; only the owning layer mutates its private jobs.
- `RequestStatus` terminals are `DONE`, `FAILED`, and `REJECTED`; feedback lags one tick.
- `DebugTap` receives immutable frames through a bounded global queue (capacity 512).
- The dispatcher writes the bag before offering each seam line to bounded clients.
- Socket and replay controllers sit above the same `IController` seam as teleop and auto.

```mermaid
stateDiagram-v2
    [*] --> ACTIVE
    ACTIVE --> DONE: subsystem complete
    ACTIVE --> ACTIVE: progress
    ACTIVE --> REJECTED: cancel or validation
    ACTIVE --> FAILED: engine failure
    DONE --> [*]
    REJECTED --> [*]
    FAILED --> [*]
```

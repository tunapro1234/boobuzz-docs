# Request flow (Phase 1.1 R3 design)

How a request travels through the layers, who touches it, and what it triggers.
Mermaid; render in any Markdown viewer with Mermaid support.

## 1. One tick

```mermaid
sequenceDiagram
    participant HAL as IHal
    participant SUB as Subsystems
    participant ENG as IRobotEngine (logic)
    participant CTL as IController
    HAL->>SUB: observe(RobotState)
    HAL->>ENG: sense(RobotState) → WorldSnapshot
    ENG-->>CTL: Feedback(snapshot, drained RequestStatus[])
    CTL->>ENG: act(RequestBatch{stream, requests[], cancels[]})
    ENG->>SUB: IDrive / IShooter / IIntake / ITurret calls
    SUB->>HAL: update() → RobotAction{motors, servos, events}
```

## 2. Two message kinds, controller → logic

```mermaid
flowchart LR
    GP[GamepadState] --> TM[TeleopMap + Buttons]
    AB[AutoBuilder sequence] --> SR[SequenceRunner]
    TM -->|every tick: vx,vy,ω| ST[RequestStream 'UDP'<br/>no id, no answer]
    TM -->|on edge: SHOOT, INTAKE_ON/OFF,<br/>RESET_POSE, SWITCH_ENGINE| RQ[Request 'TCP'<br/>id → RequestStatus]
    SR -->|PATH, TURN_TO, SHOOT,<br/>SPIN_UP, INTAKE_*| RQ
    ST --> RB[RequestBatch]
    RQ --> RB
    RB --> ENG[IRobotEngine.act]
```

## 3. SHOOT request inside cplx1

```mermaid
sequenceDiagram
    participant C as Controller
    participant E as CplxEngine1
    participant S as ShooterLogic
    participant T as TurretLogic
    participant SH as IShooter
    participant TU as ITurret
    C->>E: Request(id, SHOOT, count=3)
    E->>S: requestShot(id, 3)
    S->>SH: spinUp(rpmFor(distance))
    loop every tick
        T->>TU: aimAt(goalX, goalY)  (automatic, independent of SHOOT)
        S->>S: SPINNING: wait shooter.isReady && turretLogic.locked
    end
    S->>T: holdForShot(true)
    loop count times
        S->>SH: feed()  → events shooter.feed.start / end
    end
    S->>T: holdForShot(false)
    S-->>E: RequestStatus.done(id)
    E-->>C: (next tick, in Feedback)
```

## 4. Drive arbitration in MotionLogic

```mermaid
stateDiagram-v2
    [*] --> Stopped
    Stopped --> Manual: stream.manualDrive
    Stopped --> Following: Request GOTO/PATH/TURN_TO
    Following --> Manual: stream.manualDrive (request REJECTED "overridden")
    Following --> Stopped: drive.pathDone → DONE
    Manual --> Stopped: !stream.manualDrive
    Manual --> Following: Request GOTO/PATH/TURN_TO
```

## 5. Same SHOOT in the direct engine (no logic)

```mermaid
flowchart LR
    RQ[Request SHOOT n] --> DE[DirectEngine wiring]
    DE --> DM[DirectMap case SHOOT]
    DM --> SH[IShooter.spinUp → feed ×n]
    SH -->|isFeeding false n times| DE
    DE -->|RequestStatus DONE| C[Controller]
```

## 6. Engine switch (contingency)

```mermaid
sequenceDiagram
    participant C as TeleopController
    participant L as RobotLoop
    participant E1 as CplxEngine1
    participant E2 as DirectEngine
    C->>L: Request SWITCH_ENGINE(1)  (start held 1 s)
    L->>E1: act(cancel-all batch)
    L->>L: engine = E2
    Note over L,E2: next tick sense/act go to E2, same Subsystems
```

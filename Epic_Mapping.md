|ADO Concept|Proposed|Built-in GitHub Mechanism|Why It Works Well Here|
|-|-|-|-|
|Epic|Milestone|Repository Milestone|Solves the missing "Epic" type by using Milestones as high-level feature containers.
|Story|Feature|Native Issue Type: Feature|Uses the built-in Feature type to represent deliverable user value.
|Maintenance Task|Task|Native Issue Type: Task with label maintenance|Uses Task for maintenance/tech debt.|
|Bug|Bug|Native Issue Type: Bug|Uses Bug for fixes/issues|
|Task|Issue Sub-item|Native Sub-issue or Markdown [ ]|Actionable steps nested directly inside the parent Feature issue.|

We use Milestones as Epics, GitHub limits each issue to one single Milestone, which I don't see an issue with.

To make this structure work smoothly, keep these two rules in mind:

1. Use Project Iterations for Sprints: Do not use Milestones for Sprints (e.g., "Sprint 12").
  - Use the GitHub Project Iteration Field for time-boxed sprint tracking instead.
  I don't think this is applicable for how this project runs, so it's not much of a concern.
2. Use GitHub Releases for Code Versions:
  - Do not use Milestones for release versions (e.g., v1.2.0). Use GitHub Releases / Tags for software delivery milestones instead.

Example Diagram:
```mermaid
graph TD
    subgraph Milestone_Layer ["Milestone (Epic Container)"]
        MS["Milestone: 'Q1 Mobile Refresh'"]
    end

    subgraph Issue_Layer ["GitHub Issues (Work Items)"]
        F1["Issue (Type: Feature)<br/><b>User Story: User Login</b>"]
        F2["Issue (Type: Feature)<br/><b>User Story: Payment Gateway</b>"]
        M1["Issue (Type: Bug / Task)<br/><b>Maintenance: Upgrade Dependencies</b>"]
    end

    subgraph Task_Layer ["Execution Items (Tasks)"]
        T1["Sub-issue: Create Auth API"]
        T2["Sub-issue: Build Login UI"]
        T3["Markdown Checklist: <code>- [ ] Add unit tests</code>"]
    end

    subgraph Board_Layer ["GitHub Project"]
        Iter["Iteration Field<br/>(e.g., Sprint 14)"]
        Status["Status Columns<br/>(Backlog,Ready,In Progress,In review, Professor Review, Done)"]
    end

    %% Hierarchy Relationships
    MS -->|Contains| F1
    MS -->|Contains| F2
    MS -->|Contains| M1

    F1 -->|Child Work| T1
    F1 -->|Child Work| T2
    M1 -->|Child Work| T3

    %% Board Management
    Iter -.->|Schedules| F1
    Iter -.->|Schedules| M1
    Status -.->|Tracks| F1
    Status -.->|Tracks| M1

    %% Styling
    classDef epic fill:#4A154B,color:#fff,stroke:#fff,stroke-width:1px;
    classDef feature fill:#0052CC,color:#fff,stroke:#fff,stroke-width:1px;
    classDef maintenance stroke:#E06C75,color:#fff,fill:#282C34,stroke-width:1px;
    classDef task fill:#1F2428,color:#959DA5,stroke:#444C56,stroke-width:1px;
    classDef project fill:#0969DA,color:#fff,stroke:#fff,stroke-width:1px;

    class MS epic;
    class F1,F2 feature;
    class M1 maintenance;
    class T1,T2,T3 task;
    class Iter,Status project;
```
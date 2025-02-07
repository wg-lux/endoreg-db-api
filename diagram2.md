```mermaid
graph TD;
    %% 🎯 Start of the Process
    A[🏥 Patient Registration] -->|Enter Patient Details| B[📝 Save Patient Information]
    B -->|Select Medical Center| C[🏢 Link Patient to Center]
    
    %% 🩺 Examination Step
    C -->|Doctor Schedules Examination| D[📋 Select Examination Type]
    D -->|Confirm & Save| E[📝 Assign Examination to Patient]

    %% 🔬 Finding Step
    E -->|Doctor Selects a Medical Finding| F[🔎 Select Finding]
    F -->|Confirm & Save| G[📝 Link Finding to Examination]

    %% 📍 Finding Location Selection
    G -->|Doctor Selects Finding Location Category| H[📍 Select Location Type]
    H -->|Show Available Locations| I[🔍 Load Possible Locations]
    I -->|Doctor Selects Specific Location| J[📝 Save Location]

    %% 🦠 Morphology Classification
    J -->|Doctor Classifies Finding Morphology| K[🦠 Select Morphology Type]
    K -->|Confirm & Save| L[📝 Link Morphology to Finding]

    %% 💉 Medical Intervention Step
    L -->|Doctor Selects Medical Interventions| M[💉 Choose One or More Interventions]
    M -->|Confirm & Save| N[📝 Assign Interventions to Finding]

    %% 📊 Report Generation Step
    N -->|Doctor Generates Report| O[📊 Retrieve All Patient Data]
    O -->|Display on UI| P[📑 Show Patient Report]
    O -->|Download as PDF| P2[📄 Export Report]

    %% ✅ End of Process
    P -->|Process Complete| Z[✅ Report Ready]
    P2 -->|Process Complete| Z

```mermaid
graph TD;
    %% Start of the Process
    A[🏥 Start: User Registers a Patient] -->|Enter Patient Details| B[📝 Save in endoreg_db_patient]
    B -->|Select Center from Dropdown| C[🏢 Save Center ID in endoreg_db_patient]
    
    %% Patient CRUD Operations
    B <-->|🔄 CRUD: Update/Delete Patient| CRUD_PATIENT[⚙️ Manage Patients]
    C <-->|🔄 CRUD: Manage Centers| CRUD_CENTER[⚙️ Manage Centers]

    %% Examination Step
    C -->|Doctor Selects Examination Type| D[📋 Select from endoreg_db_examination]
    D -->|Save Selection| E[📝 Save in endoreg_db_patientexamination]

    %% Examination CRUD Operations
    D <-->|🔄 CRUD: Add/Edit/Delete Examinations| CRUD_EXAM[⚙️ Manage Examinations]

    %% Finding Step
    E -->|Doctor Selects a Medical Finding| F[🔬 Select from endoreg_db_finding]
    F -->|Save Selection| G[📝 Save in endoreg_db_patientfinding]
    
    %% Finding CRUD Operations
    F <-->|🔄 CRUD: Add/Edit/Delete Findings| CRUD_FINDING[⚙️ Manage Findings]

    %% Finding Location Selection
    G -->|Doctor Selects Finding Location Classification| H[📍 Select from endoreg_db_findinglocationclassification]
    H -->|Load Choices Linked to Classification| I[🔍 Retrieve from endoreg_db_findinglocationclassificationchoice]
    I -->|Save Selected Location| J[📝 Save in endoreg_db_patientfinding_locations]

    %% Finding Location CRUD Operations
    H <-->|🔄 CRUD: Manage Finding Locations| CRUD_LOCATION[⚙️ Manage Locations]

    %% Morphology Step
    J -->|Doctor Selects Finding Morphology| K[🦠 Select from endoreg_db_findingmorphologyclassification]
    K -->|Save Morphology| L[📝 Save in endoreg_db_patientfinding_morphology]

    %% Morphology CRUD Operations
    K <-->|🔄 CRUD: Add/Edit/Delete Morphologies| CRUD_MORPHOLOGY[⚙️ Manage Morphologies]

    %% Medical Intervention Step
    L -->|Doctor Selects Medical Intervention| M[💉 Select from endoreg_db_findingintervention]
    M -->|Save Intervention| N[📝 Save in endoreg_db_patientfinding_intervention]

    %% Intervention CRUD Operations
    M <-->|🔄 CRUD: Add/Edit/Delete Interventions| CRUD_INTERVENTION[⚙️ Manage Interventions]

    %% Report Generation Step
    N -->|Generate Report| O[📊 Query all linked tables]
    O -->|Display in UI / Download as PDF| P[📑 Retrieve Data from endoreg_db_patient + Related Tables]
    P -->|Show Patient Findings, Locations, Morphology, Interventions| Q[📄 Final Report Displayed]
    
    %% End of Process
    Q -->|End of Process| Z[✅ Process Complete]

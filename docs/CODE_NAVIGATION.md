# Acumatica ERP Code Navigation Guide

> Product repository: Acumatica ERP (`code/` by default).
>
> Reference revision: `2027r150@30696c145fce` (2026-11-26), verified on 2026-11-27.
>
> Primary focus: PM / CN / PJ (Projects & Construction).

Use the map to choose a starting path on the target branch. It covers representative locations. **If the map has no entry or a route yields no matches, continue with [repository search](#search-beyond-the-map) before drawing any conclusion about whether the implementation exists.**

Verify the path and symbol on the inspected revision, then cite the actual source for findings. Follow [File Placement Guidelines](ARCHITECTURE_RULES.md#11-file-placement-guidelines) when adding files.

Paths start at the product repository root unless scoped by a section. Shortened application paths beginning with a project name such as `PX.Objects/` or `PX.Objects.PJ/` are under `WebSites/Pure/`.

## Search routes

For a known module, go to [Projects and Construction](#projects-and-construction) or [Adjacent application modules](#adjacent-application-modules). For a known framework mechanism, use the [Platform code map](#platform-code-map).

### Screen ID

Use the prefix to pick a UI folder. Read the graph binding in one or both stacks:

- Classic page: `WebSites/Pure/Site/Pages/<Prefix>/<ID>.aspx`. Look for `TypeName=` on `PXDataSource`, using a case-insensitive search.
- Modern UI: `WebSites/Pure/Site/FrontendSources/screen/src/screens/<Prefix>/<ID>/<ID>.ts`. Read `graphType` in `@graphInfo` and check the screen's `extensions/` folder for feature-specific TypeScript and HTML.

Use the graph's qualified type to locate its project. For example, `CL201000` binds to `VendorDocumentReqMaint` in `PX.Objects/CN/Requirements/`. `PM306500` binds to `ProjectMaterialListEntry` in the `PX.Objects.PM.MaterialManagement` satellite. If the expected UI file is missing, search the screen ID in `WebSites/Pure/DB/EntityXml/SiteMap/SiteMap.xml` and follow its URL and screen type.

### Graph or action

Start with the type declaration in `PX.Objects/<Module>/` or a satellite. For an action, search its name in the graph, partials, base classes, and extensions. Check `<Graph>_Workflow.cs` and approval workflow extensions for action registration and state. Follow the view, handlers, and services involved in the operation. For generated actions, see [workflow](#workflow-and-automation) and [processing](#processing-and-background-operations).

Search the graph name as a whole word in the target module, the feature owner, and relevant satellites. Inspect extension declarations, including ones that list the graph after another generic argument or inherit an abstract shared extension. For example, within `PX.Objects/PM/ChangeOrderBillingVisibility/`, searching `JournalEntry` finds both `JournalEntryProjectExt : PXGraphExtension<…, JournalEntry>` and `JournalEntryExt : BillingVisibilityExt<JournalEntry>`. Follow the base extension and check `IsActive` when tracing which behavior applies.

### DAC, field, or table

Try the DAC class and file name under the module's `DAC/` folder, then search the type and field names by content. If starting from a table, find its SQL definition and look for DACs that map to it, including derived DACs and projections. `PMProject` inherits `Contract`, whose table is in `DatabaseModel/Application/CT/Contract.sql`. `PMQuote` uses `PXQuoteProjection` over `CR.Standalone.CRQuote`, `CROpportunityRevision`, and `CR.Standalone.CROpportunity`. Follow the projected fields to the source DACs before mapping them to physical tables in `DatabaseModel/Application/` or `DatabaseModel/System/`.

Search the DAC name in the feature owner's code as well. Inspect `PXCacheExtension` declarations and their base types, then look for the nested BQL field class and its property. To trace schema history, search the actual table and column names in `WebSites/Pure/DB/MSSQL/AppUpdates_*.sql`, starting with `AppUpdates_500_PROJ.sql` for Projects changes.

### Field behavior or UI state

- For defaults, formulas, selectors, or field metadata, start with the DAC attributes and check `CacheAttached` on the effective graph and extensions. Open module attribute declarations or the [platform definitions](#dac-and-data-access) when needed.
- For row-dependent state, check `RowSelected`, workflow state, and the applicable screen definition and UI extensions.
- For feature-dependent state, trace `IsActive` and `FeaturesSet`. For attributes with a `FieldClass` token, find its mapping in the applicable `Features.xml`. Base feature mappings are in `NetTools/PX.Data/Access/Features.xml`. Check access rights when the symptom depends on the user or role.

### Release or posting

Find the source document's release graph using [Adjacent application modules](#adjacent-application-modules). Search the graph and posting method names in the feature owner and PM integration code. If release creates `PMTran`, follow the transaction to `RegisterRelease`, allocation, or billing as relevant. Use the originating document references on `PMTran` to trace the chain in reverse.

### Configuration or tests

- For a shipped Generic Inquiry, search its title or ID under `WebSites/Pure/DB/EntityXml/Generic Inquiries/`. The shared Modern UI screen is `WebSites/Pure/Site/FrontendSources/screen/src/systemScreens/GenericInquiry.ts`. For execution, use the [platform GI engine](#customization-and-no-code). See [Artifact locations](#artifact-locations) for reports, mobile configuration, and endpoints.
- For an application test, search the graph, feature, or behavior by content under `WebSites/Pure/AppTests/`. Check the feature owner's folders even when the test exercises another module. For example, the Budget Control test for `APInvoiceEntry` is under `PX.Objects.Tests/PM/BudgetControl/` within `AppTests/`. For framework tests, start under `NetTools/Tests/`.

### Search beyond the map

Search file names and contents with `rg --files` and `rg` on the checked-out target revision. Start with a concrete identifier such as the screen ID, qualified type, field name, or exact message. Widen to the product repository when the first module or artifact type yields no match. Follow usages, base types, project references, overrides, and registrations when declarations alone leave the path unclear.

To inspect a different revision without switching branches, use `git ls-tree`, `git grep`, and `git show` with that revision. For example, from the product repository:

```powershell
git grep -n -w -F JournalEntry 30696c145fce -- WebSites/Pure/PX.Objects/PM/ChangeOrderBillingVisibility
```

If the behavior appears framework-owned, resolve the symbol's assembly and start with the [platform map](#platform-code-map).

## Top-level repository structure

| Path | Content |
|---|---|
| `PureWithNetTools.sln` | Main solution: platform + application |
| `NetTools/` | Platform and framework code |
| `WebSites/Pure/` | The ERP application: business modules, site, shipped data, app tests |
| `WebSites/Pure/PX.Objects/` | Monolithic application assembly; one folder per module (`AP`, `AR`, `GL`, `IN`, `PM`, `CN`, `CT`, `EP`, `PO`, `SO`, …) |
| `WebSites/Pure/PX.Objects.*/` | Satellite application projects (`PX.Objects.PM`, `.PM.ChangeRequest`, `.PM.MaterialManagement`, `.PJ`, `.PR`, `.FS`, `.AM`, …) |
| `WebSites/Pure/Site/` | ASP.NET site: classic pages, Modern UI sources, reports, runtime engines (wiki, GI, customization) |
| `WebSites/Pure/DB/` | Shipped data and migrations: update scripts, `EntityXml/` no-code seed data, contract-based API endpoint definitions |
| `WebSites/Pure/AppTests/` | Application test projects (xUnit) |
| `ClientSideApps/` | Shared Modern UI TypeScript library (`client-controls/`) and frontend build tooling |
| `DatabaseModel/` | SSDT schema project: one `.sql` per table under `Application/<MOD>/` and `System/` |
| `Common/` | Shared test utilities (`PX.Tests.Common`) |
| `NetTools/Tests/` | Platform test projects |

Scope ordinary code searches to source trees. Skip build outputs (`bin/`, `obj/`, `dist/`, `node_modules/`) and runtime working data unless relevant. `ClientSideApps/client-controls/src/` contains shared Modern UI source. Installer, update delivery, and auxiliary sites such as `WebSites/TestPortal/` have their own entry points.

## Distinguishing platform from application

| Signal | Platform | Application |
|---|---|---|
| Directory | `NetTools/**`, `ClientSideApps/**` | `WebSites/Pure/**` |
| Namespace | `PX.Data*`, `PX.Common*`, `PX.Web.UI*`, `PX.Api.*`, `PX.Reports*`, `PX.SM`, `PX.SiteMap*`, `PX.BusinessProcess`, `PX.PushNotifications`, `PX.DbServices*`, `Customization` | `PX.Objects.*`, `PX.Commerce.*`, app data-sync providers |
| Assembly | `PX.Data.dll`, `PX.Common.dll`, `PX.Web.UI.dll`, … | `PX.Objects.dll`, `PX.Objects.<X>.dll` |
| Reference direction | referenced *by* the application | references platform binaries via `..\Site\Bin\*.dll` HintPaths |

Use project references and assembly names to confirm ownership. For example, `WebSites/Pure/PX.Objects/PX.Objects.csproj` resolves `PX.Data.dll` via `Site/Bin/`. The platform can also resolve application types by name, as in `NetTools/PX.Data/Access/Features.xml`.

Traps — do not classify by folder name alone; confirm namespace and project references:

- The `PX.SM` namespace (users, roles, site map, schedules) is implemented in platform code: `NetTools/PX.Data/Maintenance/`, `NetTools/PX.Data/Process/`, `NetTools/PX.SiteMap/`. `WebSites/Pure/PX.Objects/SM/` is only a thin application overlay of it.
- The `PX.Api` namespace (import/export scenarios, screen-based SOAP) lives in platform `NetTools/PX.Data/Api/`.
- The `PX.Web.Customization` project uses the root namespace `Customization`.
- `WebSites/Pure/PX.Web.Controls/` and `WebSites/Pure/PX.Web.Objects/` are application-side UI helpers despite platform-sounding names.

## Projects and Construction

Three code homes, all application-side:

- `WebSites/Pure/PX.Objects/PM/` — project accounting (in the monolith);
- `WebSites/Pure/PX.Objects/CN/` — construction features layered over other modules (in the monolith);
- satellite projects `PX.Objects.PJ`, `PX.Objects.PM`, `PX.Objects.PM.ChangeRequest`, `PX.Objects.PM.MaterialManagement` under `WebSites/Pure/`.

Assembly dependency chain (verified from csproj): `PX.Objects` ← `PX.Objects.PM.ChangeRequest` ← `PX.Objects.PJ` ← `PX.Objects.PM` (satellite). `PX.Objects.PM.MaterialManagement` depends only on `PX.Objects`.

Feature gates for the area live in `WebSites/Pure/PX.Objects/CS/DAC/FeaturesSet.cs`: `projectAccounting`, `construction`, construction project management.

### PM — Project Accounting

Root `WebSites/Pure/PX.Objects/PM/`. Some features group their graph extensions, DACs, and helpers in a dedicated folder. This newer layout in PM keeps specialized extensions out of the shared `GraphExtensions/` listing. Search under the owning module by feature name as well as artifact type. For example, `PM/ChangeOrderBillingVisibility/` contains a shared extension and a nested `GraphExtensions/` folder, while `PM/Features/ProjectParentChild/` groups extensions, services, and DACs directly. Both paths are relative to `PX.Objects/`.

| Area | Where (under `PM/`) | What to look for |
|---|---|---|
| Graphs | root `*.cs` | `*Entry`/`*Maint`/`*Process`/`*Inquiry`; e.g. `ProjectEntry` (PM301000), `ProjectTaskEntry`, `RegisterEntry` (PM transactions), `ChangeOrderEntry`, `ProformaEntry`, `ProgressWorksheetEntry`, `PMQuoteMaint`, `AllocationProcess`, `BillingProcess`, `RegisterRelease` |
| Data model | `DAC/` | one DAC per file: `PMProject`, `PMTask`, `PMTran`, `PMRegister`, `PMBudget`, `PMChangeOrder`, `PMProforma`, `PMCommitment`, `PMSetup`; `DAC/Lite/` — slim query variants |
| Attributes | `Descriptor/` | `ProjectAttribute`, `ProjectTaskAttribute`, `ActiveProjectTaskAttribute`, `ProjectDefaultAttribute`, `CostCodeAttribute`, `AccountGroupAttribute`, `PMCommitmentAttribute`. Note: `ActiveProjectAttribute` is defined in `GL/Attributes/ActiveProjectAttribute.cs` |
| Cross-module hooks | `GraphExtensions/` and feature folders | extensions targeting AP/AR/IN/GL/PO/SO/EP graphs |
| DAC extensions | `CacheExtensions/` | `PXCacheExtension` over other modules' DACs |
| Workflow | root, `<Graph>_Workflow.cs` / `<Graph>_ApprovalWorkflow.cs` | screen configuration and approval states |
| Engines/services | root | `PMBillEngine` (billing engine implemented as a graph), `PMAllocator`, `RateEngine`, `BudgetService`, `ProjectBalance`. DI registration is in `WebSites/Pure/PX.Objects/ServiceRegistration.cs` (no PM-local registration) |
| Project 360 | `Project/` | `ProjectOverview` (PM301500), side panels/charts; `Project/Shared/ProjectEntryBase.cs` — shared base of `ProjectEntry` and `ProjectOverview` |
| Row-level access | `EntityAccess/`, `VisibilityRestriction/` | project/account-group access graphs, restriction classes |

Satellite projects:

- `WebSites/Pure/PX.Objects.PM/` — additive features over the monolith: `ProjectAudit/`, `BudgetOverrunInquiry.cs`, `Extensions/BudgetControl/` (budget control over `APInvoiceEntry`, `POOrderEntry`, `ChangeOrderEntry`).
- `WebSites/Pure/PX.Objects.PM.ChangeRequest/` — the Change Requests feature: `ChangeRequestEntry.cs` (PM308500) plus extensions into `ChangeOrderEntry`/`ProjectEntry`.
- `WebSites/Pure/PX.Objects.PM.MaterialManagement/` — project material lists and warehouse integration (`ProjectMaterialListEntry`, Modern-UI-only screen PM306500), IN/PO/SO extensions.

### CN — Construction

Root `WebSites/Pure/PX.Objects/CN/`, namespaces `PX.Objects.CN.*`. Layout convention: `CN/<Feature>/<TargetModule>/{DAC,CacheExtensions,GraphExtensions,Graphs,Services,Descriptor}` — the second level names the *feature*, the third names the *module being extended*.

| Feature | Where (under `CN/`) | What / attaches to |
|---|---|---|
| Compliance & lien waivers | `Compliance/` | `ComplianceDocument` DAC, `ComplianceDocumentEntry` (CL401000); generic `ComplianceViewEntityExtension<TGraph,TDac>` instantiated over AP/AR/PO/PM graphs; lien-waiver processing |
| Subcontracts | `Subcontracts/` | `Subcontract : POOrder` (same table), `SubcontractEntry : POOrderEntry` (SC301000); per-module hooks in `Subcontracts/{AP,CR,CS,EP,PM,PO,RQ,SM}/` |
| Joint checks | `JointChecks/` | joint payees on AP bills/payments; extensions over `APPaymentEntry`, `APReleaseProcess` |
| Vendor requirements | `Requirements/` | `VendorDocumentReqMaint` (CL201000, Modern-only); compliance sync with PO |
| Construction project accounting | `ProjectAccounting/` | `CostProjectionEntry` (hosted on PM screen PM305000); AP/AR/EP/IN/PO extensions |
| CRM overlay | `CRM/` | multiple project quotes per opportunity (`OpportunityMaint` extension) |
| Shared infrastructure | `Common/` | data providers (`IProjectDataProvider`, …), DI module `Common/DependencyInjection/Registration.cs`, shared attributes |
| Mobile behavior | `Mobile/` | mobile-specific selectors/defaulting for EP time cards |

Start with `CL*` for compliance and vendor requirements and `SC*` for subcontracts. Construction extensions also participate in PM and adjacent module screens. Compliance and subcontract reports use `CL*.rpx` and `SC*.rpx`.

### PJ — Construction Project Management

Separate project `WebSites/Pure/PX.Objects.PJ/`. Namespace pattern `PX.Objects.PJ.<Area>.<ModuleCode>.<Layer>`, e.g. `PX.Objects.PJ.RequestsForInformation.PJ.Graphs.RequestForInformationMaint`. Per-area layout mirrors CN: `<Area>/<ModuleCode>/{DAC,Descriptor,CacheExtensions,GraphExtensions,Graphs,Services}` where `PJ` holds the area's own artifacts and `PM/CR/EP/CS/SM` hold integration hooks.

Start with the named area, such as `RequestsForInformation/`, then use `ProjectManagement/` for shared graphs such as `ProjectManagementBaseMaint<TGraph,TEntity>` and `Common/` for shared services and registration.

Quirk: `ProjectFiles/` uses namespace `PX.Objects.PM.ProjectFiles.*` and PM screen numbers (PM509000/PM509500) although it lives in the PJ project.

### Shared Project and Construction paths

- **`PMTimeActivity`** physically resides in `WebSites/Pure/PX.Objects/CR/DAC/` — the shared CRM/EP/PM activity table.
- **Commitments**: `PM/DAC/PMCommitment.cs` + generic `PM/GraphExtensions/CommitmentTracking.cs` applied to PO/AP graphs.
- **Retainage**: `AP/Retainage/` and `AR/Retainage/` folders plus `AP/APRetainageRelease.cs`; PM-side hooks such as `PM/GraphExtensions/ChangeOrderEntryRetainageExt.cs`.
- **Project inventory**: `INRegister` has no project fields; the link is `IN/DAC/INCostCenter.cs` (keyed by site/location/project/task) plus `PM/GraphExtensions/CostCenter/`.
- **Account groups**: GL `Account.AccountGroupID` → `PMAccountGroup` maps GL accounts into PM.

### Integration with adjacent modules

For backend integration, search both the PM/CN/PJ feature owner and the host graph or DAC. For Modern UI, inspect the host screen's extensions. For example, Construction Compliance extends the AR301000 screen under `WebSites/Pure/Site/FrontendSources/screen/src/screens/AR/AR301000/extensions/`.

- **Financial release → PM**: `PM/GraphExtensions/ARDocumentReleaseExt.cs` (`ARReleaseProcessExt`), `APReleaseProcessExt.cs`, `INReleaseProcessExt.cs`, `PostGraphExt.cs` and `JournalEntryExt.cs` (GL). These attach/produce `PMTran` during release of source documents.
- **EP → PM**: `EP/TimeCardMaint.cs` and `EP/EmployeeActivitiesRelease.cs` instantiate PM `RegisterEntry` and call its `CreatePMTran`-style factory to post time to projects.
- **Document capture**: project/task/cost-code fields on `APTran`, `ARTran`, `GLTran`, `INTran`, `POLine`, `SOLine` are declared with PM `Descriptor/` attributes.
- **PM billing → AR**: `PMBillEngine`/`ProformaEntry` produce AR invoices; navigate back from `PMTran` reference fields (AR doc type/number, GL batch number).

## Adjacent application modules

Paths in this table are relative to `WebSites/Pure/PX.Objects/` unless qualified. Common starting points are the module root for graphs, `DAC/` for data and preferences, and `Descriptor/` for attributes and messages.

| Module | Entry points (verified) | Release / posting | PM/CN/PJ touchpoints |
|---|---|---|---|
| **IN** Inventory | `INReceiptEntry`, `INIssueEntry`, `INAdjustmentEntry`, `INTransferEntry` (base `INRegisterEntryBase`) | `IN/InventoryRelease/INReleaseProcess.cs`, `INDocumentRelease` | project stock via `INCostCenter`; project fields on `INTran`; `PM/GraphExtensions/IN*`; MaterialManagement satellite |
| **AR** Receivables | `ARInvoiceEntry`, `ARPaymentEntry` | `AR/ARDocumentRelease.cs` (also contains `ARReleaseProcess`) | pro forma → AR invoice; project fields on `ARTran`; `AR/Retainage/`; PM's `ARReleaseProcessExt` |
| **AP** Payables | `APInvoiceEntry`, `APPaymentEntry` | `AP/APDocumentRelease.cs` (also contains `APReleaseProcess`) | subcontract/commitment billing; project fields on `APTran`; `AP/Retainage/` + `APRetainageRelease`; CN joint checks & lien waivers |
| **GL** General Ledger | `JournalEntry` | `PostGraph` (same file `GL/JournalEntry.cs`) | `Account.AccountGroupID` → `PMAccountGroup`; project fields on `GLTran`; PM's `PostGraphExt`/`JournalEntryExt` |
| **CR** CRM | `OpportunityMaint`, `BusinessAccountMaint` (per-graph folders `CR/Graphs/<Name>/`) | — | `PMQuote` projection over CR quotes; `PMTimeActivity` DAC lives here; CN multi-quote overlay |
| **EP** Time & Expenses | `TimeCardMaint`, `ExpenseClaimEntry`; approvals `EPApprovalProcess` | `EPReleaseProcess`, `EmployeeActivitiesRelease` | time/expenses become `PMTran` via PM `RegisterEntry`; approval maps used by PM/CN/PJ approval workflows |
| **PR** Payroll | real code in satellite `WebSites/Pure/PX.Objects.PR/` (`PRPayChecksAndAdjustments` family, `PRCalculationEngine.cs`); monolith `PX.Objects/PR/` holds only `PX.Objects.PR.Standalone` stub DACs | `PRDocumentProcess.cs` | certified projects, labor cost rates ↔ PM; `PX.Objects.PJ` references the PR project |
| **PO** Purchasing | `POOrderEntry`, `POReceiptEntry` | none of its own — receipt release drives IN/AP | commitments (`POCommitmentAttribute`); subcontracts derive from PO; project fields on `POLine` |
| **SO** Sales Orders | `SOOrderEntry`, `SOShipmentEntry`, `SOInvoiceEntry : ARInvoiceEntry` | via AR/IN | project shipments via cost centers; project fields on `SOLine` |
| **CT** Contracts | `ContractMaint`, `UsageMaint`, `ContractBilling` + `CTBillEngine.cs` | — | base DAC `Contract` of `PMProject`; a billing engine parallel to PM's |

Shared application code lives in `PX.Objects/Common/` and `PX.Objects/Extensions/`, including multi-currency, discounts, and sales tax. Check `PX.Objects/ServiceRegistration.cs` for application DI and `PX.Objects/EndpointAdapters/` for contract-based API handlers.

## Platform code map

Platform paths below are relative to `NetTools/`. Paths prefixed with `WebSites/` or `ClientSideApps/` start at the repository root.

### Graph framework

- Graph lifecycle and base types: `PX.Data/Graph/Graph.cs` (`PXGraph`) and `PX.Data/Graph/GraphExtension.cs` (`PXGraphExtension`).
- Extension discovery: `PX.Data/Graph/GraphExtensibility.cs` (`PXGraphExtensibility` and its `Finder`) and `PX.Data/Extensibility/Helpers/ExtensionFinder.cs`.
- Actions and views: `PX.Data/Descriptor/Action/PXAction.cs` and `PX.Data/Database/Cached.cs` (`PXView`).

### DAC and data access

`PX.Data/BQL/` holds `IBqlTable` and `PXBqlTable`. Look for `PXCache` and `PXCacheExtension` under `PX.Data/Cache/`, key definitions under `PX.Data/ReferentialIntegrity/`, and field attributes under `PX.Data/Descriptor/`. For point changes to attached attributes, search `PXCustomizeAttribute` in `PX.Data/Extensibility/Attributes/Customize/`.

### BQL
Classic grammar in `PX.Data/BQL/` (Select/Search/Where/Join); `PXSelect*` view wrappers in `PX.Data/Graph/Indexer.cs`. Fluent BQL in `PX.Data.BQL.Fluent/` (`SelectFrom<>`, `PXViewOf<>`, `FbqlCommand`). Descend for: query translation and overload resolution.

### Events and cache pipeline
Classic event args in `PX.Data/Cache/Event.cs`; typed generic events in `PX.Data/Graph/Events/`; dispatch in `PX.Data/Cache/ModelEventHandling.cs`. Descend for: handler ordering, auto-subscription, `CacheAttached`.

### Persistence and database
`PX.Data/Database/` (`PXDatabase`, `PXTransactionScope`, MSSQL provider, `ISqlDialect`); MySQL in `PX.MySql/`, PostgreSQL in `PX.PgSql/`; bulk/script execution in `PX.BulkInsert/`; schema model and DB services in `PX.DbServices/`. Descend for: SQL generation, transactions, provider-specific behavior.

### UI framework
Classic WebForms: `PX.Web.UI/` (`PXGrid`, `PXFormView`, `PXDataSource`), shell `PX.Web.UI.Frameset/`; host site `WebSites/Pure/Site/` (`Pages/`, `MasterPages/`). Modern UI: server side `PX.Api.TSBasedScreen/` (+ app companion `WebSites/Pure/PX.Api.TSBasedScreen.Objects/`); client library `ClientSideApps/client-controls/` (`PXScreen`, `PXView`, controls, services); per-screen apps `WebSites/Pure/Site/FrontendSources/{screen,main-frame}/`. Classic/Modern switching: `PX.Data/Access/SiteMap/SiteMapUITypeProvider.cs`, `PX.SiteMap/UIScreenModeSwitcher.cs`. Descend for: control behavior, screen runtime, TS wrapper generation.

### Workflow and automation
Workflow API `PX.Data/ProjectDefinition/` (namespace `PX.Data.WorkflowAPI`: `PXScreenConfiguration`, `WorkflowContext<,>`); runtime `PX.Data/Process/Automation/`; legacy automation-step DACs `PX.Data/Process/DAC/` (`AUDefinition`, `AUStep` — namespace `PX.SM`). Application side: `<Graph>_Workflow.cs` overrides `Configure(PXScreenConfiguration)`. Descend for: state/transition evaluation, workflow-driven action visibility.

### APIs and integration
Contract-based REST `PX.Api.ContractBased/` — shipped endpoint definitions in `WebSites/Pure/DB/ContractBasedApiEndpoints/*.endpoint`, app implementations in `PX.Objects/EndpointAdapters/`. OData `PX.Api.OData/` and `PX.Api.OData.v4/`. Webhooks `PX.Api.Webhooks/`. Mobile API `PX.Api.Mobile/`. Screen-based SOAP `PX.Soap/` + `PX.Data/Api/Export/WebServiceMaint.cs`. Import/export scenario engine `PX.Data/Api/` (namespace `PX.Api`: `SYImportMaint`, `SYMapping`), data providers `PX.DataSync.Core/` and `WebSites/Pure/PX.DataSync/`. Descend for: endpoint resolution, scenario execution.

### Processing and background operations
`PXLongOperation` in `PX.Data/Async/`; `PXProcessing*` in `PX.Data/Descriptor/Action/`; schedules in `PX.Data/Process/` (`AUSchedule*`, namespace `PX.SM`) with app overlay `PX.Objects/AU/`; business events `PX.BusinessProcess/` (+ app subscribers `PX.Objects/BusinessProcess/`); push notifications `PX.PushNotifications/`. Descend for: async state, mass-processing plumbing, scheduling.

### Customization and no-code

Find publish and validation behavior in `PX.Web.Customization/` (namespace `Customization`). Find Generic Inquiry execution in `PX.Data/GenericInquiry/`. For shipped definitions use [Artifact locations](#artifact-locations).

### Migrations and upgrades
Update runtime `PX.Data/Update/`; script pipeline `PX.DbServices/Scripting/` + `PX.BulkInsert/ScriptExecutor/`; application scripts `WebSites/Pure/DB/{MSSQL,MySql,PgSql}/`; schema `DatabaseModel/`. Descend for: how update scripts are ordered, hashed, and executed.

### Security, features, and configuration

Find access checks and feature logic in `PX.Data/Access/` (`PXAccess`, `Features.xml`) and feature declarations in `WebSites/Pure/PX.Objects/CS/DAC/FeaturesSet.cs`. Security DACs such as `Users` and `Roles` live in `PX.Data/Maintenance/` under `PX.SM`. Follow `PX.Data/Access/SiteMap/` and `PX.SiteMap/` for menu resolution. Localization is in `PX.Data/Localization/` (`PXMessages`, `PXLocalizer`) and `WebSites/Pure/Localizations/`.

### Testing infrastructure

Within `NetTools/Tests/`, `*.WSDependent` projects require a deployed site and `*.DbDependent` projects require a database. Shared test utilities are in `Common/PX.Tests.Common/` from the repository root. Application test base classes are in `WebSites/Pure/AppTests/PX.Objects.Tests.Common/`.

## Artifact locations

| Artifact | Location | Notes |
|---|---|---|
| Backend logic | `PX.Objects/<MOD>/*.cs`, satellite projects | graphs, engines, services |
| Graph/DAC extensions | Under the owning module or feature | Search beyond shared `GraphExtensions/` and `CacheExtensions/` folders |
| Data model | The module's `DAC/` | Check nested `PK`/`FK` classes and attributes derived from `PXProjection` |
| DB schema | `DatabaseModel/Application/<MOD>/<Table>.sql`, `DatabaseModel/System/` | file per table; files are picked up by folder, no per-file project registration |
| Migrations | `WebSites/Pure/DB/MSSQL/AppUpdates_<order>_<team>.sql` | Projects team → `AppUpdates_500_PROJ.sql`; per-statement tags `--[MinVersion(…)]`, `--[IfExists(…)]`, `--[mssql|mysql|pgsql: …]`; `MySql/`/`PgSql/` dirs hold only merged files |
| Classic UI | `WebSites/Pure/Site/Pages/<MOD>/<ScreenID>.aspx(.cs)` | graph bound in the `PXDataSource` tag |
| Modern UI | `WebSites/Pure/Site/FrontendSources/screen/src/screens/<Prefix>/<ID>/` | Start with `<ID>.ts`, layouts, and `extensions/`. Shared controls are in `ClientSideApps/client-controls/src/` |
| Reports | `WebSites/Pure/Site/ReportsDefault/<ScreenID>.rpx` | flat folder; locale variants `<ID>.<CC>.rpx` |
| No-code seed data | `WebSites/Pure/DB/EntityXml/<Kind>/` | `Generic Inquiries/` (one XML per GI), `SiteMap/SiteMap.xml`, `MobileSiteMap/<ScreenID>-add.xml` (MSDL script inside XML), `BusinessEvents/`, `Scenarios/`, `Filters/`, `Dashboards/`, `Notification/`, … |
| CB API endpoints | `WebSites/Pure/DB/ContractBasedApiEndpoints/*.endpoint` | versioned per release |
| Data-consistency checks | `WebSites/Pure/DB/DataConsistency/` | incl. `DataConsistencyValidation_ProjectConstruction.sql` |
| Application tests | `WebSites/Pure/AppTests/` | Start with the feature owner or search by the tested type |
| Platform tests | `NetTools/Tests/` | See [Testing infrastructure](#testing-infrastructure) |

## Keeping the map current

Resolve the target branch to a commit. Check paths in that commit's Git tree and open representative declarations before changing the reference revision. Exercise examples where a search can take the wrong turn, such as screen-to-graph bindings across modules, chained graph extensions, DAC inheritance and projections, and framework types that moved. Keep examples that change the search and prune stale inventories.

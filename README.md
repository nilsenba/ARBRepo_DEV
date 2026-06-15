# Scaled Qlik Production Promotion Design

This package uses a centralized reusable GitHub Actions workflow for the Qlik production promotion build.

## Repository Layout

Central workflow repository:

```text
qlik-prod-promotion-workflows/
  .github/workflows/reusable-qlik-prod-promotion.yml
  scripts/Invoke-QlikProdPromotion.ps1
  scripts/Update-DeploymentChangeLog.ps1
  scripts/Add-JiraPromotionComment.ps1
```

Each Qlik-space artifact repository:

```text
Accounts-Receivable/
  .github/workflows/qlik-prod-promotion.yml
  <Qlik package/artifact files committed by Sandbox ARBAutomation>
```

## Promotion Flow

1. Qlik Sandbox automation promotes DEV to UAT and commits the package to the Jira branch, for example `BIOPS-64108`.
2. The automation logs the manifest to `PLAY.DEPLOYMENT_CHANGE_LOG`.
3. UAT validation and signoff happen in Jira.
4. A PR from `BIOPS-64108` to `main` is approved.
5. The space repo caller workflow invokes the central reusable workflow for readiness validation.
6. When the PR merges to `main`, the space repo caller invokes the central reusable workflow for production deployment.
7. The central workflow checks out the space repo artifact, migrates it to Qlik Production, updates Snowflake, and comments on Jira.

## Install Order

1. Create a central repository, for example `ORG-NAME/qlik-prod-promotion-workflows`.
2. Copy `central-workflow-repo/.github/workflows/reusable-qlik-prod-promotion.yml` into that repo.
3. Copy `central-workflow-repo/scripts/*.ps1` into that repo.
4. Commit to `main` and tag a stable version, for example `v1`.
5. In each Qlik-space repo, copy `space-repo-caller/.github/workflows/qlik-prod-promotion.yml`.
6. Replace every `ORG-NAME/qlik-prod-promotion-workflows` placeholder in the caller workflow with the real central repo.
7. Set the optional repository variable `QLIK_PROD_SPACE_NAME` when the production space name cannot safely be derived by replacing repo hyphens with spaces.

## Secret Strategy

Use organization-level secrets when possible, scoped only to the Qlik-space repositories allowed to deploy:

- `QLIK_PROD_TENANT_URL`
- `QLIK_PROD_API_KEY`
- `SNOWFLAKE_ACCOUNT`
- `SNOWFLAKE_USER`
- `SNOWFLAKE_PRIVATE_KEY`
- `SNOWFLAKE_WAREHOUSE`
- `SNOWFLAKE_DATABASE`
- `SNOWFLAKE_SCHEMA`
- `JIRA_BASE_URL`
- `JIRA_EMAIL`
- `JIRA_API_TOKEN`

The caller workflow uses `secrets: inherit`, so repositories in the same organization or enterprise can pass their available secrets to the central reusable workflow.

## Testing

After the caller workflow is merged to `main` in a space repo, run it manually from GitHub Actions with:

- `jira_key`: `BIOPS-64108`
- `source_branch`: `BIOPS-64108`
- `artifact_ref`: `main` or a test commit SHA
- `dry_run`: `true`

Dry run validates naming, context resolution, checkout, QVF discovery, Snowflake payload shape, and Jira payload shape without calling Qlik, Snowflake, or Jira write APIs.


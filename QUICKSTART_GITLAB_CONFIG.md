# GitLab CI/CD Configuration Automation - Quick Start

## Overview
This system automates reading configuration from `Project_Master_Config.xlsx` and injecting it into GitLab CI/CD variables.

## Prerequisites
1. GitLab repository with CI/CD enabled
2. GitLab personal access token with `api` scope
3. Excel file with proper structure

## Setup Instructions

### 1. Configure GitLab Variables
Go to: **Settings → CI/CD → Variables** and add:

| Variable | Value | Protected | Masked |
|----------|-------|-----------|--------|
| `GIT_TOKEN` | Your GitLab personal access token | ✓ | ✓ |

> **Note:** `CI_PROJECT_ID` is automatically provided by GitLab

### 2. Prepare Your Excel File
Ensure `Project_Master_Config.xlsx` has these sheets:

#### Sheet: Variables
```
Key             | Value                  | Environment | Protected
----------------|------------------------|-------------|----------
JAVA_VERSION    | 11                     | ALL         | False
NEXUS_URL       | https://nexus.com      | ALL         | False
NEXUS_PASSWORD  | secret123              | ALL         | True
JAVA_OPTS       | -Xms512m -Xmx1024m     | QA          | False
JAVA_OPTS       | -Xms2048m -Xmx4096m    | PROD        | False
```

#### Sheet: Build_Info
```
Component      | Version        | Maven_Profile
---------------|----------------|---------------
spring-boot    | 2.7.5          | spring
hibernate      | 5.6.12.Final   | persistence
```

### 3. Run the Pipeline

#### Option A: Manual Execution
1. Go to **CI/CD → Pipelines**
2. Click **Run Pipeline**
3. Click on the `configure-project` job when it appears as manual
4. Click **Play** to execute

#### Option B: Automatic Execution
The pipeline runs automatically when you commit changes to:
- `Project_Master_Config.xlsx`
- `config_loader.py`
- Files in `templates/` directory

### 4. Verify Results

#### Check Variables
Go to **Settings → CI/CD → Variables** to see configured variables

#### Download Artifacts
1. Go to **CI/CD → Pipelines**
2. Click on the completed pipeline
3. Click on the `configure-project` job
4. Download artifacts from the right sidebar
5. Extract to see generated configuration files

## Environment Scoping

Variables are automatically scoped:
- `ALL` → Available in all environments (scope: `*`)
- `QA` → Only in QA environment (scope: `qa`)
- `PRE` → Only in PRE environment (scope: `pre`)
- `PROD` → Only in PROD environment (scope: `prod`)

## Templates

Create custom templates in `templates/` directory:
- File extension: `.j2` (Jinja2)
- Access to all variables and build info
- Generated files saved to `generated_configs/`

Example template (`templates/config.yml.j2`):
```jinja2
app:
  name: {{ variables['ALL']['APP_NAME'] }}
  version: {{ build_info['my-app']['version'] }}
```

## Troubleshooting

### "GIT_TOKEN not configured"
- Configure the `GIT_TOKEN` variable in GitLab CI/CD Settings
- Ensure the token has `api` scope

### "Excel file not found"
- Verify `Project_Master_Config.xlsx` is in the repository root
- Check the file name is exactly as specified

### "Column missing in Excel"
- Ensure both sheets have all required columns
- Column names are case-sensitive

## Security Notes

⚠️ **Important:**
- Mark sensitive variables as `Protected: True` in Excel
- Never commit secrets directly in code
- Use GitLab's masked variables for credentials
- Only run pipeline on protected branches for production

## Support

For more details, see `CONFIG_AUTOMATION_README.md`

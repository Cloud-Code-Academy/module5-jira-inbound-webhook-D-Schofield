# Jira Webhook Integration Architecture

## Overview
This document outlines the architecture for the Jira webhook integration, which processes incoming webhooks from Jira through a Glitch middleware to create, update, and delete records in Salesforce.

## Components

### 1. Glitch Middleware
- **Purpose**: Intermediary service between Jira and Salesforce
- **Responsibilities**:
  - Receives webhooks from Jira
  - Uses Connected App, Integration user for JWT flow to get an access token from Salesforce
  - Forwards requests to Salesforce

### 2. WebhookResource
- **Purpose**: Entry point for all webhook requests from Glitch
- **URL Mapping**: `/webhook/*`
- **Responsibilities**:
  - Validates webhook type from URL
  - Routes requests to appropriate handler
  - Handles error responses with appropriate status codes:
    - 200: Successful operation
    - 400: Validation errors (invalid JSON, missing fields, etc.)
    - 500: Unexpected server errors

### 3. JiraWebhookHandler
- **Purpose**: Factory and coordinator for webhook processing
- **Responsibilities**:
  - Determines entity type (issue/project) from webhook event
  - Creates appropriate processor
  - Handles JSON parsing and basic validation
  - Throws WebhookException for validation errors

### 4. Processors
#### JiraIssueProcessor
- **Purpose**: Handles Jira issue webhooks
- **Supported Events**:
  - `jira:issue_created`
  - `jira:issue_updated`
  - `jira:issue_deleted`
- **Responsibilities**:
  - Validates issue-specific data using JiraIssueWrapper
  - Creates/updates/deletes Jira_Issue__c records
  - Uses JiraIssueWrapper for data conversion and validation

#### JiraProjectProcessor
- **Purpose**: Handles Jira project webhooks
- **Supported Events**:
  - `project_created`
  - `project_updated`
  - `project_deleted`
- **Responsibilities**:
  - Validates project-specific data using JiraProjectWrapper
  - Creates/updates/deletes Jira_Project__c records
  - Uses JiraProjectWrapper for data conversion and validation

### 5. Wrappers
#### JiraIssueWrapper
- **Purpose**: Converts Jira issue webhook payload to Salesforce object
- **Fields Mapped**:
  - Issue Key
  - Summary
  - Description
  - Issue Type
  - Status
  - Project Key
  - Priority

#### JiraProjectWrapper
- **Purpose**: Converts Jira project webhook payload to Salesforce object
- **Fields Mapped**:
  - Project Key
  - Project Name
  - Project ID
  - Description
  - Project Type
  - Project Template
  - Lead Information

## Flow Diagram
```
[Jira] → [Glitch Middleware] → [Salesforce WebhookResource]
                                    ↓
                              [JiraWebhookHandler]
                                    ↓
                              ┌─────────┴─────────┐
                              ↓                   ↓
                        [JiraIssueProcessor] [JiraProjectProcessor]
                              ↓                   ↓
                        [JiraIssueWrapper]  [JiraProjectWrapper]
                              ↓                   ↓
                        [Jira_Issue__c]     [Jira_Project__c]
```

## Detailed Request Flow
1. Jira sends webhook to Glitch middleware
2. Glitch middleware:
   - Validates the incoming webhook
   - Transforms the payload if needed
   - Forwards the request to Salesforce
   - Handles any retries if needed
3. Request arrives at Salesforce `/webhook/jira` endpoint
4. WebhookResource validates the request and routes to JiraWebhookHandler
5. JiraWebhookHandler determines the entity type (issue/project) from the webhook event
6. Appropriate processor (JiraIssueProcessor or JiraProjectProcessor) is instantiated
7. Processor validates the request using its wrapper class
8. If validation passes, processor processes the request:
   - Parses the JSON into the wrapper class
   - Converts wrapper to Salesforce object
   - Performs DML operation (create/update/delete)
9. Response is returned to Glitch middleware
10. Glitch middleware handles the response and logs the result

## Design Patterns Used

### 1. Factory Pattern
- JiraWebhookHandler creates appropriate processors based on webhook type
- Allows for easy addition of new processor types
- Decouples processor creation from processor usage

### 2. Strategy Pattern
- Different processors implement IWebhookProcessor
- Allows for different processing strategies for different entity types
- Makes it easy to add new entity types

### 3. Wrapper Pattern
- JiraIssueWrapper and JiraProjectWrapper encapsulate JSON parsing and validation
- Provides type safety and consistent data structure
- Simplifies data conversion between Jira and Salesforce formats

## Error Handling
- Glitch middleware handles retries and temporary failures
- Salesforce returns appropriate HTTP status codes
- Detailed error messages are logged for debugging
- Failed requests are tracked for monitoring 
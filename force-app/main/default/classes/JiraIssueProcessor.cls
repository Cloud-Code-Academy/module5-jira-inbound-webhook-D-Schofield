/**
 * @description Processor class for handling Jira issue webhooks
 */
public class JiraIssueProcessor implements IWebhookProcessor {
    private JiraIssueWrapper wrapper;
    
    /**
     * @description Custom exception class for Jira issue webhook processing errors
     */
    public class IssueWebhookException extends Exception {}
    
    /**
     * @description Validates the webhook request
     * @param request The REST request to validate
     * @return Boolean True if the request is valid
     */
    public Boolean validate(RestRequest request) {
        validateRequestNotNull(request);
        parseAndValidateWrapper(request);
        return true;
    }
    
    /**
     * @description Validates that the request and request body are not null
     * @param request The REST request to validate
     */
    private void validateRequestNotNull(RestRequest request) {
        if (request == null || request.requestBody == null) {
            throw new IssueWebhookException('Invalid request: Request or request body is null');
        }
    }
    
    /**
     * @description Parses the request body into a wrapper and validates its contents
     * @param request The REST request to parse and validate
     */
    private void parseAndValidateWrapper(RestRequest request) {
        try {
            String requestBody = request.requestBody.toString();
            this.wrapper = JiraIssueWrapper.parse(requestBody);
            
            validateWebhookEvent();
            validateIssueData();
        } catch (JSONException e) {
            throw new IssueWebhookException('Invalid JSON in request body: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validates the webhook event type
     */
    private void validateWebhookEvent() {
        if (wrapper.webhookEvent == null || !wrapper.webhookEvent.startsWith('jira:issue_')) {
            throw new IssueWebhookException('Invalid webhook event type: ' + wrapper.webhookEvent);
        }
    }
    
    /**
     * @description Validates the issue data based on the event type
     */
    private void validateIssueData() {
        if (wrapper.issue == null || wrapper.issue.key == null) {
            throw new IssueWebhookException('Invalid issue data: Missing issue or issue key');
        }
        
        // For delete events, we only need the issue key
        if (wrapper.webhookEvent == 'jira:issue_deleted') {
            return;
        }
        
        // For create/update events, we need the fields
        if (wrapper.issue.fields == null) {
            throw new IssueWebhookException('Invalid issue data: Missing fields');
        }
    }
    
    /**
     * @description Processes the webhook request
     * @param request The REST request to process
     * @return Object The processed record (Jira_Issue__c)
     */
    public Object process(RestRequest request) {
        try {
            validate(request);
            
            switch on wrapper.webhookEvent {
                when 'jira:issue_created' {
                    return createIssue(wrapper);
                }
                when 'jira:issue_updated' {
                    return updateIssue(wrapper);
                }
                when 'jira:issue_deleted' {
                    deleteIssue(wrapper);
                    return null;
                }
                when else {
                    throw new IssueWebhookException('Unsupported event type: ' + wrapper.webhookEvent);
                }
            }
        } catch (Exception e) {
            Logger.error('Error processing issue webhook: ' + e.getMessage(), e).addTag('JIRA');
            throw new IssueWebhookException('Failed to process issue webhook: ' + e.getMessage());
        }
    }
    
    private Jira_Issue__c createIssue(JiraIssueWrapper wrapper) {
        Jira_Issue__c newIssue = wrapper.toSObject();
        insert newIssue;
        return newIssue;
    }
    
    private Jira_Issue__c updateIssue(JiraIssueWrapper wrapper) {
        String issueKey = wrapper.issue.key;
        
        List<Jira_Issue__c> existingIssues = [
            SELECT Id, Name, Issue_Key__c, Summary__c, Description__c, Issue_Type__c, Status__c, Project_Key__c
            FROM Jira_Issue__c
            WHERE Issue_Key__c = :issueKey
            LIMIT 1
        ];
        
        if (existingIssues.isEmpty()) {
            throw new IssueWebhookException('Issue not found: ' + issueKey);
        }
        
        Jira_Issue__c existingIssue = existingIssues[0];
        Jira_Issue__c updatedIssue = wrapper.toSObject();
        updatedIssue.Id = existingIssue.Id;
        
        update updatedIssue;
        return updatedIssue;
    }
    
    private void deleteIssue(JiraIssueWrapper wrapper) {
        String issueKey = wrapper.issue.key;
        
        List<Jira_Issue__c> existingIssues = [
            SELECT Id
            FROM Jira_Issue__c
            WHERE Issue_Key__c = :issueKey
            LIMIT 1
        ];
        
        if (!existingIssues.isEmpty()) {
            delete existingIssues[0];
        }
    }
} 
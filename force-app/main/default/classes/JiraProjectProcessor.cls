/**
 * @description Processor class for handling Jira project webhooks
 */
public class JiraProjectProcessor implements IWebhookProcessor {
    private JiraProjectWrapper wrapper;
    
    /**
     * @description Custom exception class for Jira project webhook processing errors
     */
    public class ProjectWebhookException extends Exception {}
    
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
            throw new ProjectWebhookException('Invalid request: Request or request body is null');
        }
    }
    
    /**
     * @description Parses the request body into a wrapper and validates its contents
     * @param request The REST request to parse and validate
     */
    private void parseAndValidateWrapper(RestRequest request) {
        try {
            String requestBody = request.requestBody.toString();
            this.wrapper = JiraProjectWrapper.parse(requestBody);
            
            validateWebhookEvent();
            validateProjectData();
        } catch (JSONException e) {
            throw new ProjectWebhookException('Invalid JSON in request body: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validates the webhook event type
     */
    private void validateWebhookEvent() {
        if (wrapper.webhookEvent == null || !wrapper.webhookEvent.startsWith('project_')) {
            throw new ProjectWebhookException('Invalid webhook event type: ' + wrapper.webhookEvent);
        }
    }
    
    /**
     * @description Validates the project data
     */
    private void validateProjectData() {
        if (wrapper.project == null || wrapper.project.key == null) {
            throw new ProjectWebhookException('Invalid project data: Missing project or project key');
        }
    }
    
    /**
     * @description Processes the webhook request
     * @param request The REST request to process
     * @return Object The processed record (Jira_Project__c)
     */
    public Object process(RestRequest request) {
        try {
            validate(request);
            
            switch on wrapper.webhookEvent {
                when 'project_created' {
                    return createProject(wrapper);
                }
                when 'project_updated' {
                    return updateProject(wrapper);
                }
                when 'project_deleted' {
                    deleteProject(wrapper);
                    return null;
                }
                when else {
                    throw new ProjectWebhookException('Unsupported event type: ' + wrapper.webhookEvent);
                }
            }
        } catch (Exception e) {
            Logger.error('Error processing project webhook: ' + e.getMessage(), e).addTag('JIRA');
            throw new ProjectWebhookException('Failed to process project webhook: ' + e.getMessage());
        }
    }
    
    private Jira_Project__c createProject(JiraProjectWrapper wrapper) {
        Jira_Project__c newProject = wrapper.toSObject();
        insert newProject;
        return newProject;
    }
    
    private Jira_Project__c updateProject(JiraProjectWrapper wrapper) {
        String projectKey = wrapper.project.key;
        
        List<Jira_Project__c> existingProjects = [
            SELECT Id, Project_Key__c, Project_Name__c, Description__c, Project_Type__c
            FROM Jira_Project__c
            WHERE Project_Key__c = :projectKey
            LIMIT 1
        ];
        
        if (existingProjects.isEmpty()) {
            throw new ProjectWebhookException('Project not found: ' + projectKey);
        }
        
        Jira_Project__c existingProject = existingProjects[0];
        Jira_Project__c updatedProject = wrapper.toSObject();
        updatedProject.Id = existingProject.Id;
        
        update updatedProject;
        return updatedProject;
    }
    
    private void deleteProject(JiraProjectWrapper wrapper) {
        String projectKey = wrapper.project.key;
        
        List<Jira_Project__c> existingProjects = [
            SELECT Id
            FROM Jira_Project__c
            WHERE Project_Key__c = :projectKey
            LIMIT 1
        ];
        
        if (!existingProjects.isEmpty()) {
            delete existingProjects[0];
        }
    }
} 
/**
 * @description Handler class for processing Jira webhook requests
 * Implements factory pattern to create appropriate processors for different webhook types
 */
public class JiraWebhookHandler {
    private static final String EVENT_TYPE_FIELD = 'webhookEvent';
    private static final String DELETE_SUFFIX = '_deleted';
    
    /**
     * @description Custom exception class for Jira webhook processing errors
     */
    public class WebhookException extends Exception {}
    
    /**
     * @description Processes a webhook request directly from a RestRequest
     * @param request The REST request containing the webhook payload
     * @return SObject The processed record (Jira_Issue__c or Jira_Project__c)
     */
    public static SObject processRequest(RestRequest request) {
        if (request == null || request.requestBody == null) {
            throw new WebhookException('Invalid request: missing request body');
        }
        
        try {
            String requestBody = request.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            
            String eventType = (String)payload.get(EVENT_TYPE_FIELD);
            if (eventType == null) {
                throw new WebhookException('Missing webhook event type');
            }
            
            IWebhookProcessor processor = getProcessor(payload);
            return (SObject)processor.process(request);
        } catch (WebhookException e) {
            throw e;
        } catch (JSONException e) {
            throw new WebhookException('Invalid JSON in request body');
        } catch (Exception e) {
            Logger.error('Error processing webhook: ' + e.getMessage(), e).addTag('JIRA');
            throw new WebhookException(e.getMessage());
        }
    }
    
    /**
     * @description Gets the appropriate processor for the webhook payload
     * @param payload The webhook payload
     * @return IWebhookProcessor The processor instance
     */
    private static IWebhookProcessor getProcessor(Map<String, Object> payload) {
        String eventType = (String)payload.get(EVENT_TYPE_FIELD);
        String entityType = getEntityType(eventType);
        
        switch on entityType {
            when 'issue' {
                return new JiraIssueProcessor();
            }
            when 'project' {
                return new JiraProjectProcessor();
            }
            when else {
                throw new WebhookException('Unsupported entity type: ' + entityType);
            }
        }
    }
    
    /**
     * @description Gets the entity type from the webhook event
     * @param webhookEvent The webhook event type
     * @return String The entity type (issue or project)
     */
    private static String getEntityType(String webhookEvent) {
        if (webhookEvent == null) {
            throw new WebhookException('Missing webhook event type');
        }
        
        if (webhookEvent.startsWith('jira:issue_')) {
            return 'issue';
        } else if (webhookEvent.startsWith('project_')) {
            return 'project';
        }
        
        throw new WebhookException('Unsupported webhook event: ' + webhookEvent);
    }
} 
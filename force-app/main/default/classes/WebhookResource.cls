/**
 * @description REST resource to handle incoming webhooks from various systems
 * Current implementation supports Jira webhooks at /webhook/jira
 */
@RestResource(urlMapping='/webhook/*')
global class WebhookResource {
    
    /**
     * @description Handles POST requests to the webhook endpoint
     */
    @HttpPost
    global static void doPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        try {
            // Get the webhook type from the URI
            String webhookType = getWebhookTypeFromPath(request.requestURI);
            
            // Process the webhook based on its type
            if (webhookType == 'jira') {
                SObject result = JiraWebhookHandler.processRequest(request);
                
                // For delete operations, we expect null result
                if (result == null) {
                    response.statusCode = 200;
                    Map<String, String> responseMap = new Map<String, String>{
                        'message' => 'Record successfully deleted'
                    };
                    response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
                    return;
                }
                
                // For create/update operations, return the processed record
                response.statusCode = 200;
                response.responseBody = Blob.valueOf(JSON.serialize(result));
                return;
            } else {
                response.statusCode = 400;
                Map<String, String> responseMap = new Map<String, String>{
                    'error' => 'Unsupported webhook type: ' + webhookType
                };
                response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
                return;
            }
            
        } catch (JiraWebhookHandler.WebhookException e) {
            // For validation errors, return 400
            response.statusCode = 400;
            Map<String, String> responseMap = new Map<String, String>{
                'error' => e.getMessage()
            };
            response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
            return;
        } catch (JiraIssueProcessor.IssueWebhookException e) {
            // For validation errors, return 400
            response.statusCode = 400;
            Map<String, String> responseMap = new Map<String, String>{
                'error' => e.getMessage()
            };
            response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
            return;
        } catch (JiraProjectProcessor.ProjectWebhookException e) {
            // For validation errors, return 400
            response.statusCode = 400;
            Map<String, String> responseMap = new Map<String, String>{
                'error' => e.getMessage()
            };
            response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
            return;
        } catch (Exception e) {
            // For unexpected errors, return 500
            response.statusCode = 500;
            Map<String, String> responseMap = new Map<String, String>{
                'error' => e.getMessage()
            };
            response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
            return;
        }
    }
    
    /**
     * @description Extracts the webhook type from the URL path
     * @param path The request URI
     * @return String The webhook type (e.g., "jira")
     */
    private static String getWebhookTypeFromPath(String path) {
        if (path == null) {
            return '';
        }
        
        // Look for the webhook segment in the path
        Integer webhookIndex = path.indexOf('/webhook/');
        
        if (webhookIndex >= 0) {
            // Extract the part after /webhook/
            String remaining = path.substring(webhookIndex + 9);
            
            // If there are additional slashes, only take the first segment
            Integer nextSlash = remaining.indexOf('/');
            if (nextSlash > 0) {
                return remaining.substring(0, nextSlash).toLowerCase();
            }
            
            return remaining.toLowerCase();
        }
        
        return '';
    }
} 
/**
 * @description Interface for webhook processors
 * All webhook processors should implement this interface
 */
public interface IWebhookProcessor {
    
    /**
     * @description Validates the incoming webhook request
     * @param request The REST request containing the webhook payload
     * @return Boolean True if the request is valid, false otherwise
     */
    Boolean validate(RestRequest request);
    
    /**
     * @description Processes the webhook request
     * @param request The REST request containing the webhook payload
     * @return Object The result of processing (can be null, SObject, or any other type)
     */
    Object process(RestRequest request);
} 
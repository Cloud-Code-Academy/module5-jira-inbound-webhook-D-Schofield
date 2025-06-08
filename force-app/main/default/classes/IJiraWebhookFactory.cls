/**
 * @description Interface for Jira webhook factory implementations
 * Defines the contract for creating appropriate processors based on webhook type
 */
public interface IJiraWebhookFactory {
    /**
     * @description Creates and returns the appropriate processor for the webhook payload
     * @param payload The webhook payload
     * @return IWebhookProcessor The processor instance
     */
    IWebhookProcessor createProcessor(Map<String, Object> payload);
} 
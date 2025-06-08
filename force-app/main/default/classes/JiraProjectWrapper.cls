/**
 * @description Wrapper class for Jira Project data
 * Handles conversion between Jira webhook payload and Salesforce Jira_Project__c object
 */
public class JiraProjectWrapper {
    public Long timestamp;
    public String webhookEvent;
    public String projectEventTypeName;
    public User user;
    public Project project;
    
    /**
     * @description Default constructor
     */
    public JiraProjectWrapper() {}
    
    /**
     * @description Parses a JSON string into a JiraProjectWrapper
     * @param jsonString The JSON string to parse
     * @return JiraProjectWrapper The parsed wrapper
     */
    public static JiraProjectWrapper parse(String jsonString) {
        return (JiraProjectWrapper)JSON.deserialize(jsonString, JiraProjectWrapper.class);
    }
    
    /**
     * @description Converts the wrapper to a Jira_Project__c sObject
     * @return Jira_Project__c The Salesforce object
     */
    public Jira_Project__c toSObject() {
        Project proj = this.project;
        return new Jira_Project__c(
            Project_Key__c = proj.key,
            Project_Name__c = proj.name,
            Project_ID__c = proj.id,
            Description__c = proj.description,
            Project_Type__c = proj.projectTypeKey,
            Project_Template__c = proj.projectTemplateKey,
            Lead_Account_ID__c = proj.lead?.accountId,
            Lead_Display_Name__c = proj.lead?.displayName
        );
    }
    
    /**
     * @description Inner class representing user information in the webhook
     */
    public class User {
        public String self;
        public String accountId;
        public String emailAddress;
        public String displayName;
        public Boolean active;
        public String timeZone;
    }
    
    /**
     * @description Inner class representing project in the webhook
     */
    public class Project {
        public String self;
        public String id;
        public String key;
        public String name;
        public String description;
        public String projectTypeKey;
        public String projectTemplateKey;
        public User lead;
    }
} 
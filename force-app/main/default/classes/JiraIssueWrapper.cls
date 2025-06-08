/**
 * @description Wrapper class for Jira Issue data
 * Handles conversion between Jira webhook payload and Salesforce Jira_Issue__c object
 */
public class JiraIssueWrapper {
    public Long timestamp;
    public String webhookEvent;
    public String issueEventTypeName;
    public User user;
    public Issue issue;
    
    /**
     * @description Default constructor
     */
    public JiraIssueWrapper() {}
    
    /**
     * @description Parses a JSON string into a JiraIssueWrapper
     * @param jsonString The JSON string to parse
     * @return JiraIssueWrapper The parsed wrapper
     */
    public static JiraIssueWrapper parse(String jsonString) {
        return (JiraIssueWrapper)JSON.deserialize(jsonString, JiraIssueWrapper.class);
    }
    
    /**
     * @description Converts the wrapper to a Jira_Issue__c sObject
     * @return Jira_Issue__c The Salesforce object
     */
    public Jira_Issue__c toSObject() {
        Fields fields = this.issue.fields;
        return new Jira_Issue__c(
            Issue_Key__c = this.issue.key,
            Summary__c = fields.summary,
            Description__c = fields.description,
            Issue_Type__c = fields.issuetype?.name,
            Status__c = fields.status?.name,
            Priority__c = fields.priority?.name,
            Project_Key__c = fields.project?.key,
            Project_ID__c = fields.project?.id
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
     * @description Inner class representing issue data in the webhook
     */
    public class Issue {
        public String id;
        public String self;
        public String key;
        public Fields fields;
    }
    
    /**
     * @description Inner class representing issue fields in the webhook
     */
    public class Fields {
        public String summary;
        public String description;
        public IssueType issuetype;
        public Status status;
        public Priority priority;
        public Project project;
        public String created;
        public String updated;
    }
    
    /**
     * @description Inner class representing issue type in the webhook
     */
    public class IssueType {
        public String self;
        public String id;
        public String description;
        public String iconUrl;
        public String name;
        public Boolean subtask;
    }
    
    /**
     * @description Inner class representing status in the webhook
     */
    public class Status {
        public String self;
        public String description;
        public String iconUrl;
        public String name;
        public String id;
        public StatusCategory statusCategory;
    }
    
    /**
     * @description Inner class representing status category in the webhook
     */
    public class StatusCategory {
        public String self;
        public Integer id;
        public String key;
        public String colorName;
        public String name;
    }
    
    /**
     * @description Inner class representing priority in the webhook
     */
    public class Priority {
        public String self;
        public String iconUrl;
        public String name;
        public String id;
    }
    
    /**
     * @description Inner class representing project in the webhook
     */
    public class Project {
        public String self;
        public String id;
        public String key;
        public String name;
        public String projectTypeKey;
        public String projectTemplateKey;
        public User lead;
    }
} 
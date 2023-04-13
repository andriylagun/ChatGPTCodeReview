public with sharing class UserSelector {
    public static User getCurrentUserWithRegion() {
        return [SELECT Id, FIN_Current_Region__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }
}
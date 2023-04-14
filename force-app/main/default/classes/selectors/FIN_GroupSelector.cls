public with sharing class FIN_GroupSelector {
    public static Group getGroupByDeveloperName(String developerName) {
        return [SELECT Id FROM Group WHERE DeveloperName = :developerName];
    }
}
public with sharing class Logger {
    public static void log(Exception e, String finProcess, String finRegion) {
        FIN_System_Log__c systemLog = new FIN_System_Log__c();
        systemLog.FIN_Process__c = finProcess;
        systemLog.FIN_Region__c = finRegion;
        systemLog.FIN_Error_Message__c = e.getMessage();
        systemLog.FIN_Error_Time__c = System.now();
        systemLog.FIN_Error_Log__c = e.getStackTraceString();
        insert systemLog;
    }
}
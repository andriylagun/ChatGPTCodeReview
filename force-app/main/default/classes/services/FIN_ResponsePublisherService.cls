public with sharing class FIN_ResponsePublisherService {
    public static void processSystemDataLoadLogResponse(String responseBody) {
        SystemDataLoadLogResponseBodyWrapper responseBodyWrapper = (SystemDataLoadLogResponseBodyWrapper) JSON.deserialize(responseBody, SystemDataLoadLogResponseBodyWrapper.class);
        System.debug(responseBodyWrapper);
        List<FIN_SystemDataLoadLog__c> systemDataLoadLogs = FIN_SystemDataLoadLogSelector.getSystemDataLoadLogByIdIn(new List<String>{
                responseBodyWrapper.systemDataLoadLogId
        });
        if (systemDataLoadLogs.isEmpty()) {
            return;
        }
        FIN_SystemDataLoadLog__c systemDataLoadLog = systemDataLoadLogs.get(0);
        FIN_SystemDataLoadLog__c loadLog = systemDataLoadLog.clone(true, true, false, false);
        if (responseBodyWrapper.isProcessed && !responseBodyWrapper.hasErrors && !responseBodyWrapper.isFromMarkingProcessed) {
            abortCronJobs(systemDataLoadLog);
            FIN_AXSRuleEngineService.markRecordsOnHerokuAsProcessed(systemDataLoadLog);
            return;
        }
        if (responseBodyWrapper.isProcessed && !responseBodyWrapper.hasErrors && responseBodyWrapper.isFromMarkingProcessed) {
            classifyRecords(systemDataLoadLog);
            loadLog.FIN_BusinessRuleProcessCompleteStatus__c = 'Success';
            loadLog.FIN_BusinessRuleEndTime__c = System.now();
            if (responseBodyWrapper.markedAsProcessedCount != null) {
                loadLog.FIN_RecordsProcessed__c += ',\n' + 'Marked as processed records: ' + responseBodyWrapper.markedAsProcessedCount;
            }
            if (responseBodyWrapper.failedRecords != null) {
                loadLog.FIN_RecordsProcessed__c += ',\n' + 'Records was failed: ' + responseBodyWrapper.failedRecords;
            }
            update loadLog;
            return;
        }
        if (responseBodyWrapper.hasErrors) {
            Logger.log(new AuraHandledException(responseBodyWrapper.message + ' sysLoadLog: ' + systemDataLoadLog.Id), systemDataLoadLog.FIN_Process__c, systemDataLoadLog.FIN_Region__c);
            loadLog.FIN_SalesforceRulesStatus__c = 'Failure';
            loadLog.FIN_SalesforceRulesEndTime__c = System.now();
            update loadLog;
            return;
        }
        if (!responseBodyWrapper.isProcessed && !responseBodyWrapper.hasErrors && !responseBodyWrapper.isFromMarkingProcessed) {
            abortCronJobs(systemDataLoadLog);
            FIN_SystemDataLoadLogService.scheduleApexJob(systemDataLoadLog);
        }
        System.debug('In publisher: ' + responseBodyWrapper);
    }

    public static void classifyRecords(FIN_SystemDataLoadLog__c systemDataLoadLog) {
        FIN_UnclassifiedRecordsController.runBatchJob(Constants.finProcessMap.get(systemDataLoadLog.FIN_Process__c), systemDataLoadLog);
    }

    private static void abortCronJobs(FIN_SystemDataLoadLog__c systemDataLoadLog) {
        for (CronTrigger cronTrigger : [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name LIKE :systemDataLoadLog.FIN_Process__c + ' ' + Constants.SYSTEM_DATA_LOAD_LOG_JOB_NAME + '%']) {
            System.abortJob(cronTrigger.Id);
        }
    }


    public class SystemDataLoadLogResponseBodyWrapper {
        public String systemDataLoadLogId;
        public String message;
        public Integer failedRecords;
        public Integer markedAsProcessedCount;
        public Integer salesTransactionsCount;
        public Integer status;
        public Boolean isProcessed;
        public Boolean isFromMarkingProcessed;
        public Boolean hasErrors;
    }
}
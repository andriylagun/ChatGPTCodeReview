public class FIN_SystemDataLoadLogTriggerHandler extends TriggerHandler {
    protected override void afterInsert() {
        for (FIN_SystemDataLoadLog__c dataLoadLog : (List<FIN_SystemDataLoadLog__c>) this.triggerNew) {
            checkMasterDataLoadRecord(dataLoadLog);
        }
        addOrderToDataLoadRecord((List<FIN_SystemDataLoadLog__c>) this.triggerNew);
    }
    protected override void beforeUpdate() {
        for (FIN_SystemDataLoadLog__c dataLoadLog : (List<FIN_SystemDataLoadLog__c>) this.triggerNew) {
            if (dataLoadLog.FIN_StagingTableLoadBusinessApproved__c && dataLoadLog.FIN_BusinessRuleStartTime__c == null && dataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c == null) {
               dataLoadLog.FIN_BusinessRuleStartTime__c = System.now();
               dataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c= 'In-Progress';
            }
            if (dataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c == 'Success' && dataLoadLog.FIN_SalesforceRulesStartTime__c == null) {
                dataLoadLog.FIN_SalesforceRulesStartTime__c = System.now();
                dataLoadLog.FIN_SalesforceRulesStatus__c = 'In-Progress';
            }
        }
    }

    protected override void afterUpdate() {
        for (FIN_SystemDataLoadLog__c dataLoadLog : (List<FIN_SystemDataLoadLog__c>) this.triggerNew) {
            if (((dataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c != 'In-Progress' && dataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c != null)
                    || (dataLoadLog.FIN_SalesforceRulesStatus__c != 'In-Progress' && dataLoadLog.FIN_SalesforceRulesStatus__c != null))
                && dataLoadLog.FIN_StagingTableLoadBusinessApproved__c) {
                if (dataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c == 'Success'
                        && dataLoadLog.FIN_SalesforceRulesStatus__c == 'Failure') {
                } else {
                    if (dataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c == 'Success Heroku') {
                        FIN_SystemDataLoadLogService.scheduleApexJob(dataLoadLog);
                    }
                    if (dataLoadLog.FIN_SalesforceRulesStatus__c == 'In-Progress') {
                        FIN_AXSRuleEngineService.processSettlementRuleEngineFromSystemDataLoadLog(dataLoadLog);
                    }
                }
            } else {
                if (dataLoadLog.FIN_BusinessRuleEndTime__c == null) {
                    checkMasterDataLoadRecord(dataLoadLog);
                }
            }
            if (dataLoadLog.FIN_ProcessCompletionStatus__c != null && dataLoadLog.FIN_ProcessCompletionStatus__c != 'In-Progress') {
//                FIN_SystemDataLoadLogService.sendNotification(dataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c,
//                        dataLoadLog.FIN_Region__c, dataLoadLog);
                EventBus.publish(new FIN_ToastNotification__e(Status__c = dataLoadLog.FIN_ProcessCompletionStatus__c,
                        Message__c = 'Your process was '
                                + (dataLoadLog.FIN_ProcessCompletionStatus__c == Constants.SUCCESS_STATUS ? 'finished successfully' : 'failed please review the errors')));
            }
        }
    }

    private static void checkMasterDataLoadRecord(FIN_SystemDataLoadLog__c dataLoadLog) {
        List<Master_Data_Load__c> mdlList = MasterDataLoadSelector.getMasterDataLoadRecordByProcessDate(dataLoadLog.FIN_ProcessDate__c.date());
        Master_Data_Load__c mdl = mdlList.isEmpty() ? new Master_Data_Load__c() : mdlList[0];
        mdl.put(Constants.getFinProcessMap().get(dataLoadLog.FIN_Process__c), dataLoadLog.Id);
        mdl.ProcessDate__c = dataLoadLog.FIN_ProcessDate__c.date();
        mdl.FIN_Region__c = dataLoadLog.FIN_Region__c;
        upsert mdl;
    }

    private static void addOrderToDataLoadRecord(List<FIN_SystemDataLoadLog__c> dataLoadLogs) {
        List<FIN_SystemDataLoadLog__c> systemDataLoadLogs = new List<FIN_SystemDataLoadLog__c>();
        for (FIN_SystemDataLoadLog__c dataLoadLog : dataLoadLogs) {
            FIN_SystemDataLoadLog__c systemDataLoadLog = new FIN_SystemDataLoadLog__c();
            systemDataLoadLog.Id = dataLoadLog.Id;
            systemDataLoadLog.FIN_OrderToGet__c = Constants.getOrderForSystemDataLoadLogRecords().get(dataLoadLog.FIN_Process__c);
            systemDataLoadLogs.add(systemDataLoadLog);
        }
        update systemDataLoadLogs;
    }
}
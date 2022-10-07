public class FIN_SystemDataLoadLogTriggerHandler extends TriggerHandler {
    protected override void afterInsert() {
        for (FIN_SystemDataLoadLog__c dataLoadLog : (List<FIN_SystemDataLoadLog__c>) this.triggerNew) {
            if (dataLoadLog.FIN_StagingTableLoadBusinessApproved__c) {
                FIN_SystemDataLoadLogService.makeCalloutToHerokuOnApprove(dataLoadLog.Id);
            }
        }
    }
    protected override void beforeUpdate() {
        for (FIN_SystemDataLoadLog__c dataLoadLog : (List<FIN_SystemDataLoadLog__c>) this.triggerNew) {
            if (dataLoadLog.FIN_StagingTableLoadBusinessApproved__c) {
               dataLoadLog.FIN_BusinessRuleStartTime__c = System.now();
               dataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c= 'In-Progress';
            }
        }
    }

    protected override void afterUpdate() {
        for (FIN_SystemDataLoadLog__c dataLoadLog : (List<FIN_SystemDataLoadLog__c>) this.triggerNew) {
            if (dataLoadLog.FIN_StagingTableLoadBusinessApproved__c) {
                FIN_SystemDataLoadLogService.makeCalloutToHerokuOnApprove(dataLoadLog.Id);
            }
        }
    }
}
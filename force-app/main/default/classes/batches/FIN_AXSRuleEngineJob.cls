public with sharing class FIN_AXSRuleEngineJob implements Schedulable {
    public FIN_SystemDataLoadLog__c systemDataLoadLog;

    public FIN_AXSRuleEngineJob(FIN_SystemDataLoadLog__c systemDataLoadLog) {
        this.systemDataLoadLog = systemDataLoadLog;
    }

    public void execute(SchedulableContext param1) {
        FIN_SystemDataLoadLogService.makeSimpleHttpCallout(JSON.serialize(new Map<String, String>{
                'systemDataLoadLogId' => systemDataLoadLog.Id}), 'callout:Records_Check_Heroku');
    }
}
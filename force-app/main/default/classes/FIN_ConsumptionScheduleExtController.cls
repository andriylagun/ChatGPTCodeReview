public with sharing class FIN_ConsumptionScheduleExtController {
    private Id ConsumpSchedId;
    public FIN_ConsumptionScheduleExtController (ApexPages.StandardController stdController) {
        ConsumpSchedId= stdController.getId();
    }
    public PageReference onSubmit() {
        if (ConsumpSchedId!= null) {
            SBAA.ApprovalAPI.submit(ConsumpSchedId, SBAA__Approval__c.Consumption_Schedule__c);
        }
        return new PageReference('/' + ConsumpSchedId);
    }
    public PageReference onRecall() {
        if (ConsumpSchedId!= null) {
            SBAA.ApprovalAPI.recall(ConsumpSchedId, SBAA__Approval__c.Consumption_Schedule__c);
        }
        return new PageReference('/' + ConsumpSchedId);
    }
}
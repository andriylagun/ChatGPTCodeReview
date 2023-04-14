public with sharing class FIN_JournalizingScheduleTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        FIN_JournalizingScheduleHelper.updateStatusesAfterUpdate((List<Journalizing_Schedule__c>) this.triggerNew, (Map<Id, Journalizing_Schedule__c>)this.triggerOldMap);
    }
}
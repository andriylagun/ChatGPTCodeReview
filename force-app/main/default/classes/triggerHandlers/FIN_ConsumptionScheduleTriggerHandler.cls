public with sharing class FIN_ConsumptionScheduleTriggerHandler extends TriggerHandler {
    protected override void afterInsert() {
        FIN_ConsumptionScheduleHelper.createConsumptionRate((List<ConsumptionSchedule>) this.triggerNew, (Map<Id, ConsumptionSchedule>)this.triggerOldMap);
        FIN_ConsumptionScheduleHelper.checkForDuplicates((List<ConsumptionSchedule>) this.triggerNew, (Map<Id, ConsumptionSchedule>)this.triggerOldMap);
    }
    protected override void beforeUpdate() {
        FIN_ConsumptionScheduleHelper.checkForDuplicates((List<ConsumptionSchedule>) this.triggerNew, (Map<Id, ConsumptionSchedule>)this.triggerOldMap);
    }
}
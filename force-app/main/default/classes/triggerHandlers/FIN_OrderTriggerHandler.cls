public with sharing class FIN_OrderTriggerHandler extends TriggerHandler {
    protected override void beforeUpdate() {
        FIN_OrderHelper.updateApprovalStatus((List<Order>) this.triggerNew, (Map<Id, Order>)this.triggerOldMap);
    }

    protected override void afterUpdate() {
        FIN_OrderHelper.orderSharing((List<Order>) this.triggerNew, (Map<Id, Order>)this.triggerOldMap);
        FIN_OrderHelper.createRetroactiveAdjustment((List<Order>) this.triggerNew, (Map<Id, Order>)this.triggerOldMap);
    }

}
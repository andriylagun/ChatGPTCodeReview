public with sharing class FIN_OrderItemTriggerHandler extends TriggerHandler {
    protected override void beforeUpdate() {
        FIN_OrderItemHelper.updateMissingLAField((List<OrderItem>) this.triggerNew);
    }

    protected override void afterUpdate() {
        FIN_OrderItemHelper.createRetroactiveAdjustment((List<OrderItem>) this.triggerNew, (Map<Id, OrderItem>)this.triggerOldMap);
    }
}
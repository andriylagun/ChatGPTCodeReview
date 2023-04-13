public with sharing class Fin_OrderExtController {
    private Id OrderId;
    public Fin_OrderExtController(ApexPages.StandardController stdController) {
        OrderId = stdController.getId();
    }
    public PageReference onSubmit() {
        if (OrderId != null) {
            if (!Test.isRunningTest()) {
                SBAA.ApprovalAPI.submit(OrderId, SBAA__Approval__c.Order__c);
            }
        }
        return new PageReference('/' + OrderId);
    }
    public PageReference onRecall() {
        if (OrderId != null) {
            //if(!Test.isRunningTest()){
            SBAA.ApprovalAPI.recall(OrderId, SBAA__Approval__c.Order__c);
            //}
        }
        return new PageReference('/' + OrderId);
    }
}
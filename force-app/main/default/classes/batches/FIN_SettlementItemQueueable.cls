public class FIN_SettlementItemQueueable implements Queueable {
    public Boolean isForInsertOrUpdate;
    public List<FIN_SettlementItem__c> items;
    public Map<Id, FIN_SettlementItem__c> oldMap;


    public FIN_SettlementItemQueueable(List<FIN_SettlementItem__c> items, Map<Id, FIN_SettlementItem__c> oldMap) {
        this.items = items;
        this.oldMap = oldMap;
        this.isForInsertOrUpdate = false;
    }

    public FIN_SettlementItemQueueable(List<FIN_SettlementItem__c> items, Boolean isForInsertOrUpdate) {
        this.items = items;
        this.isForInsertOrUpdate = isForInsertOrUpdate;
    }

    public void execute(QueueableContext context) {
        if (this.isForInsertOrUpdate) {
            upsert items;
        }
        FIN_SettlementItemHelper.updateStatusesAfterInsert(items, oldMap);
        FIN_SettlementItemHelper.createSettlementLines(items, oldMap);
    }
}
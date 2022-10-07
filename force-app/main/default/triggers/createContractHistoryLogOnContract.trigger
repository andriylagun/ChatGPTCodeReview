trigger createContractHistoryLogOnContract on Contract(after update) {
    List<Contract_History_Log__c> listCHL = new List<Contract_History_Log__c>();

    Contract contractObject = new Contract();
    Schema.SObjectType objType = contractObject.getSObjectType();
    Map<String, Schema.SObjectField> mapFields = Schema.SObjectType.Contract.fields.getMap();

    for(Contract c : trigger.new) {
        Contract oldC = trigger.oldMap.get(c.Id);
        
        for (String str : mapFields.keyset()) {
            if(c.get(str) != oldC.get(str)) {
                listCHL.add(new Contract_History_Log__c(
                    Contract__c = c.Id,
                    Field__c = str,
                    Old_Value__c = String.valueOf(oldC.get(str)),
                    New_Value__c = String.valueOf(c.get(str)),
                    Description__c = str +'was changed from '+ oldC.get(str) + ' to ' +c.get(str)
                ));
            }
        }
    }
    insert listCHL;
}
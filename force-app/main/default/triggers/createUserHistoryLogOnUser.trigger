trigger createUserHistoryLogOnUser on User (after insert, after update) {
    if (Trigger.isInsert) {
        List<User_History_Log__c> listUHL = new List<User_History_Log__c>();
        
        for(User u : Trigger.New) {
            listUHL.add(new User_History_Log__c(
                Description__c = 'was created',
                User__c = u.Id
            ));
        }
        
        insert listUHL;        
    }
    else if (Trigger.isUpdate) {
        List<User_History_Log__c> listUHL = new List<User_History_Log__c>();
        
        User userObject = new User(); 
        Schema.SObjectType objType = userObject.getSObjectType(); 
        Map<String, Schema.SObjectField> mapFields = Schema.SObjectType.User.fields.getMap(); 
        
        for(User u : trigger.new) {
            User oldU = trigger.oldMap.get(u.Id);

            for (String str : mapFields.keyset()) {
                if(u.get(str) != oldU.get(str)) { 
                    listUHL.add(new User_History_Log__c(
                        User__c = u.Id,
                        Field__c = str,
                        Old_Value__c = String.valueOf(oldU.get(str)),
                        New_Value__c = String.valueOf(u.get(str)),
                        Description__c = str +'was changed from '+ oldU.get(str) + ' to ' +u.get(str)             
                    ));
                }
            }
        }
        
        insert listUHL;
    }
}
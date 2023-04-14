public class FIN_SubmitForApprovalApexAction{
  @InvocableMethod(label='Submit For Approval - Apex Action' description='Submit For Approval Apex Action for Order,Contract and Rule Engine')
  public static List<String> getAccountNames(List<ID> ids) {
    
    id firstrecordId= ids[0];

    Schema.SObjectType sobjectType = firstrecordId.getSObjectType();
    String sobjectName = sobjectType.getDescribe().getName();
    System.debug(sobjectName);
    
    for( id myid : ids){
    
        if (sobjectName =='Order'){    
                SBAA.ApprovalAPI.submit(myId, SBAA__Approval__c.Order__c);
         }else if (sobjectName == 'Contract'){
                SBAA.ApprovalAPI.submit(myId, SBAA__Approval__c.Contract__c);
         }else if ( sobjectName == 'FIN_AXSRuleEngine__c'){
                SBAA.ApprovalAPI.submit(myId, SBAA__Approval__c.FIN_AXS_Rule_Engine__c);
         }
     }        
    return null;
  }
}
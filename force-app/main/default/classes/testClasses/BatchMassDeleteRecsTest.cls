@isTest 
public class BatchMassDeleteRecsTest
{
    static testMethod void testMethod1()
    {
        
        Account acc = new Account();
        acc.name='test';
        insert acc;
        
        Test.startTest();

            BatchMassDeleteRecs obj = new BatchMassDeleteRecs('select id from Account limit 1');
            DataBase.executeBatch(obj); 
            
        Test.stopTest();
    }
}
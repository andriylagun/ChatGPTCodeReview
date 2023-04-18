@IsTest
private class FIN_ConsumptionScheduleHelperTest {
    @IsTest
    static void createConsumptionRates() {
        try {

            RecordType rtActoTarget = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SobjectType = 'ConsumptionSchedule'
                AND DeveloperName = 'Accumulation_to_Target'
            ];
            RecordType rtAdvRec = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SobjectType = 'ConsumptionSchedule'
                AND DeveloperName = 'Advance_Recoupment'
            ];

            ConsumptionSchedule newCS1 = new ConsumptionSchedule(
                RecordTypeId = rtActoTarget.Id,
                Name = 'test',
                FIN_Start_Date__c = Date.TODAY()-1,
                Accumulation_to_Target__c = 100
            );
            ConsumptionSchedule newCS2 = new ConsumptionSchedule(
                RecordTypeId = rtActoTarget.Id,
                Name = 'test',
                FIN_Start_Date__c = Date.TODAY()-1
            );
            ConsumptionSchedule newCS3 = new ConsumptionSchedule(
                RecordTypeId = rtAdvRec.Id,
                Name = 'test',
                FIN_Start_Date__c = Date.TODAY()-1,
                Recoupment_Balance__c = 100
            );
            insert newCS1;
            insert newCS2;
            insert newCS3;


            List<ConsumptionRate> crList = [
                SELECT ID
                FROM ConsumptionRate];

            System.assertEquals(3, crList.size());

        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
}
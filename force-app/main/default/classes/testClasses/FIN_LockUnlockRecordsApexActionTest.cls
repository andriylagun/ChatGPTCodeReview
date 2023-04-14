/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Test class for FIN_LockUnlockRecordsApexAction class
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Ivan Liolia
* @modifiedBy     Ivan Liolia
* @version        1.0
* @created        2022-04-12
* @modified       2022-04-12
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            Name
* YYYY-MM-DD      Explanation of the change.  Multiple lines can be used to explain the change, but
*                 each line should be indented till left aligned with the previous description text.
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

@IsTest
public with sharing class FIN_LockUnlockRecordsApexActionTest {

    /**
     * @method      doLock
     * @description tests, that method lock record for the Approval
     * @author      Ivan Liolia - 2022-04-12
     */
    @IsTest
    static void doLock(){
        Account account = TestDataFactory.createAccount();


        Test.startTest();
        FIN_LockUnlockRecordsApexAction.doLockUnlock(new List<Id>{account.Id});
        Test.stopTest();

        System.assertEquals(true, Approval.isLocked(account.Id));
    }

    /**
     * @method      doUnLock
     * @description tests, that method unlock record for the Approval
     * @author      Ivan Liolia - 2022-04-12
     */
    @IsTest
    static void doUnLock(){
        Account account = TestDataFactory.createAccount();

        Approval.LockResult lr = Approval.lock(account.Id, false);

        Test.startTest();
        FIN_LockUnlockRecordsApexAction.doLockUnlock(new List<Id>{account.Id});
        Test.stopTest();

        System.assertEquals(false, Approval.isLocked(account.Id));
    }
}
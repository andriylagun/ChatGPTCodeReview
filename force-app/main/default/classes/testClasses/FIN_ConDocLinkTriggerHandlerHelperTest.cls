/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Test class for Content Document Link trigger handler helper logic
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Ivan Liolia
* @modifiedBy     Ivan Liolia
* @version        1.0
* @created        2022-04-07
* @modified       2022-04-07
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            Name
* YYYY-MM-DD      Explanation of the change.  Multiple lines can be used to explain the change, but
*                 each line should be indented till left aligned with the previous description text.
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

@isTest
public with sharing class FIN_ConDocLinkTriggerHandlerHelperTest {

    /**
     * @method      setFileVisibilityTest
     * @description tests, that after File insertion it's visible to Customer users
     * @author      Ivan Liolia - 2022-04-07
     */
    @isTest
    public static void setFileVisibilityTest() {
        Account account = TestDataFactory.createAccount();
        Contract contract = TestDataFactory.createParentContract(account.Id);

        //Create ContentDocument
        ContentVersion content = new ContentVersion();
        content.Title = 'Header_Picture1';
        content.PathOnClient = '/' + content.Title + '.jpg';
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body');
        content.VersionData = bodyBlob;
        content.origin = 'H';
        insert content;

        //Create ContentDocumentLink
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.LinkedEntityId = contract.id;
        contentLink.ContentDocumentId = [   SELECT ContentDocumentId
                                            FROM   ContentVersion
                                            WHERE  Id =: content.id].ContentDocumentId;
        contentLink.ShareType = 'I';
        contentLink.Visibility = 'InternalUsers';

        Test.startTest();
            insert contentLink;
        Test.stopTest();

        ContentDocumentLink updatedDocumentLink = [ SELECT ShareType
                                                    ,      Visibility
                                                    FROM   ContentDocumentLink
                                                    WHERE  Id = :contentLink.Id];

        Assert.areEqual('AllUsers', updatedDocumentLink.Visibility, 'New created File should be shared to Customer Users');
        Assert.areEqual('V', updatedDocumentLink.ShareType, 'New created File should be shared with View access');
    }
}
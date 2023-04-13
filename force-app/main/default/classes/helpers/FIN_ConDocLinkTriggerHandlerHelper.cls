/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Content Document Link trigger handler helper, used by the FIN_ConDocLinkTriggerHandler
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Ivan Liolia
* @modifiedBy     Ivan Liolia
* @version        1.0
* @created        2022-03-31
* @modified       2022-01-31
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            Name
* YYYY-MM-DD      Explanation of the change.  Multiple lines can be used to explain the change, but
*                 each line should be indented till left aligned with the previous description text.
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

public with sharing class FIN_ConDocLinkTriggerHandlerHelper {

    /**
     * @method      setFileVisibility
     * @description set File visibility to Customer Users
     * @author      Ivan Liolia - 2022-05-07
     */
    public static void setFileVisibility(List<ContentDocumentLink> files) {
        for (ContentDocumentLink file : files) {
            if (file.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Contract') {
                file.Visibility = 'AllUsers';
                file.ShareType = 'V';
            }
        }
    }
}
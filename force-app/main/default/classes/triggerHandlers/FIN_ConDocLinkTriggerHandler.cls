/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Content Document Link trigger handler, used by the Content Document Link trigger
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

public with sharing class FIN_ConDocLinkTriggerHandler extends TriggerHandler{

    public override void beforeInsert() {
        // SFCA-474, grant access to files for Customer users
        FIN_ConDocLinkTriggerHandlerHelper.setFileVisibility((List<ContentDocumentLink>) Trigger.new);
    }
}
@IsTest
private class TriggerHandlerTest {

    @IsTest
    static void testExecute() {

        TriggerHandler handler = new TriggerHandler();
        handler.init(TriggerOperation.BEFORE_INSERT, null, null, null);
        handler.execute();

        handler.operation = TriggerOperation.BEFORE_UPDATE;
        handler.execute();

        handler.operation = TriggerOperation.AFTER_UPDATE;
        handler.execute();

        handler.operation = TriggerOperation.AFTER_INSERT;
        handler.execute();

        handler.operation = TriggerOperation.BEFORE_INSERT;
        handler.execute();

        handler.operation = TriggerOperation.AFTER_DELETE;
        handler.execute();
    }
}
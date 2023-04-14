@IsTest
private class TriggerHandlerFactoryTest {

    @IsTest
    static void testBehavior() {

        try {
            TriggerHandlerFactory.executeHandler(null, null, null, null, null);

        } catch(Exception e) {
            System.assertEquals('Trigger handler class cannot be null!', e.getMessage());
        }

        TriggerHandlerFactory.executeHandler(TriggerHandler.class, TriggerOperation.AFTER_INSERT, null, null, null);
    }
}
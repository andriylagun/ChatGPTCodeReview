public class TriggerHandlerFactory {

    public static void executeHandler(final Type handlerClass, final System.TriggerOperation operation, final List<SObject> triggerNew,
            final Map<Id, SObject> triggerNewMap, final Map<Id, SObject> triggerOldMap) {
        if (null == handlerClass) {
            throw new TriggerHandlerFactoryException('Trigger handler class cannot be null!');
        }
        TriggerHandler handler = (TriggerHandler) handlerClass.newInstance();
        handler.init(operation, triggerNew, triggerNewMap, triggerOldMap);
        handler.execute();
    }

    public class TriggerHandlerFactoryException extends Exception {
    }
}
@IsTest
private class BooleanExpressionTest {
    @IsTest
    static void testEvaluate() {
        String x = '(true OR false) AND true';

        Assert.areEqual(true, BooleanExpression.evaluate(x));
    }
}
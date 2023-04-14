public class BooleanExpression {
    static Boolean orJoin(String x, String y) {
        return evaluate(x) || evaluate(y);
    }
    static Boolean andJoin(String x, String y) {
        return evaluate(x) && evaluate(y);
    }
    static Boolean isSimpleExpression(String x) {
        return x == 'true' || x == 'false';
    }
    static String simplify(String x) {
        x = x.trim();
        while (x.contains('(')) {
            String sub = x.substringAfterLast('(').substringBefore(')');
            x = x.replace('(' + sub + ')', String.valueOf(evaluate(sub)));
        }
        return x;
    }
    public static Boolean evaluate(String x) {
        if (x != null) {
            x = simplify(x);
            if (!isSimpleExpression(x)) {

                if (x.contains('AND')) {
                    List<String> elements = x.split('AND', 2);
                    return andJoin(elements[0], elements[1]);
                }
                if (x.contains('OR')) {
                    List<String> elements = x.split('OR', 2);
                    return orJoin(elements[0], elements[1]);
                }
            }
        }
        return Boolean.valueOf(x);
    }
}
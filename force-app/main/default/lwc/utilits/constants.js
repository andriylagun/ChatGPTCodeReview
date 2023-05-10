import PAYMENT_OBJECT from '@salesforce/schema/FIN_Payment__c';
import PAYMENT_DISTRIBUTION_OBJECT from '@salesforce/schema/FIN_PaymentDistribution__c';
import SALES_TRANSACTIONS_OBJECT from '@salesforce/schema/OrderItem';
export const PAYMENT_SOBJECT_API = PAYMENT_OBJECT.objectApiName;
export const PAYMENT_DISTRIBUTION_SOBJECT_API = PAYMENT_DISTRIBUTION_OBJECT.objectApiName;
export const SALES_TRANSACTIONS_SOBJECT_API = SALES_TRANSACTIONS_OBJECT.objectApiName;
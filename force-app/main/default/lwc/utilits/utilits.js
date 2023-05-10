import { LightningElement, wire } from 'lwc';
import {handlePlatformEvent} from "./toastByPlatformEvent";
import { subscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
export {PAYMENT_SOBJECT_API, PAYMENT_DISTRIBUTION_SOBJECT_API, SALES_TRANSACTIONS_SOBJECT_API} from "./constants";

export default class Utilits extends LightningElement {
    subscription = null;
    channelName = '/event/FIN_ToastNotification__e';

    connectedCallback() {
        this.subscribeToChannel();
    }

    @wire(isEmpEnabled)
    wiredEmpEnabled({ error, data }) {
        if (error) {
            console.error('Error in empApi enabled check:', error);
        } else if (data) {
            setDebugFlag(data);
        }
    }

    subscribeToChannel() {
        if (!this.subscription) {
            subscribe(this.channelName, -1, (event) => {
                handlePlatformEvent(event);
            })
                .then((response) => {
                    this.subscription = response;
                    console.log('Successfully subscribed to:', this.channelName);
                })
                .catch((error) => {
                    console.error('Error in subscription:', error);
                });
        }
    }

    errorCallback(error) {
        console.error('Error in toastNotificationService:', error);
        onError(error);
    }
}
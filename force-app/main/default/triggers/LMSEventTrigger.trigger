trigger LMSEventTrigger on FLIP_Event__c (after update) {
    if (system.isFuture()) {
        return;
    }

    for (Id eventId : Trigger.newMap.keySet() ) {
        FLIP_Event__c oldEvent = Trigger.oldMap.get( eventId ), newEvent = Trigger.newMap.get( eventId );
        
        if (oldEvent.Send_to_LMS__c != newEvent.Send_to_LMS__c ||
            oldEvent.Event_Date__c != newEvent.Event_Date__c ||
            oldEvent.Event_End_Date__c != newEvent.Event_End_Date__c ||
            oldEvent.Start_Time__c != newEvent.Start_Time__c ||
            oldEvent.End_Time__c != newEvent.End_Time__c ||
            oldEvent.Event_Full_Name__c != newEvent.Event_Full_Name__c ||
            oldEvent.Event_Description_Rich__c != newEvent.Event_Description_Rich__c ||
            oldEvent.Delivery_Address__c != newEvent.Delivery_Address__c
        ) {
            List<Attendees__c> attendees = [
                SELECT Id,
                    FLIP_Event__r.Id
                FROM Attendees__c
                WHERE FLIP_Event__r.Id = :eventId
            ];

            Datetime oldStart = LMS.getEventDateTime(oldEvent.Event_Date__c, oldEvent.Start_Time__c),
                oldEnd = LMS.getEventDateTime(oldEvent.Event_End_Date__c, oldEvent.End_Time__c);
            
            LMS.onEventUpdate(attendees, oldStart, oldEnd, oldEvent.Event_Name__c);
        }
    }
}
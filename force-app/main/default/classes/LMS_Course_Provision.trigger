trigger LMS_Course_Provision on TL_Programme__c (after insert, after update) {
    if (system.isFuture()) {
        return;
    }
    
    Boolean LMS_Access_Changed = false;
    if (Trigger.isUpdate) {
        for (Id courseId : Trigger.newMap.keySet() ) {
            if (Trigger.oldMap.get( courseId ).LMS_Access__c != Trigger.newMap.get( courseId ).LMS_Access__c ) {
                LMS_Access_Changed = true;
            }
        }
    }
    
    if (Trigger.isInsert || LMS_Access_Changed) {
        LMS.onCourseInsertOrUpdate(Trigger.newMap.keySet());
    }
}

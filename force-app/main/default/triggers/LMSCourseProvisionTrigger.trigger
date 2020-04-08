trigger LMSCourseProvisionTrigger on TL_Programme__c (after insert, after update) {
    if (system.isFuture()) {
        return;
    }
    
    for (Id courseId : Trigger.newMap.keySet() ) {
        if (Trigger.isInsert) {
            LMS.onCourseInsert(courseId);
            continue;
        }

        TL_Programme__c oldCourse = Trigger.oldMap.get( courseId ), newCourse = Trigger.newMap.get( courseId );

        if (oldCourse.LMS_Access__c != newCourse.LMS_Access__c ||
            oldCourse.LMS_Provision_Primary_Course__c != newCourse.LMS_Provision_Primary_Course__c
        ) {
            LMS.onCourseInsert(courseId);
        }

        if (oldCourse.Programme_Name__c != newCourse.Programme_Name__c ||
            oldCourse.Cohort_Name__c != newCourse.Cohort_Name__c ||
            oldCourse.LMS_Start_Date__c != newCourse.LMS_Start_Date__c ||
            oldCourse.LMS_End_Date__c != newCourse.LMS_End_Date__c
        ) {
            LMS.onCourseUpdate(courseId);
        }
    }
}
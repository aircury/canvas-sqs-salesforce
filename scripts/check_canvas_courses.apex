List<TL_Programme__c> programmes = [
SELECT Name,
    Programme_Name__c,
    Cohort_Name__c,
    LMS_Course_Id__c,
    LMS_Course_Section_Id__c,
    LMS_Start_Date__c,
    LMS_End_Date__c
FROM TL_Programme__c
WHERE LMS_Access__c = true AND
    LMS_Course_Id__c != null
];

System.debug(LoggingLevel.INFO, 'Programmes: ' + programmes.size());

for (TL_Programme__c programme: programmes) {
    try {
        CanvasAPI.findCourseById(String.valueOf(programme.LMS_Course_Id__c));
    } catch (CanvasAPIException caught) {
        if (caught.getMessage().contains('The specified resource does not exist')) {
            System.debug(LoggingLevel.INFO, 'Non existent course: ' + programme.Name + ' ' + programme.Programme_Name__c + ' ' + programme.Cohort_Name__c);
            continue;
        }
        throw caught;
    }
}

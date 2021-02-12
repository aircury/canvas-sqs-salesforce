List<AsyncApexJob> jobs = [
    SELECT Id, JobType, ApexClass.Name, CompletedDate, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, ExtendedStatus, MethodName
    FROM AsyncApexJob
    WHERE ApexClass.Name LIKE '%LMS%'
        AND (Status = 'Failed' or NumberOfErrors > 0)
        AND CompletedDate < TODAY
        AND CompletedDate >= YESTERDAY
];

for (AsyncApexJob job: jobs) {
    System.debug(LoggingLevel.INFO, job.ApexClass.Name + ' ' + job);
}

# Canvas/Salesforce Integration

## Apex Classes Deployment

Download the [zip](https://github.com/aircury/canvas-sqs-salesforce/archive/master.zip) with all the code.

Install the [Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm#sfdx_setup_install_cli) (sfdx command)

To authorize the Salesforce CLI to use the Salesforce Org, run:
```sfdx force:auth:web:login -r https://test.salesforce.com```

And finally deploy with executed on the directory where the zip was extracted:
```sfdx force:source:deploy --sourcepath force-app```

## APEX Runtime requirements

### CanvasAPI Class

This class needs a Custom Setting named as CanvasAPISettings with 3 fields:

1. Token: to store an API Access token created on Canvas with an admin user
2. Base_Url: the base url endpoint for the Canvas instance. For example <https://ambition.instructure.com/api/v1.>
   The base url also needs to be added on Remote Sites (Setup->Security Controls->Remote Site Settings)
3. Account_Id: Canvas account Id used to create courses or users on that Canvas account. For example: account id 1
    is the "Ambition School Leadership" main and only account on <https://ambition.instructure.com>

### Scheduled Job

In order to provision Canvas user on LMS course start date, a new scheduled Job running the
ScheduledLMSUsersProvision apex class needs to be created (Setup->Build->Develop->Apex Classes->Schedule Apex).
Recommended to schedule it nightly at 01:00 am.

### TL_Programme new fields

1. LMS_Course_Id__c of type Number(10, 0) (External ID)
2. LMS_Course_Section_Id__c of type Number(10, 0) (External ID)

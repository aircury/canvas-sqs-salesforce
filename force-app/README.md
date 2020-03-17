# Salesforce > Canvas Subproject

## Overview

The subproject uses the Canvas REST API to create the user requested resources on the Canvas side.

For example, when a Salesforce user creates or updates a TL_Programme__c object, the implementation will call the Canvas API to create a Course and a Course Section attached to the Course.

## Salesforce objects to Canvas resources mapping

| Salesforce Objects          | Actions                | Canvas Resources                           | Canvas APIs                                                                                                                                                                                                                                  |
|-----------------------------|------------------------|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| TL_Programme__c             | Create, Update         | Courses, Sections                          | [Courses API](https://canvas.instructure.com/doc/api/courses.html), [Sections API](https://canvas.instructure.com/doc/api/sections.html)                                                                                                     |
| Programme_Participant__c    | Create, Update, Delete | Users, Enrollments, Communication Channels | [Users API](https://canvas.instructure.com/doc/api/users.html), [Enrollments API](https://canvas.instructure.com/doc/api/enrollments.html), [Communication Channels API](https://canvas.instructure.com/doc/api/communication_channels.html) |
| FLIP_Event__c, Attendees__c | Create, Update, Delete | Calendar Events                            | [Calendar Events API](https://canvas.instructure.com/doc/api/calendar_events.html)                                                                                                                                                           |

## Apex Classes Deployment

During development, it's recommendable to use the Salesforce CLI to quick upload the code. There is a [Makefile](../Makefile)
file in the root repository directory to help to upload code an run tests. Also Visual Studio Code with the
"Salesforce Extension Pack" provides helpers to develop and use the Salesforce CLI from the IDE.

Install the [Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm#sfdx_setup_install_cli) (sfdx command)

To authorize the Salesforce CLI to use the Salesforce Org, run:

* ```sfdx force:auth:web:login -r https://test.salesforce.com```

You can upload the code to the Salesforce Org executing the next command on the root repository directory:

* ```sfdx force:source:deploy --sourcepath force-app```

Also you can run (you need GNU Make previously installed):

* ```make apex_deploy``` to upload the code
* ```make apex_tests``` to run tests

## APEX Runtime requirements

### CanvasAPI Class

This class needs a Custom Setting named as CanvasAPISettings with 4 fields:

1. Token: to store an API Access token created on Canvas with an admin user
2. Base_Url: the base url endpoint for the Canvas instance. For example <https://ambition.instructure.com/api/v1.>
   The base url also needs to be added on Remote Sites (Setup->Security Controls->Remote Site Settings)
3. Account_Id: Canvas account Id used to create courses or users on that Canvas account. For example: account id 1
    is the "Ambition School Leadership" main and only account on <https://ambition.instructure.com>
4. Participant_Role_Id__c: Role id of the Participant role in Canvas. For example 13 (the default if not filled) is
   the "Participant" role id on the Canvas instance <https://ambition.instructure.com>.

### Scheduled Job

In order to provision Canvas user on LMS course start date, a new scheduled Job running the
[ScheduledLMSUsersProvision](main/default/classes/ScheduledLMSUsersProvision.cls) apex class needs to be created (Setup->Build->Develop->Apex Classes->Schedule Apex).
Recommended to schedule it nightly at 01:00 am.

### TL_Programme new fields

1. LMS_Course_Id__c of type Number(10, 0) (External ID)
2. LMS_Course_Section_Id__c of type Number(10, 0) (External ID)

## APEX Code Structure

All the bussiness logic has been implemented on the [LMS](main/default/classes/LMS.cls) class that could trigger the exception [LMSException](main/default/classes/LMSException.cls).

All the connection with Canvas API helper functions are on the [CanvasAPI](main/default/classes/CanvasAPI.cls) class. Those functions could trigger the exception [CanvasAPIException](main/default/classes/CanvasAPIException.cls).

The tests are on [LMSTest](main/default/classes/LMSTest.cls) class that uses the [CanvasAPIMock](main/default/classes/CanvasAPIMock.cls) class to simulate Canvas api calls during tests because it's not a good practice to use real API calls in tests and Salesforce doesn't allow them.

There are 5 triggers and 1 scheduled job to implement all the Salesforce > Canvas requirements defined at <https://docs.google.com/spreadsheets/d/1wrlmlsveUWOU-wRrQCz7IkTjvPRm1Wg3CLgnka4Ec6c>:

### [LMSCourseProvisionTrigger](main/default/classes/LMSCourseProvisionTrigger.trigger)

This trigger implements the "Cohorts that require access to Canvas need to be created in Salesforce and mirrored in Canvas" requirement of the "Course provisioning".

It acts when a TL_Programme__c is created or updated, but only when:

* The LMS_Access__c is checked
* The Programme_Name__c, Cohort_Name__c, LMS_Start_Date__c  or LMS_End_Date__c changes

The actions are executed inmediatelly (live) and consists on:

* Create or update a Course in Canvas side
* Create or update a Course Section in Canvas attached to the course
* On create only, store in the TL_Programme__c the Canvas Course id and the Course Section id to help other actions implementation.

The LMS_Start_Date__c and LMS_End_Date__c can be nulls after the implementation of a new requirement.

The logic never removes a Canvas Course when the LMS_Access__c is unchecked.

The Canvas Course name and code are built from Programme_Name__c and Cohort_Name__c. Also this is used for the Canvas Course Section name.

The Canvas Course start date and end date are setted from LMS_Start_Date__c and LMS_End_Date__c respectively.

### [LMSProgrammeParticipantStatusTrigger](main/default/classes/LMSProgrammeParticipantStatusTrigger.trigger)

This trigger implements some of the "User provisioning" requirements:

* "When a user withdraws or defers from the programme, their access to Canvas needs to be removed"
* "If an active LMS users details change, this needs to be updated in Canvas" (partially)

It acts when a Programme_Participant__c is created or updated, but only when:

* The related TL_Programme__c has LMS_Access__c checked
* Today is between the related TL_Programme__c LMS_Start_Date__c and LMS_End_Date__c
* When the related Contact has Email not null

The actions are executed inmediatelly (live) and consists on:

* Update the Canvas User name if the ParticipantName__c changed
* Create or update the Canvas User with the related enrollment status on the related Canvas Course. For 'Active', the enrollment will be 'active' in Canvas. For 'Inactive, the enrollment will be 'inactive' in Canvas. For 'Complete', 'Deferred' or 'Withdrawn' the Canvas User is removed from Canvas only if the Canvas User is not enrolled in another Canvas Course related with any other TL_Programme__c. If the Canvas User is enrolled, then the enrollment status will be updated as 'conclude' on Canvas.

#### Canvas User data sources

The Canvas User email is setted from the Programme_Participant__c related Contact Email field.

The Canvas User name is setted from the Programme_Participant__c related Contact Name field.

The Canvas User short name is setted from the Programme_Participant__c related Contact Prefered_Name__c field if not null. If null, then is setted from then Name field.

The Canvas User sis_user_id is setted from the Contact Participant_UID__c field. That allows to locate Canvas Users through the Canvas API using a Salesforce side unique identifier (map Participants with Canvas Users).

### [ScheduledLMSUsersProvision](main/default/classes/ScheduledLMSUsersProvision.cls)

This is a Cron Job that should be executed nightly.

It implements some of the "User Provisioning" requirements:

* "When the LMS start date arrives, all programme participants will need to be provisioned in Canvas so that they can access the system"
* "When a cohort is finished, user access to Canvas needs to be removed"

Also, it implements some of the "Events provisioning" requirements:

* "When a participant has been invited to a cohort-specific event in Salesforce, it should appear in their individual calendar in Canvas"

It iterates over all the TL_Programme__c with:

* LMS_Access__c checked.
* Today is between LMS_Start_Date__c and LMS_End_Date__c.

As a Cron Job, the actions are only executed when defined in the Cron Job, and consists on:

* Provision Canvas Users if today is LMS_Start_Date__c according to the Programme_Participant__c currently in the TL_Programme__c. It creates the Canvas Users with the related enrollment status on the related Canvas Course. For 'Active', the enrollment will be 'active' in Canvas. For 'Inactive, the enrollment will be 'inactive' in Canvas. For 'Complete', 'Deferred' or 'Withdrawn' the Canvas User is not created.
* Add Canvas Calendar Events attached to the Canvas User if today is LMS_Start_Date__c. It iterates over all Attendees__c that:
  * are on every FLIP_Event__c defined in the TL_Programme__c that has the Send_to_LMS__c checked
  * the related Contact has Email not null
* Remove Canvas Users if today is LMS_End_Date__c and if the Canvas User is not enrolled in another Canvas Course related with any other TL_Programme__c. If the Canvas User is enrolled, then the enrollment status will be updated as 'conclude' on Canvas.

The Canvas User data is setted like defined in [Canvas User data sources](#canvas-user-data-sources).

#### Canvas Calendar Event data sources

The Canvas Calendar Event attached to the Canvas User fields are:

* title: from FLIP_Event__c Event_Full_Name__c field.
* description: from FLIP_Event__c Event_Description_Rich__c field if not empty.
* address: built from FLIP_Event__c Delivery_Address__c field or blank string if null.

### [LMSContactTrigger](main/default/classes/LMSContactTrigger.trigger)

This trigger implements partially the requirement "If an active LMS users details change, this needs to be updated in Canvas" of the "User provisioning".

It acts when a Contact is updated but only when:

* The field updated is any of:
  * FirstName
  * LastName
  * Prefered_Name__c
  * Email
* The Contact is related with a Programme_Participant__c
* The Emails is not null
* The Programme_Participant__c is related with an TL_Programme__c with:
  * LMS_Access__c checked
  * Today is between LMS_Start_Date__c and LMS_End_Date__c

The actions are executed inmediatelly (live) and consists on:

* Update the Canvas User name and short name
* If the Email changed:
  * Delete the Canvas User Communication Channel using the old Email
  * Create a new Canvas User Communication Channel using the new Email
  * Update the default Canvas User email

### [LMSEventAttendeesProvisionTrigger](main/default/classes/LMSEventAttendeesProvisionTrigger.trigger)

This trigger implements some of the "Events provisioning" requirements:

* "When a participant has been invited to a cohort-specific event in Salesforce, it should appear in their individual calendar in Canvas"
* "When a participant has been deleted from a cohort-specific event in Salesforce, it should be removed from their individual calendar in Canvas"

It acts when an Attendees__c is created or deleted but only when:

#### On creation

* the related FLIP_Event__c has Send_to_LMS__c checked
* the related TL_Programme__c has:
  * LMS_Access__c checked.
  * Today is between LMS_Start_Date__c and LMS_End_Date__c.
* the related Contact Email filed is not null

#### On deletion

* the related TL_Programme__c has:
  * LMS_Access__c checked.
  * Today is between LMS_Start_Date__c and LMS_End_Date__c.
* the related Contact Participant_UID__c filed is not null

The actions are executed inmediatelly (live) and consists on:
  
* Create or delete Canvas Calendar Events attached to the Canvas User

The Canvas Calendar Event attached to the Canvas User fields are the same as defined in [Canvas Calendar Event data sources](#canvas-event-data-sources).

### [LMSEventTrigger](main/default/classes/LMSEventTrigger.trigger)

This trigger implements some of the "Events provisioning" requirements:

* "When details of an event are changed in Salesforce, this needs to be updated in Canvas"

It acts when an FLIP_Event__c is updated but only when any of the next FLIP_Event__c fields changed:

* Send_to_LMS__c
* Event_Date__c
* Event_End_Date__c
* Start_Time__c
* End_Time__c
* Event_Full_Name__c
* Event_Description_Rich__c
* Delivery_Address__c

The actions are executed inmediatelly (live) and consists on:

* Delete all the Canvas Calendar Events attached to the Canvas User for all the Attendees__c related with the FLIP_Event__c. The same restrictions defined on [LMSEventAttendeesProvisionTrigger "On deletion"](#on-deletion) applies. To locate the old Canvas Calendar Event to remove it, the old Event_Date__c, Start_Time__c, Event_End_Date__c and End_Time__c is used.
* Create all the Canvas Calendar Events attached to the Canvas User for all the Attendees__c related with the FLIP_Event__c. The same restrictions defined on [LMSEventAttendeesProvisionTrigger "On creation"](#on-creation) applies.

The Canvas Calendar Event attached to the Canvas User fields are the same as defined in [Canvas Calendar Event data sources](#canvas-event-data-sources).

## Design decisions

* All the requirements except 1 are implemented as triggers. Salesforce doesn't allow to directly execute external API calls from triggers, so all the API calls and next salesforce model updates are executed using Apex Jobs (functions defined as @future(callout=true)). Those jobs can be listed on Setup->Environments->Jobs->Apex Jobs.

* All the connections to the Canvas REST API are authenticated using a unique Canvas administrator user access token. That simplifies the OAuth flow. So, all the actions triggered from Salesforce will be executed on Canvas on behalf of that User. As an administrator user, the action can be on behalf of any Canvas user when needed; for example when adding events to a user calendar.

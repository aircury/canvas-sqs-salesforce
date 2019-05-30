# Canvas > Salesforce Subproject

## Overview

Canvas LMS has a feature called [Canvas Live Events](https://community.canvaslms.com/docs/DOC-9067-how-do-i-configure-live-events-for-canvas-data) that allows organizations to receive realtime messages about executed Canvas actions. For example, if a Canvas user sends a Quiz, a message is sent with details about the submission that then can be processed by the organization.

The Live Events are sent to an AWS SQS queue by Canvas and are formatted according to the [IMS Caliper 1.1 standard](https://www.imsglobal.org/caliper-analytics-v11-introduction).

This subproject is responsible to process every message received on the AWS SQS queue attached to the Ambition Institute Canvas LMS instance and accordingly update the Ambition Institute Salesforce instance data using the [Salesforce REST API](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/intro_what_is_rest_api.htm). The subprojects also uses the [Canvas REST API](https://canvas.instructure.com/doc/api/index.html) to get more details about the received Canvas Live Event when needed.

## Design decisions

An [AWS Lambda](https://aws.amazon.com/lambda/) function is used to process every message received at the AWS SQS queue. In brief, an AWS Lambda function stores the developped code and executes it on a managed infrastructure when new messages arrives to the AWS SQS queue.

The python language programming is used on the AWS Lambda function because it as easy bindings to connect/work with Canvas REST API ([canvasapi](https://github.com/ucfopen/canvasapi)) and Salesforce REST API ([simple-salesforce](https://pypi.org/project/simple-salesforce/)).

All the AWS Lambda logging output is stored on AWS CloudWatch. The logging level (```DEBUG``` by default) can be controlled using the ```LOG_LEVEL``` AWS Lambda function environment variable.

## Requirements

* An AWS account with priveleges to create and manage AWS SQS and AWS Lambda.

* A new AWS SQS queue needs to be provisioned to receive Canvas Live Events following [these steps](https://community.canvaslms.com/docs/DOC-14163-how-do-i-create-an-sqs-queue-to-receive-live-events-data-from-canvas).

* The Canvas instance needs to be [configured](https://community.canvaslms.com/docs/DOC-14182-4214848302) to send Canvas Live Events to the created AWS SQS queue.

* In order to use the Salesforce REST API, a Salesforce administrator user credentials and security token is needed.

* In order to use the Canvas REST API, a Canvas administrator user access token is needed.

## Deployment

There is a [GNU Make file](./Makefile) with different targets to provision or update the AWS Lambda function:

* ```make install```: to initially create the AWS Lambda function. It needs the AWS CLI command to access AWS, configured with valid credentials. Copy first the [.env.dist](./.env.dist) file to .env and edit the .env with the correct parameters. After install, you need to manually attach the AWS SQS queue to the AWS Lambda function using the AWS web interface.

* ```make deploy```: to update the AWS Lambda function code with the local modifications.

* ```make uninstall```: to remove the AWS Lambda function.

## Canvas Live Event types

Canvas LMS has internally different Live Events types, such ```quiz_submitted``` or ```logged_in```. But at the AWS SQS queue they are formatted using IMS Caliper standard. That standard only knows about "Caliper Event", "Caliper Action" and "Caliper Object", not Canvas Live Events types. So, Canvas uses a map (documented [here](https://github.com/instructure/canvas-lms/blob/3afdafe5ae246d22bcaaa841bd63c036853c075d/doc/api/caliper_live_events.md#event-mapping)) to convert Canvas Live Event types to "Caliper Event", "Caliper Action" and "Caliper Object".

The implementation uses a similar map but in the reverse way, defined at [canvas_live_events.py](./canvas_live_events.py) named ```EVENT_MAP```.

## Code Structure

The AWS Lambda entry point is the ```lambda_handler``` function at the [process-sqs-records.py](./process-sqs-records.py) file. That function receives one or more
AWS SQS queue messages. The Canvas Live Event is received in the ```body``` field of the message.

The Canvas Live Event is first identified using the reverse map (Caliper format to Canvas Live Event type) and processed by one of the functions defined at [canvas_live_events.py]. If not possible to map the Canvas Live Event, then an error is logged with useful information to help to map it if needed. Depending on the Canvas Live Event type a function or another is used. The function should return the related Salesforce participant UID, the related Canvas Course id, the Activity name and the Activity detail in human readable format. To get all that information, some Canvas REST API calls could be needed, depending on the Canvas Live Event type. All that information will be used to fill the Salesforce Canvas_Activitiy__c.

After mapping the Canvas Live Event with a Salesforce Canvas_Activitiy__c, the same ```lambda_handler``` function at the [process-sqs-records.py](./process-sqs-records.py) file, is responsible to connect to Salesforce REST API and create the Canvas_Activitiy__c object only if it is related with a participant UID on a TL_Programme__c with today between LMS_Start_Date__c and LMS_End_Date__c. If the Canvas Live Event is related with a Canvas Course, then the related paticipant TL_Programme__c LMS_Course_Id__c should match with the Canvas Course Id. With that, the "The engagement of participants with their usage of the online platform needs to be tracked in Salesforce" requirement defined at <https://docs.google.com/spreadsheets/d/1wrlmlsveUWOU-wRrQCz7IkTjvPRm1Wg3CLgnka4Ec6c> is accomplished.

Finally, if the Canvas Live Event is related with a Salesforce Attendees__c object and the related FLIP_Event__r name matches the Canvas Live Event quiz name or submission name, then the Salesforce FLIP_Event__r is marked as attended (Event_Attended__c to true for the Attendees__c object). With that, the requirements "When a submission is required by a participant as part of the programme (NPQ, Assignment, Quiz/Assessment) this needs to be tracked in Salesforce" and "Completion of an online module by a participant in Canvas needs to be reported on in Salesforce" are accomplished.

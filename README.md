# Canvas/Salesforce Integration

## Overview

This project allows the Ambition Institute Salesforce instance to interoperate with the Ambition Institute Canvas LMS instance.

It uses a new specific model implemented on Salesforce to interoperate with Canvas LMS. With the new model help's, the project can provision new Courses, Users and Events directly from Salesforce. Internally, the project uses the [Canvas REST API](https://canvas.instructure.com/doc/api/) to transparently create the requested resources. Also, Salesforce receives tracking activity data from Canvas LMS thanks to the [Canvas Live Events](https://community.canvaslms.com/docs/DOC-9067-how-do-i-configure-live-events-for-canvas-data).

## [Salesforce > Canvas Subproject](force-app/README.md)

## [Canvas > Salesforce Subproject](lambda/README.md)

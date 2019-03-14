# Canvas/Salesforce Integration

## Apex Classes Deployment

Download the [zip](https://github.com/aircury/canvas-sqs-salesforce/archive/master.zip) with all the code.

Install the [Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm#sfdx_setup_install_cli) (sfdx command)

To authorize the Salesforce CLI to use the Salesforce Org, run:
```sfdx force:auth:web:login -r https://test.salesforce.com```

And finally deploy with executed on the directory where the zip was extracted:
```sfdx force:source:deploy --sourcepath force-app```

## APEX Runtime requirements

TBC

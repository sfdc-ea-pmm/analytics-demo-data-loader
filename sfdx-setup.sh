sfdx force:auth:web:login -d -a DevHub
mkdir mdapioutput
sfdx force:source:convert -d mdapioutput/
sfdx force:mdapi:deploy -d mdapioutput/ -u DevHub -w 100
#Survey App

This app was used to obtain the list of commits with warnings to generate the payload of
the survey request message. It was also used to deliver the survey page and to log the
result of the survey

**This service might not be able to run correctly**

## Setup
* Update the _conf/application.conf_ file with the warningsguru database information. This
service needs to be using the same database. 
* Update the _conf/application.conf_ file with github credentials. This is used to allow
the inclusion of the changed code sample
* Run `sbt run`
* Navigate to `http://localhost:9000/api/admin/review ` to obtain list of possible commits
to send survey requests for

## APIs / Pages
### Admin
####GET     /api/admin/review 
Gets the list of possible commit surveys to send
   
####GET     /api/admin/review/message/:project/:commit
Generate email message payload to send manually

####GET     /api/admin/review/message/:project/:commit/sent  
Log that the email survey as been sent

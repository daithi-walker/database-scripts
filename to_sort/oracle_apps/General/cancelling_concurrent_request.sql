Cancelling Concurrent Request from backend (script) + Concurrent Request Status Codes and Phase Codes

from: http://dbahut.blogspot.ie/2013/04/cancelling-concurrent-request-from.html

Concurrent Request Status Codes and Phase Codes

Use below query to cancel all scheduled concurrent programs.
===================================================
UPDATE fnd_concurrent_requests
SET phase_code = 'C', status_code = 'X'
WHERE status_code IN ('Q','I')
AND requested_start_date > SYSDATE
AND hold_flag = 'N';

COMMIT;

=====================================================
TO cancel all running concurrent programs.

UPDATE fnd_concurrent_requests
SET phase_code = 'C', status_code = 'X'
WHERE status_code IN ('R','I');
Commit;


Concurrent Request Phase Codes:-

SELECT LOOKUP_CODE, MEANING
  FROM FND_LOOKUP_VALUES
 WHERE LOOKUP_TYPE = 'CP_PHASE_CODE' AND LANGUAGE = 'US'
       AND ENABLED_FLAG = 'Y';

To Cancel Specific request:
++++++++++++++++++++++++++++++++
update fnd_concurrent_requests
set status_code='D', phase_code='C'
where request_id=<request id>;

LOOKUP_CODE MEANING
C           Completed
I           Inactive
P           Pending
R           Running

Concurrent Request Status Codes:-

SELECT LOOKUP_CODE, MEANING
  FROM FND_LOOKUP_VALUES
 WHERE LOOKUP_TYPE = 'CP_STATUS_CODE' AND LANGUAGE = 'US'
       AND ENABLED_FLAG = 'Y';

LOOKUP_CODE MEANING
R           Normal
I           Normal
Z           Waiting
D           Cancelled
U           Disabled
E           Error
M           No Manager
C           Normal
H           On Hold
W           Paused
B           Resuming
P           Scheduled
Q           Standby
S           Suspended
X           Terminated
T           Terminating
A           Waiting
G           Warning

Normally a concurrent request proceeds through three, possibly four, life cycle stages or phases,
Phase Code  Meaning with Description
Pending     Request is waiting to be run
Running     Request is running
Completed   Request has finished
Inactive    Request cannot be run

Within each phase, a requests condition or status may change. Below appears a listing of each phase and the various states that a concurrent request can go through.

The status and the description of each meaning given below:

Phase          Status      Description
PENDING        Normal      Request is waiting for the next available manager.
               Standby     Program to run request is incompatible with other program(s) currently running.
               Scheduled   Request is scheduled to start at a future time or date.
               Waiting        A child request is waiting for its Parent request to mark it ready to run. For example, a report in a report set that runs sequentially must wait for a prior report to complete.
RUNNING        Normal      Request is runnng normally.
               Paused      Parent request pauses for all its child requests to complete. For example, a report set pauses for all reports in the set to complete.
               Resuming    All requests submitted by the same parent request have completed running. The Parent request is waiting to be restarted.
               Terminating Running request is terminated, by selecting Terminate in the Status field of   the Request Details zone.
COMPLETED      Normal      Request completes normally.
               Error       Request failed to complete successfully.
               Warning     Request completes with warnings. For example, a report is generated successfully but fails to print.
               Cancelled   Pending or Inactive request is cancelled, by selecting Cancel in the Status field of the Request Details zone.
               Terminated  Running request is terminated, by selecting Terminate in the Status field of   the Request Details zone.
INACTIVE       Disabled    Program to run request is not enabled. Contact your system administrator.
               On Hold     Pending request is placed on hold, by selecting Hold in the Status field of the Request Details zone.
               No Manager  No manager is defined to run the request. Check with your system administrator.
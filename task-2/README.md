# Task 2 - Incident Response

## Scenario

End user lost the work laptop

## Incident Response Runbook

A lost laptop is a critical incident that needs to be addressed promptly. While the investigation section comes before incident response, there are time-critical steps from incident response that need to be done immediately, such as:
* Wiping the device remotely
* Isolating the device from the network
* Revoking accesses

Depending on the organization layout, these initial steps are likely taken by IT before the incident is handed over to the security team for further actions.

### [Investigation]

* Ask the end user for information regarding the incident:
    * Was the device logged in and active on any accounts?
    * If the device was logged in, what data was accessed?
    * What files were stored locally?
    * What time did the theft happen?

We can't expect the end user to answer all of these specifically, but any information could help understand the impact of the incident. 
* Determine the user's access level
    * As different end users have access to different things, it's important to understand what access needs to be revoked. For example, a developer will need to have SSH keys removed.
* Review user account activity after theft - if the laptop was access by an unauthorized user, we want to make sure that no backdoor has been placed.
    * Was MFA or Email changed?

### [Incident Response]
* Wipe the device remotely
* Remove access from the device to internal network and services. Generally this is Active Directory and VPN, however it depends on the user's access level established in earlier step.
* Reset passwords for user's accounts
* Reset active user sessions
    * Some services keep old session regardless of password change. If this is an internal service behind a VPN, then this is not a big issue, however if it's public facing the user session needs to be reset.
* Add user to watchlist and continuously monitor activity
    * Were accounts accessed after laptop was lost?
* Was the laptop stolen? Inform the legal department so local authorities can be notified

### [Post Incident Response]

* Write a report on the incident, highlighting steps taken
* Lessons Learned
    * Should the playbook be updated?
    * Should additional security measures be implemented?
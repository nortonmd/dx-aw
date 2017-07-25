trigger BugEmailNotification on CM_Bug__c ( after insert, after update) {

    Set<CM_Bug__c> bugs = new Set<CM_Bug__c>();
    Set<Id> assignedToIds = new Set<Id>();
    Set<Id> backlogIds = new Set<Id>();
    
    for ( CM_Bug__c bug : Trigger.new ) {
        // Skip records that don't have an assigned to
        if ( bug.Assigned_To__c == null ) {
            continue;
        }
        
        // Always send for inserts, assigned to changes, and status changes
        if ( Trigger.isInsert ||
			 bug.Assigned_To__c != null && bug.Assigned_To__c != Trigger.oldMap.get( bug.Id).Assigned_To__c ||
			 bug.Status__c != null && bug.Status__c != Trigger.oldMap.get( bug.Id).Status__c ) {
            bugs.add( bug);
            assignedToIds.add( bug.Assigned_To__c);
            backlogIds.add( bug.Backlog_Item__c);
        }
    }

    System.debug( 'There were ' + bugs.size() + ' bugs that need notifications');
	Map<Id,User> userMap = new Map<Id,User>([select Id, Name, Email from User where Id in :assignedToIds]);
	Map<Id,CM_Backlog_Item__c> blMap = new Map<Id,CM_Backlog_Item__c>( [select Id, Name, Backlog_Id__c from CM_Backlog_Item__c where Id in :backlogIds]);
	System.debug( 'userMap size is ' + userMap.size() + ', and blMap size is ' + blMap.size());
    
    // Now iterate through building the emails
    for ( CM_Bug__c bug : bugs ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { userMap.get( bug.Assigned_To__c).Email };
        mail.setToAddresses( toAddresses );
        mail.setSenderDisplayName('Agile Way Bug Notification');
        mail.setSubject( 'Agile Way - Bug Updated');

		String body = 'A Bug created in Agile Way has been updated.';
		body += '<p>';
		body += 'Bug: <a href=https://na7.salesforce.com/' + bug.Id + '> ' + bug.Name + '</a><br/>';
		body += 'Assigned To: <b>' + userMap.get( bug.Assigned_To__c).Name + '</b><br/>';
		body += 'Status: <b>' + bug.Status__c + '</b><br/>';
		body += '</p>';

		// If this is related to a backlog item, show backlog item id and name
		body += '<p>';
		body += 'Backlog Item: <a href=https://na7.salesforce.com/' + bug.Backlog_Item__c + '>' + blMap.get( bug.Backlog_Item__c).BackLog_ID__c + ' ' + blMap.get( bug.Backlog_Item__c).Name + '</a><br/>';
		body += '</p>';
        mail.setHtmlBody( body);

        // Send the email you have created.
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

}
/*
 * Backlog Item Task Helper
 * Create tasks when the status of backlog items changes
 * Change the status of a backlog item when tasks are completed
 */
// Only Global if certain methods are @future
//global class BacklogItemTaskHelper { 
public class BacklogItemTaskHelper {

	public static final String AUTOMATIC_TASK_TYPE = 'System Generated';
	
	// These are the backlog Items that will cause action to be taken
	public static final String READY_FOR_QA_DEPLOY_STATUS = 'Ready for QA Deploy';
	public static final String READY_FOR_QA_STATUS = 'Ready for QA';
	public static final String READY_FOR_UAT_DEPLOY_STATUS = 'Passed QA / Ready for UAT Deploy';
	public static final String READY_FOR_UAT_STATUS = 'Ready for UAT';
	public static final String READY_FOR_PROD_STATUS = 'Passed UAT / Ready for Production Deploy';
	public static Set<String> TASK_STATUS_SET = new Set<String> { READY_FOR_QA_DEPLOY_STATUS, READY_FOR_QA_STATUS, 
																  READY_FOR_UAT_DEPLOY_STATUS, READY_FOR_UAT_STATUS};
	
	// A Map with Leads and the User ID's in that role
	private static final String EM_LEAD_ROLE = 'Environment Management Lead';
	private static final String QA_LEAD_ROLE = 'Quality Assurance Lead';
	private static final String OPS_LEAD_ROLE = 'Business Operations Manager';
	private static Set<String> LEAD_ROLES = new Set<String> { EM_LEAD_ROLE, QA_LEAD_ROLE, OPS_LEAD_ROLE };
	private static Map<String, User> leadUserMap =  BacklogItemTaskHelper.loadLeadUserMap();
	
	// A Map with all of the sprints and their significant dates
	private static final Map<ID, CM_Sprint__c> sprintMap = new Map<ID, CM_Sprint__c>( [select id, name, QA_Deploy_Date__c, QA_Signoff_Date__c, UAT_Deploy_Date__c, UAT_Signoff_Date__c from CM_Sprint__c]);
	
	// Create tasks for backlog items
	//@future - Not doing these in the future for now.
	public static void createTasks( Set<ID> backlogItemIDs) {
		//System.debug( 'BacklogItemTaskHelper:createTasks with ' + backlogItemIDs.size() + ' Items.');
		
		List<Task> tasks = new List<Task>();
		
		// Loop through the backlog items creating tasks for each
		for ( CM_Backlog_Item__c bi : BacklogItemTaskHelper.getBacklogItems(backlogItemIDs)) {
			Task t = new Task();
			t.Subject = 'Agile Way Automated Task';
			t.Description = 'An Agile Way Backlog Item Status has changed to [' + bi.Status__c + ']';
			t.WhatId = bi.id;
			t.Type = BacklogItemTaskHelper.AUTOMATIC_TASK_TYPE;
			
			// Determine the due date of the task from the sprint (Note: Done separately because BI might not have a sprint)
			t.ActivityDate = BacklogItemTaskHelper.getTaskDueDate( bi.Sprint__c, bi.Status__c);
			
			// Key Here.  The backlog item's current status is put into the task so that when it is completed (the task), 
			// the trigger will fire and the backlog item's status will be pushed to the next value
			t.Current_Backlog_Item_Status__c = bi.Status__c;
			
			// Evaluate the task owner based on the status			
			if ( bi.Status__c == READY_FOR_QA_DEPLOY_STATUS ) {
				t.OwnerId = leadUserMap.get( EM_LEAD_ROLE).id;
				t.Subject += ' - Deploy Backlog Item Components to QA';
				t.Description += '\nDeploy Backlog Item to QA [' + bi.BackLog_ID__c + ' ' + bi.name + ']';
			} else if ( bi.Status__c == READY_FOR_QA_STATUS ) {
				t.OwnerId = leadUserMap.get( QA_LEAD_ROLE).id;
				t.Subject += ' - QA Backlog Item';
				t.Description += '\nQA Test Backlog Item [' + bi.BackLog_ID__c + ' ' + bi.name + ']';
			} else if ( bi.Status__c == READY_FOR_UAT_DEPLOY_STATUS) {
				t.OwnerId = leadUserMap.get( EM_LEAD_ROLE).id;
				t.Subject += ' - Deploy Backlog Item Components to UAT';
				t.Description += '\nDeploy Backlog Item to UAT [' + bi.BackLog_ID__c + ' ' + bi.name + ']';
			} else if ( bi.Status__c == READY_FOR_UAT_STATUS ) {
				t.OwnerId = leadUserMap.get( OPS_LEAD_ROLE).id;
				t.Subject += ' - UAT Backlog Item';
				t.Description += '\nUAT Test Backlog Item [' + bi.BackLog_ID__c + ' ' + bi.name + ']';
			} else {
				System.debug( 'BacklogItemTaskHelper:createTasks - Invalid Status on Backlog Item');
				t.OwnerId = UserInfo.getUserId(); // Assign to originator
			}
			
			tasks.add( t);
		}
		
		//System.debug( 'BacklogItemTaskHelper:createTasks - Tasks to created: ' + tasks.size());
		if ( tasks.size() > 0 ) {
			insert tasks;
		}

		// Try to create emails for these tasks
		try {
			// Now create the emails.  I don't think you can automatically generate the emails when the tasks are created.
			List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
			for ( Task t : tasks) {
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
				String[] toAddresses = new String[] { BacklogItemTaskHelper.getEmailByUserId( t.ownerId) };
				email.setToAddresses( toAddresses);
				email.setSubject( 'Agile Way Automated Task Notification');
				String body = '<b>Task Comments</b><br/> ' + t.Description.replace( '\n', '<br/>') + '<br/><br/>';
				body += '<b>Due Date:</b> ' + t.ActivityDate + '<br/><br/>';
				body += 'To view the task <a href=https://' + BacklogItemTaskHelper.getPod() + '.salesforce.com/' + t.id + '> Click Here</a>';
				body += '<br/><br/><b>Note:</b> By changing the status of this Task to ';
				body += '<i>Completed</i> the Backlog Item will be progressed to the next Status.';
				email.setHtmlBody( body);
				emails.add( email);
			}
			Messaging.sendEmail(emails);
		} catch ( Exception e) {
			System.debug( 'ERROR:::Exception occurred trying to send email for tasks.  ' + e.getMessage());
		}
	}

	// Pull Date from the sprint
	private static Date getTaskDueDate( ID sprintId, String biStatus ) {
		Date dueDate;
		try {
			if ( biStatus == READY_FOR_QA_DEPLOY_STATUS) {
				dueDate = BacklogItemTaskHelper.sprintMap.get( sprintId).QA_Deploy_Date__c;
			} else if ( biStatus == READY_FOR_QA_STATUS) {
				dueDate = BacklogItemTaskHelper.sprintMap.get( sprintId).QA_Signoff_Date__c;
			} else if ( biStatus == READY_FOR_UAT_DEPLOY_STATUS) {
				dueDate = BacklogItemTaskHelper.sprintMap.get( sprintId).UAT_Deploy_Date__c;
			} else if ( biStatus == READY_FOR_UAT_STATUS) {
				dueDate = BacklogItemTaskHelper.sprintMap.get( sprintId).UAT_Signoff_Date__c;
			} else {
				dueDate = null;
			}
		} catch ( Exception e) {
			System.debug( 'ERROR:::Exception occurred trying to get task due date: ' + e.getMessage());
		}
		return dueDate;
	}
	
	// Get Pod
	private static String getPod() {
		// This code is not portable between SFDC orgs.  It's tied to one specific production instance.
		if ( UserInfo.getOrganizationId() == '00DA0000000c3lf') {
			return 'login';
		} else {
			return 'test';
		}
	}
	
	// Get Email address by User Id
	private static String getEmailByUserId( ID userId ) {
		//System.debug( 'DEBUG:::Searching for Email address for user ID [' + userId + ']...');
		for ( User u : leadUserMap.values()) {
			if ( u.id == userId ) {
				//System.debug( 'DEBUG:::Found email address [' + u.Email + ']');
				return u.Email;
			}
		}
		
		return '';
	}

	// Update status for backlog items
	//@future - Not doing these in the future for now.
	public static void updateBacklogItemStatus( Set<ID> backlogItemIDs) {

		// Loop through the backlog items creating tasks for each
		List<CM_Backlog_Item__c> backlogItems = BacklogItemTaskHelper.getBacklogItems(backlogItemIDs);
		for ( CM_Backlog_Item__c bi : backlogItems) {
			String output = 'Backlog Item ' + bi.name + ' Changing Status from [' + bi.Status__c + ']';
			// Evaluate the next status based on the current status			
			if ( bi.Status__c == READY_FOR_QA_DEPLOY_STATUS) {
				bi.Status__c = READY_FOR_QA_STATUS;
			} else if ( bi.Status__c == READY_FOR_QA_STATUS ) {
				bi.Status__c = READY_FOR_UAT_DEPLOY_STATUS;
			} else if ( bi.Status__c == READY_FOR_UAT_DEPLOY_STATUS) {
				bi.Status__c = READY_FOR_UAT_STATUS;
			} else if ( bi.Status__c == READY_FOR_UAT_STATUS ) {
				bi.Status__c = READY_FOR_PROD_STATUS;
			} else {
				System.debug( 'BacklogItemTaskHelper:updateBacklogItemStatus - Untracked Status on Backlog Item');
			}
			output += ' to [' + bi.Status__c + ']';
			//System.debug( 'DEBUG:::' + output);
			
			update backlogItems;
			
		}		
	}

	// Generic method to get the Backlog Items via the IDs
	private static List<CM_Backlog_Item__c> getBacklogItems( Set<ID> backlogItemIDs) {
		return [select id, Name, BackLog_ID__c, Component_Count__c, Status__c, Sprint__c from CM_Backlog_Item__c where id in :backlogItemIDs];
	}
	
	// Get a map of the leads and the users
	private static Map<String, User> loadLeadUserMap() {
		Map<String, User> userMap = new Map<String, User>();
		for ( User u : [Select id, Username, Email, UserRole.Name From User where UserRole.Name in :LEAD_ROLES] ) {
			if ( !userMap.containsKey( u.UserRole.Name)) {
				userMap.put( u.UserRole.Name, u);
			}			
		}
		
		//System.debug( 'BacklogItemTaskHelper:loadLeadUserMap - Size of userMap is ' + userMap.size());
		return userMap;
	}
}
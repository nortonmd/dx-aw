trigger BacklogItemStatusChange on CM_Backlog_Item__c (after update) {

	// This list will contain the backlog items that need tasks created
	Set<ID> backlogIDSet = new Set<ID>();

	// Loop through backlog items looking for status values that require action
	for ( CM_Backlog_Item__c backlogItem : Trigger.new ) {
		// First, see if the status has changed, then see if it's in the list of statuses to change.
		if ( backlogItem.Status__c != Trigger.oldMap.get( backlogItem.id).Status__c &&
			BacklogItemTaskHelper.TASK_STATUS_SET.contains( backlogItem.Status__c) ) {
				backlogIDSet.add( backlogItem.id);
		}
	}
	
	// If there are any Backlog Items than need tasks created call the helper class
	if ( backlogIDSet.size() > 0 ) {
		System.debug( 'BacklogItemStatusChange:Number of Backlog Items that need tasks created: ' + backlogIDSet.size());
		BacklogItemTaskHelper.createTasks( backlogIDSet);
	}

}
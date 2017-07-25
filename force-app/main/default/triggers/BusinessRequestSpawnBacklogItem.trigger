/*
 * Business Request Spawn a Backlog Item
 */
trigger BusinessRequestSpawnBacklogItem on Business_Request__c (after insert, after update) {

    System.debug( LoggingLevel.DEBUG, 'Inside BusinessRequestSpawnBacklogItem Trigger');

    // Only works for a single edits on BRs
    if ( Trigger.new.size() != 1 ) {
        System.debug( LoggingLevel.WARN, 'Business Requests can only spawn Backlog Items when records are edited individually');
        return;
    }
    
    // Can't do a before insert, but can certainly check for it
    if ( Trigger.isInsert ) {
        System.debug( LoggingLevel.DEBUG, 'Cannot spawn Backlog Items on Insert');
        if ( Trigger.new[0].Status__c == 'Approved by Business') {
            Trigger.new[0].addError( 'Cannot create a Business Request in Approved by Business Status');
        }
        return;
    }
    
    System.debug( LoggingLevel.DEBUG, 'Checking Spawn Flag, Status, and Status Changes...');
    Business_Request__c br = Trigger.new[0];
    // Only spawn if no others were spawned, it's approved, and it wasn't already approved
    if ( br.Backlog_Item_Spawned__c == null &&
         br.Status__c == 'Approved by Business' &&
         br.Status__c <> Trigger.oldMap.get( br.Id).Status__c)  {

        System.debug( LoggingLevel.DEBUG, 'Spawning a new backlog item');

        // Create a new backlog item
        CM_Backlog_Item__c newBL = new CM_Backlog_Item__c();
        newBL.Name = br.Name;
        newBL.Origin__c = br.Category__c;
        newBL.Description__c = br.Description__c;
        newBL.Priority__c = br.Priority__c;
        newBL.Business_Request__c = br.Id;
        insert newBL;

        // Transfer notes    
        List<Note> notes = new List<Note>();
        for ( Note n : [Select Title, IsPrivate, Body 
        					  from Note
        					 where ParentId = :br.Id] ) {
            notes.add( new Note( ParentId = newBL.Id, Title = n.Title, IsPrivate = n.IsPrivate, Body = n.Body));
        }
        if ( notes.size() > 0 ) {     
            insert notes;
        }
        
        // Transfer Attachments
        List<Attachment> attachments = new List<Attachment>(); 
        for ( Attachment a : [Select Name, IsPrivate, Description, ContentType, Body 
        								  from Attachment 
        								 where ParentId = :br.Id] ) {
			attachments.add( new Attachment( parentId = newBL.Id, Name = a.Name, IsPrivate = a.IsPrivate, 
											 Description = a.Description, ContentType = a.ContentType, Body = a.Body));
        }
        if ( attachments.size() > 0 ) {
            insert attachments;
        }

        // This should avoid another update based on the spawned flag
        update new Business_Request__c( Id = br.Id, Backlog_Item_Spawned__c = newBL.Id);
    }
    System.debug( LoggingLevel.DEBUG, 'Exiting BusinessRequestSpawnBacklogItem');
}
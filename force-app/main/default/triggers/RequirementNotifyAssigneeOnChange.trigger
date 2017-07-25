trigger RequirementNotifyAssigneeOnChange on CM_Requirement__c ( after insert, after update) {

    // Load up changed Ids
    List<ID> changedIds = new List<ID>();
    for ( CM_Requirement__c req : Trigger.new ) {
        if ( Trigger.isInsert) { 
            changedIds.add( req.id);
        } else if ( Trigger.isUpdate && req.Status__c != Trigger.oldMap.get( req.id).Status__c) {
            changedIds.add( req.id);
        }
    }
    System.debug( 'Number of changed requirements is ' + changedIds.size());
    if ( changedIds.size() == 0 ) {
        return;
    }

    // Load Up changedReqs
    List<CM_Requirement__c> changedReqs = new List<CM_Requirement__c>();
    changedReqs = [select id, Name, Status__c, Summary__c, Backlog_Item__c, Backlog_Item__r.Name,
                          Backlog_Item__r.Assigned_To__c, Backlog_Item__r.Assigned_To__r.Email, 
                          Backlog_Item__r.Backlog_Id__c
                     from CM_Requirement__c
                    where id in :changedIds];
    System.debug( 'Total number of changedReqs is ' + changedReqs.size());
    
    // Based on insert 
    for ( CM_Requirement__c req : changedReqs ) {
        System.debug( 'DEBUG:::Backlog Item is ' + req.Backlog_Item__c);
        System.debug( 'DEBUG:::Assigned To is ' + req.Backlog_Item__r.Assigned_To__c);

        if ( req.Backlog_Item__c != null && req.Backlog_Item__r.Assigned_To__c != null ) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] { req.Backlog_Item__r.Assigned_To__r.Email };
            mail.setToAddresses( toAddresses);
            mail.setSenderDisplayName( 'Agile Way');
            mail.setSubject( 'Agile Way Backlog Item Requirement Update');
    
            String body = '<b>A Requirement record has been changed in Agile Way for a backlog item you own.</b><br/><br/>';
            body += 'The Backlog Item is: <a href="https://login.salesforce.com/' + req.Backlog_Item__c + '">';
            body += req.Backlog_Item__r.Backlog_Id__c + ' ' + req.Backlog_Item__r.Name + '</a><br/><br/>';
            body += 'Requirement: <a href="https://login.salesforce.com/' + req.id + '">';
            body += req.Name + ' ' + req.Summary__c + '</a><br/><br/>';
            body += 'Requirement Status is: <font color="red"><b><big>' + req.Status__c + '</big></b></font><br/>';
            mail.setHtmlBody( body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    
}
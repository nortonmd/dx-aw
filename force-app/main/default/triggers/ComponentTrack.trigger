trigger ComponentTrack on CM_Component__c ( before insert, before update) {

    List<CM_Component__c> comps = new List<CM_Component__c>();
    Set<String> compNames = new Set<String>();
    
    for ( CM_Component__c comp : Trigger.new ) {
        if ( Trigger.isInsert ) {
            comps.add( comp);
            compNames.add( comp.Name);
        } else if ( comp.Name != Trigger.oldMap.get( comp.id).Name ) {
            comps.add( comp);
            compNames.add( comp.Name);
        }
    }
    
    if ( comps.size() == 0 ) {
        System.debug( 'No new components or changed component names to track.');
        return;
    }
    
    // Get the existing Components (1st pass)
    Map<String, ID> srcCompMap = new Map<String, ID>();
    for ( Source_Component__c sc : [select Id, Name from Source_Component__c where Name in :compNames] ) {
        srcCompMap.put( sc.Name, sc.Id);
    }

	// Walk through the updated components to get any new components
	Set<Source_Component__c> newSrcComps = new Set<Source_Component__c>();
	for ( CM_Component__c comp : comps ) {
		if ( !srcCompMap.containsKey( comp.Name)) {
			newSrcComps.add( new Source_Component__c( Name = comp.Name));
		}
	}

	// Add any new source components then reselect into the source component map
	if ( newSrcComps.size() > 0 ) {
		List<Source_Component__c> newSrcList = new List<Source_Component__c>();
		newSrcList.addAll( newSrcComps);
		insert newSrcList;
	    // Get the new Components (2nd pass)
	    for ( Source_Component__c sc : [select Id, Name from Source_Component__c where Id in :newSrcComps] ) {
	        srcCompMap.put( sc.Name, sc.Id);
	    }
	}

	// Now set the Source Component Id for all
	for ( CM_Component__c comp : comps ) {
		comp.Source_Component__c = srcCompMap.get( comp.Name);
	}
}
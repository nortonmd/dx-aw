trigger SprintUpdateDates on CM_Sprint__c (before insert, before update) {
	
	for ( CM_Sprint__c sprint : Trigger.new ) {
		if ( sprint.Auto_Set_Dates__c == true) {
			sprint.Signoff_Required_Date_Time__c = sprint.Release_Date__c.addDays( -9);
			sprint.Signoff_Required_Date_Time__c = sprint.Signoff_Required_Date_Time__c.addHours( 21);
			sprint.UAT_Signoff_Date__c = sprint.Release_Date__c.addDays( -14);
			sprint.UAT_Deploy_Date__c = sprint.UAT_Signoff_Date__c.addDays( -7);
			sprint.QA_Signoff_Date__c = sprint.UAT_Deploy_Date__c;
			sprint.QA_Deploy_Date__c = sprint.QA_Signoff_Date__c.addDays( -7);
			sprint.Sprint_Demo_Date__c = sprint.QA_Deploy_Date__c.addDays( -1);
			sprint.Sprint_Planning_Date__c = sprint.Sprint_Demo_Date__c.addDays( -23);
			sprint.Auto_Set_Dates__c = false;
		}
	}

}
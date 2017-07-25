trigger CapacityDuplicateCheck on CM_Capacity__c ( before insert, before update) {

    System.debug( 'CapacityDuplicateCheck preventing duplicates');
    CapacityHelper.preventDuplicates( Trigger.new);
}
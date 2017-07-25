public abstract class CapacityHelper {

    // This method acts as a uniqueness checker for the Capacity sObject based on the resource (user) id and sprint
    public static void preventDuplicates( CM_Capacity__c[] capacities) {

        // Define a map for unique Capacities
        Map<String, CM_Capacity__c> capacityMap = new Map<String, CM_Capacity__c>();
        
        // Loop through capacities, set the unique key, then build the map of capacities to check
        for ( CM_Capacity__c capacity : capacities ) {
            if ( capacity.Sprint__c != null && capacity.Resource__c != null ) {
                capacity.Unique_Key__c = (String)capacity.Sprint__c + (String)capacity.Resource__c;

                if ( capacityMap.containsKey( capacity.Unique_Key__c) ) {
                    capacity.addError( 'Duplicate Sprint and Resource Id found in batch');
                } else {
                    capacityMap.put( capacity.Unique_Key__c, capacity);
                }
            } else {
                capacity.Resource__c.addError( 'Sprint and Resource values are required to record Capacity');
            }
        }

        // Check the DB for duplicates
        if ( !capacityMap.isEmpty()) {
            // Create a list of capacities that contain the unique keys from the capacity map
            for ( CM_Capacity__c[] capacitiesCheck : [select id, unique_key__c 
                                                      from CM_Capacity__c
                                                     where unique_key__c in :capacityMap.keySet()]) {
                for ( CM_Capacity__c capacity : capacitiesCheck ) {
                    String currentCapacityId = capacity.id;
                    // If there's a duplicate and it's not the current record, add the error
                    if ( capacityMap.containsKey( capacity.unique_key__c) && (currentCapacityId != capacityMap.get( capacity.unique_key__c).id)) {
                        capacityMap.get( capacity.unique_key__c).addError( 'Duplicate Capacity (Sprint + Resource) found!');
                    }
                }
            }
        }
    }



}
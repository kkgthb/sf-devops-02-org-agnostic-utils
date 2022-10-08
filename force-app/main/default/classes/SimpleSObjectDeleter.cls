/* **************************************************************************************
* Public Class: SimpleSObjectDeleter
*
* A riff on a hybrid (SimpleSObjectInserter) of 
* Dan Appleman's TriggerDMLSupport from the Advanced Apex Programming book 
* and his SimpleLeadUpdater from his Pluralsight Play-By-Play with Don Robbins.
* Dan's original:
* https://github.com/danappleman/Triggers-without-frameworks/blob/master/force-app/main/default/classes/simpleLeadUpdater.cls
* Please support Dan by watching his video at 
* https://www.pluralsight.com/courses/play-by-play-adopting-trigger-design-patterns-existing-salesforce-orgs
* 
* 
* (Not sure getting how I really want it for execution-context scope, 
* but first draft.)
* 
* Created by Katie Kodes, April 1, 2021
* Unit Tests: SimpleSObjectDeleter_TEST
*****************************************************************************************/

public class SimpleSObjectDeleter {
    
    private Boolean deletingPendingObjects = FALSE;  // I might have the execution scope wrong on this ... TBD. -9/3/2019, 10:20AM
    
    private Map<Schema.SObjectType, Set<Id>> idsToDelete = 
        new Map<Schema.SObjectType, Set<Id>>();
    //private Boolean hadToAddSObjects = FALSE; // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
    
    //@TestVisible private Boolean didWeHaveToAddSObjects() { return hadToAddSObjects; } // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
    
    public void cacheIdForDeletion(Schema.SObjectType objType, Id recordId) {
        // Fetch, or build if it didn't exist, collection of IDs for this SObjectType
        Set<Id> recordIds = idsToDelete.get(objType);
        if ( recordIds == NULL ) {
            recordIds = new Set<Id>();
            idsToDelete.put(objType, recordIds);
        }
        // If record ID is not in collection to delete, add it
        recordIds.add(recordId);
    }

    public void cacheIdsForDeletion(Schema.SObjectType objType, Set<Id> recordIdsToCache) {
        // Fetch, or build if it didn't exist, collection of IDs for this SObjectType
        Set<Id> recordIds = idsToDelete.get(objType);
        if ( recordIds == NULL ) {
            recordIds = new Set<Id>();
            idsToDelete.put(objType, recordIds);
        }
        // If record IDs are not in collection to delete, add them
        recordIds.addAll(recordIdsToCache);
    }
    
    public Boolean isIdCachedForDeletion(Schema.SObjectType objType, Id recordId) {
        Set<Id> recordIds = idsToDelete.get(objType);
        if ( recordIds == NULL ) {
            return FALSE;
        }
        return recordIds.contains(recordId);
    }

    public Set<Id> getIdsCachedForDeletion(Schema.SObjectType objType) {
        // Fetch, or build if it didn't exist, collection of IDs for this SObjectType
        Set<Id> recordIds = idsToDelete.get(objType);
        if ( recordIds == NULL ) {
            recordIds = new Set<Id>();
            idsToDelete.put(objType, recordIds);
        }
        // Return a copy (not the original, so it's safe from edits)
        return new Set<Id>(recordIds);
    }

    public void deleteAllIdsAndClearTypeCache(Schema.SObjectType objType) {
        // Note that this method doesn't actually TELL you, nor does it clear out the "cache,"
        // if it decides it's not a good idea to do DML due to deletingPendingObjects being TRUE.
        // Also, it clears out the cache whether the DML is successful or not.
        // [[[TO DO:]]]  Fix that.
        if ( !deletingPendingObjects ) {
            Set<Id> recordIds = idsToDelete.get(objType);
            if ( recordIds != NULL && recordIds.size() > 0 ) {
                List<SObject> recordsToActuallyDelete = new List<SObject>();
                for ( Id recordId : recordIds ) {
                    SObject tempSObj = objType.newSObject();
                    tempSObj.Id = recordId;
                    recordsToActuallyDelete.add(tempSObj); // Set aside value for DML
                }
                idsToDelete.put(objType, new Set<Id>()); // Clear out cache
                deletingPendingObjects = TRUE;
                DELETE recordsToActuallyDelete; // Do DML
                deletingPendingObjects = FALSE;
            }
        }
    }
    
    public void deleteCertainIdsAndClearThemFromTypeCache(Schema.SObjectType objType, Set<Id> recordIdsToDeleteNow) {
        if ( !deletingPendingObjects && !recordIdsToDeleteNow.isEmpty() ) {
            Set<Id> recordIds = idsToDelete.get(objType);
            if ( recordIds != NULL && recordIds.size() > 0 ) {
                List<SObject> recordsToActuallyDelete = new List<SObject>();
                for ( Id recordId : recordIdsToDeleteNow ) {
                    if ( recordIds.contains(recordId) ) {
                        SObject tempSObj = objType.newSObject();
                        tempSObj.Id = recordId;
                        recordsToActuallyDelete.add(tempSObj); // Set aside value for DML
                        recordIds.remove(recordId); // Clear ID from cache (subsequent attempts to use this helper class to DML this ID will be ignored unless the ID is "re-cached")
                    }
                }
                if ( !recordsToActuallyDelete.isEmpty() ) {
                    deletingPendingObjects = TRUE;
                    DELETE recordsToActuallyDelete; // Do DML
                    deletingPendingObjects = FALSE;
                }
            }
        }
        return;
    }
}
/* **************************************************************************************
* Public Class: SimpleSObjectUpdater
*
* A hybrid of Dan Appleman's TriggerDMLSupport from the Advanced Apex Programming book 
* and his SimpleLeadUpdater from his Pluralsight Play-By-Play with Don Robbins.
* Dan's original:
* https://github.com/danappleman/Triggers-without-frameworks/blob/master/force-app/main/default/classes/simpleLeadUpdater.cls
* Please support Dan by watching his video at 
* https://www.pluralsight.com/courses/play-by-play-adopting-trigger-design-patterns-existing-salesforce-orgs
* 
* (Not sure getting how I really want it for execution-context scope, 
* but first draft.)
* 
* Created by Katie Kodes, September 25, 2019
* Unit Tests: SimpleSObjectUpdater_TEST
*****************************************************************************************/

public class SimpleSObjectUpdater {
    
    private Boolean updatingPendingObjects = FALSE;  // I might have the execution scope wrong on this ... TBD. -9/25/2019, 12:00AM
    
    private Map<Schema.SObjectType, Map<Id, SObject>> objectsToPotentiallyUpdate = new Map<Schema.SObjectType, Map<Id, SObject>>();
    private Map<Schema.SObjectType, Set<Id>> objectsToActuallyUpdate = new Map<Schema.SObjectType, Set<Id>>();
    //private Boolean hadToAddSObjects = FALSE; // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
    
    //@TestVisible private Boolean didWeHaveToAddSObjects() { return hadToAddSObjects; } // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
    
    // Return a single updatable SObject record to use in after-triggers
    public SObject getCachedObj(Schema.SObjectType objType, Id recordId) {
        Map<Id, SObject> objMap = makeMapForSObjType(objType);
        // Fetch, or build if it didn't exist, SObject to return
        SObject targetCachedObj = objMap.get(recordId);
        if ( targetCachedObj == NULL ) {
            targetCachedObj = objType.newSObject(recordId);
            objMap.put(recordId, targetCachedObj);
        }
        return targetCachedObj;
    }
    
    public Map<Id, SObject> getCachedObjs(Schema.SObjectType objType, Set<Id> recordIds) {
        Map<Id, SObject> objMap = makeMapForSObjType(objType);
        // Fetch, or build if it didn't exist, Map<Id, SObject> to return
        Map<Id, SObject> targetCachedObjs = new Map<Id, SObject>();
        for ( Id recordId : recordIds ) {
            SObject theObj = objMap.get(recordId);
            if ( theObj == NULL ) {
                //hadToAddSObjects = TRUE; // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
                theObj = objType.newSObject(recordId);
                objMap.put(recordId, theObj);
            }
            targetCachedObjs.put(recordId, theObj);
        }
        return targetCachedObjs;
    }
    
    public void declareIdUpdatable(Schema.SObjectType objType, Id recordId) {
        buildActualMapForSObjType(objType);
        objectsToActuallyUpdate.get(objType).add(recordId);
    }
    
    public void declareIdsUpdatable(Schema.SObjectType objType, Set<Id> recordIds) {
        buildActualMapForSObjType(objType);
        objectsToActuallyUpdate.get(objType).addAll(recordIds);
    }

    public void updateAllObjectsAndClearTypeCache(Schema.SObjectType objType) {
        // Note that this method doesn't actually TELL you, nor does it clear out the "cache,"
        // if it decides it's not a good idea to do DML due to updatingPendingObjects being TRUE.
        // Also, it clears out the cache whether the DML is successful or not.
        // [[[TO DO:]]]  Fix that.
        if ( !updatingPendingObjects ) {
            Map<Id, SObject> objMap = objectsToPotentiallyUpdate.get(objType);
            if ( objMap != NULL && objMap.size() > 0 ) {
                List<SObject> updatingList = objMap.values(); // Set aside values for DML
                objectsToPotentiallyUpdate.put(objType, new Map<Id, SObject>()); // Clear out cache
                removeIdsFromDeclaredUpdateable(objType, new Map<Id, SObject>(updatingList).keySet()); // Clear out "declared" cache
                updatingPendingObjects = TRUE;
                UPDATE updatingList; // Do DML
                updatingPendingObjects = FALSE;
            }
        }
        return;
    }
    
    public void updateCertainObjectsAndClearThemFromTypeCache(Schema.SObjectType objType, Set<Id> recordIds) {
        if ( !updatingPendingObjects && !recordIds.isEmpty() ) {
            Map<Id, SObject> objMap = objectsToPotentiallyUpdate.get(objType);
            if ( objMap != NULL && objMap.size() > 0 ) {
                Set<Id> idsThatWillBeUpdated = new Set<Id>();
                List<SObject> updatingList = new List<SObject>();
                for ( Id recordId : recordIds ) {
                    if ( objMap.containsKey(recordId) ) {
                        updatingList.add(objMap.get(recordId)); // Set aside value for DML
                        objMap.remove(recordId); // Clear Id from cache (subsequent attempts to use this method to DML this Id will be ignored 
                        idsThatWillBeUpdated.add(recordId);
                        // unless the Id is "gotten" and has field values set again from scratch, which will create yet ANOTHER record)
                    }
                }
                removeIdsFromDeclaredUpdateable(objType, idsThatWillBeUpdated); // Clear applicable Ids from "actually remove" cache (attempts to use the "Pre-Declared" method to DML these IDs will be ignored unless they are manually re-"declared")
                if ( !updatingList.isEmpty() ) {
                    updatingPendingObjects = TRUE;
                    UPDATE updatingList; // Do DML
                    updatingPendingObjects = FALSE;
                }
            }
        }
        return;
    }
    
    // This, alongside the "declare...()" methods, can help avoid unnecessary DML calls when you instantiated updatable SObjects but, 
    // in the end, didn't actually make any changes to them.
    public void updatePreDeclaredObjectsAndClearThemFromTypeCache(Schema.SObjectType objType) {
        if ( !updatingPendingObjects && objectsToActuallyUpdate != NULL && objectsToActuallyUpdate.containsKey(objType) ) {
            Set<Id> recordIds = objectsToActuallyUpdate.get(objType);
            if ( !recordIds.isEmpty() ) {
                updateCertainObjectsAndClearThemFromTypeCache(objType, recordIds); 
            }
        }
    }
    
    // ------- Helper methods -------
    
    private Map<Id, SObject> makeMapForSObjType(Schema.SObjectType objType) {
        Map<Id, SObject> objMap = objectsToPotentiallyUpdate.get(objType);
        if ( objMap == NULL ) {
            objMap = new Map<Id, SObject>();
            objectsToPotentiallyUpdate.put(objType, objMap);
        }
        return objMap;
    }
    
    private void buildActualMapForSObjType(Schema.SObjectType objType) {
        Set<Id> objIds = objectsToActuallyUpdate.get(objType);
        if ( objIds == NULL ) {
            objIds = new Set<Id>();
            objectsToActuallyUpdate.put(objType, objIds);
        }
    }
    
    private void removeIdsFromDeclaredUpdateable(Schema.SObjectType objType, Set<Id> recordIds) {
        if ( 
            recordIds != NULL && !recordIds.isEmpty() && 
            objectsToActuallyUpdate != NULL && objectsToActuallyUpdate.containsKey(objType)
        ) {
            Set<Id> removeFrom = objectsToActuallyUpdate.get(objType);
            if ( !removeFrom.isEmpty() ) {
                removeFrom.removeAll(recordIds);
            }
        }
    }
    
    
}
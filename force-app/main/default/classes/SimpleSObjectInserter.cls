/* **************************************************************************************
* Public Class: SimpleSObjectInserter
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
* Created by Katie Kodes, September 3, 2019
* Unit Tests: SimpleSObjectInserter_TEST
*****************************************************************************************/

public class SimpleSObjectInserter {
    
    private Boolean insertingPendingObjects = FALSE;  // I might have the execution scope wrong on this ... TBD. -9/3/2019, 10:20AM
    
    private Map<Schema.SObjectType, Map<String, SObject>> objectsToInsert = 
        new Map<Schema.SObjectType, Map<String, SObject>>();
    //private Boolean hadToAddSObjects = FALSE; // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
    
    //@TestVisible private Boolean didWeHaveToAddSObjects() { return hadToAddSObjects; } // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
    
    // Return a single updatable SObject record to use in after-triggers
    public SObject getCachedObj(Schema.SObjectType objType, String uniqueRecordKey) {
        // Fetch, or build if it didn't exist, collection of records for this SObjectType
        Map<String, SObject> objMap = objectsToInsert.get(objType);
        if ( objMap == NULL ) {
            objMap = new Map<String, SObject>();
            objectsToInsert.put(objType, objMap);
        }
        // Fetch, or build if it didn't exist, SObject to return
        SObject targetCachedObj = objMap.get(uniqueRecordKey);
        if ( targetCachedObj == NULL ) {
            targetCachedObj = objType.newSObject();
            objMap.put(uniqueRecordKey, targetCachedObj);
        }
        return targetCachedObj;
    }
    
    public Map<String, SObject> getCachedObjs(Schema.SObjectType objType, Set<String> uniqueRecordKeys) {
        // Fetch, or build if it didn't exist, collection of records for this SObjectType
        Map<String, SObject> objMap = objectsToInsert.get(objType);
        if ( objMap == NULL ) {
            objMap = new Map<String, SObject>();
            objectsToInsert.put(objType, objMap);
        }
        // Fetch, or build if it didn't exist, Map<String, SObject> to return
        Map<String, SObject> targetCachedObjs = new Map<String, SObject>();
        for ( String uniqueRecordKey : uniqueRecordKeys ) {
            SObject theObj = objMap.get(uniqueRecordKey);
            if ( theObj == NULL ) {
                //hadToAddSObjects = TRUE; // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
                theObj = objType.newSObject();
                objMap.put(uniqueRecordKey, theObj);
            }
            targetCachedObjs.put(uniqueRecordKey, theObj);
        }
        return targetCachedObjs;
    }
    
    public void insertAllObjectsAndClearTypeCache(Schema.SObjectType objType) {
        // Note that this method doesn't actually TELL you, nor does it clear out the "cache,"
        // if it decides it's not a good idea to do DML due to insertingPendingObjects being TRUE.
        // Also, it clears out the cache whether the DML is successful or not.
        // [[[TO DO:]]]  Fix that.
        //Map<String, Id> oldKeysToNewIDs = new Map<String, Id>();
        if ( !insertingPendingObjects ) {
            Map<String, SObject> objMap = objectsToInsert.get(objType);
            if ( objMap != NULL && objMap.size() > 0 ) {
                List<SObject> insertingList = objMap.values(); // Set aside values for DML
                objectsToInsert.put(objType, new Map<String, SObject>()); // Clear out cache
                insertingPendingObjects = TRUE;
                INSERT insertingList; // Do DML
                insertingPendingObjects = FALSE;
            }
        }
        //return oldKeysToNewIDs;
        return;
    }
    
    public void insertCertainObjectsAndClearThemFromTypeCache(Schema.SObjectType objType, Set<String> uniqueRecordKeys) {
        if ( !insertingPendingObjects && !uniqueRecordKeys.isEmpty() ) {
            Map<String, SObject> objMap = objectsToInsert.get(objType);
            if ( objMap != NULL && objMap.size() > 0 ) {
                List<SObject> insertingList = new List<SObject>();
                for ( String key : uniqueRecordKeys ) {
                    if ( objMap.containsKey(key) ) {
                        insertingList.add(objMap.get(key)); // Set aside value for DML
                        objMap.remove(key); // Clear key from cache (subsequent attempts to use this helper class to DML this key will be ignored 
                        // unless the key is "gotten" and has field values set again from scratch, which will create yet ANOTHER record)
                    }
                }
                if ( !insertingList.isEmpty() ) {
                    insertingPendingObjects = TRUE;
                    INSERT insertingList; // Do DML
                    insertingPendingObjects = FALSE;
                }
            }
        }
        return;
    }
}
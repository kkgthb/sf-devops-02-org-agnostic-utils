/* **************************************************************************************
* Public Class: SimpleSObjectUpdater_TEST
* Unit test for the "SimpleSObjectUpdater" class.
* 
* Created by Katie Kodes, September 3, 2019
*****************************************************************************************/

@isTest
public class SimpleSObjectUpdater_TEST {
    
    private static Schema.SObjectType cType = Contact.SObjectType;
    private static Map<Integer, Contact> csBefore = new Map<Integer, Contact>();
    
    private static Contact getCb4(Integer i) { return csBefore.get(i); }
    
    private static void insertBaselineContacts() {
        csBefore.put(1, new Contact(LastName='C01'));
        csBefore.put(2, new Contact(LastName='C02'));
        csBefore.put(3, new Contact(LastName='C03'));
        INSERT csBefore.values();
    }
    
    static testMethod void testGetters() {
        insertBaselineContacts();
        Id c1Id = getCb4(1).Id;
        Id c2Id = getCb4(2).Id;
        Set<Id> allIds = new Set<Id>{c1Id, c2Id}; {}
        SimpleSObjectUpdater testMe = new SimpleSObjectUpdater();
        System.assertNotEquals(NULL, testMe.getCachedObj(cType, c1Id), 'getCachedObj on c1 did not return a value');
        System.assertEquals(cType, testMe.getCachedObj(cType, c1Id).getSObjectType(), 'getCachedObj on c1 was not a Contact');
        System.assertNotEquals(NULL, testMe.getCachedObj(cType, c2Id), 'getCachedObj on c2 did not return a value');
        System.assertEquals(cType, testMe.getCachedObj(cType, c2Id).getSObjectType(), 'getCachedObj on c2 was not a Contact');
        //testMe.getCachedObjs(cType, allIds); // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
        //System.assertEquals(FALSE, testMe.didWeHaveToAddSObjects()); // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
        Id c3Id = getCb4(3).Id;
        allIds.add(c3Id);
        Map<Id, SObject> returnedObjs2 = testMe.getCachedObjs(cType, allIds);
        System.assertEquals(3, returnedObjs2.size());
        //System.assertEquals(TRUE, testMe.didWeHaveToAddSObjects()); // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
        Contact c1 = (Contact)returnedObjs2.get(c1Id);
        c1.LastName='abcca';
        System.assertEquals('abcca', ((Contact)testMe.getCachedObj(cType, c1Id)).LastName, 'Field value change to local c1 did not propagate to helper class');
    }
    
    static testMethod void testUpdaterOfAll() {
        insertBaselineContacts();
        Id c1Id = getCb4(1).Id;
        Id c2Id = getCb4(2).Id;
        Set<Id> allIds = new Set<Id>{c1Id, c2Id}; {}
        SimpleSObjectUpdater testMe = new SimpleSObjectUpdater();
        Map<Id, SObject> returnedObjs = testMe.getCachedObjs(cType, allIds);
        Contact c1 = (Contact)returnedObjs.get(c1Id);
        Contact c2 = (Contact)returnedObjs.get(c2Id);
        c1.LastName = 'Xyzzy';
        c2.LastName = 'Zyzzx';
        Test.startTest();
        testMe.updateAllObjectsAndClearTypeCache(cType);
        Test.stopTest();
        Contact c1After = [SELECT Id, LastName FROM Contact WHERE Id = :c1Id][0];
        Contact c2After = [SELECT Id, LastName FROM Contact WHERE Id = :c2Id][0];
        System.assertEquals('Xyzzy', c1After.LastName, 'c1 did not update to Xyzzy');
        System.assertEquals('Zyzzx', c2After.LastName, 'c2 did not update to Zyzzx');
        System.assertEquals(NULL, ((Contact)testMe.getCachedObj(cType, c1Id)).LastName, 'c1 getCachedObj does not return a fresh object but should');
    }
    
    static testMethod void testUpdaterOfSome() {
        insertBaselineContacts();
        Id c1Id = getCb4(1).Id;
        Id c2Id = getCb4(2).Id;
        Id c3Id = getCb4(3).Id;
        Set<Id> allIds = new Set<Id>{c1Id, c2Id, c3Id}; {}
        Set<Id> someIds = new Set<Id>{c1Id, c3Id}; {}
        SimpleSObjectUpdater testMe = new SimpleSObjectUpdater();
        Map<Id, SObject> returnedObjs = testMe.getCachedObjs(cType, allIds);
        Contact c1 = (Contact)returnedObjs.get(c1Id);
        Contact c2 = (Contact)returnedObjs.get(c2Id);
        Contact c3 = (Contact)returnedObjs.get(c3Id);
        c1.LastName = 'Xyzzy';
        c2.LastName = 'Zyzzx';
        c3.LastName = 'Abcca';
        System.assertEquals('Xyzzy', ((Contact)testMe.getCachedObj(cType, c1Id)).LastName, 'c1 getCachedObj does not return the object still in the cache from before');
        System.assertEquals('Zyzzx', ((Contact)testMe.getCachedObj(cType, c2Id)).LastName, 'c2 getCachedObj does not return the object still in the cache from before');
        Test.startTest();
        testMe.updateCertainObjectsAndClearThemFromTypeCache(cType, someIds);
        Test.stopTest();
        Contact c1After = [SELECT Id, LastName FROM Contact WHERE Id = :c1Id][0];
        Contact c2After = [SELECT Id, LastName FROM Contact WHERE Id = :c2Id][0];
        Contact c3After = [SELECT Id, LastName FROM Contact WHERE Id = :c3Id][0];
        System.assertEquals('Xyzzy', c1After.LastName, 'c1 did not update to Xyzzy');
        System.assertEquals('C02', c2After.LastName, 'c2 updated to Zyzzx but should not have');
        System.assertEquals('Abcca', c3After.LastName, 'c3 did not update to Abcca');
        System.assertEquals(NULL, ((Contact)testMe.getCachedObj(cType, c1Id)).LastName, 'c1 getCachedObj does not return a fresh object but should');
        System.assertEquals('Zyzzx', ((Contact)testMe.getCachedObj(cType, c2Id)).LastName, 'c2 getCachedObj does not return the object still in the cache from before but should');
    }
    
    static testMethod void testUpdaterOfDeclared() {
        insertBaselineContacts();
        Id c1Id = getCb4(1).Id;
        Id c2Id = getCb4(2).Id;
        Id c3Id = getCb4(3).Id;
        Set<Id> allIds = new Set<Id>{c1Id, c2Id, c3Id}; {}
        Set<Id> someIds = new Set<Id>{c1Id, c3Id}; {}
        SimpleSObjectUpdater testMe = new SimpleSObjectUpdater();
        Map<Id, SObject> returnedObjs = testMe.getCachedObjs(cType, allIds);
        Contact c1 = (Contact)returnedObjs.get(c1Id);
        Contact c2 = (Contact)returnedObjs.get(c2Id);
        Contact c3 = (Contact)returnedObjs.get(c3Id);
        c1.LastName = 'Xyzzy';
        c2.LastName = 'Zyzzx';
        c3.LastName = 'Abcca';
        System.assertEquals('Xyzzy', ((Contact)testMe.getCachedObj(cType, c1Id)).LastName, 'c1 getCachedObj does not return the object still in the cache from before');
        System.assertEquals('Zyzzx', ((Contact)testMe.getCachedObj(cType, c2Id)).LastName, 'c2 getCachedObj does not return the object still in the cache from before');
        testMe.updatePreDeclaredObjectsAndClearThemFromTypeCache(cType); // When we run this without declaring any objects, effectively, nothing happens.
        Contact c1Middle = [SELECT Id, LastName FROM Contact WHERE Id = :c1Id][0];
        System.assertEquals('C01', c1Middle.LastName, 'c1 is not original value but should be');
        Test.startTest();
        testMe.declareIdUpdatable(cType, c1Id);
        testMe.declareIdsUpdatable(cType, someIds); // Note that this is redundant to the previous line -- previous line is kind of just for code coverage
        testMe.updatePreDeclaredObjectsAndClearThemFromTypeCache(cType); // NOW something should happen.
        Test.stopTest();
        Contact c1After = [SELECT Id, LastName FROM Contact WHERE Id = :c1Id][0];
        Contact c2After = [SELECT Id, LastName FROM Contact WHERE Id = :c2Id][0];
        Contact c3After = [SELECT Id, LastName FROM Contact WHERE Id = :c3Id][0];
        System.assertEquals('Xyzzy', c1After.LastName, 'c1 did not update to Xyzzy');
        System.assertEquals('C02', c2After.LastName, 'c2 updated to Zyzzx but should not have');
        System.assertEquals('Abcca', c3After.LastName, 'c3 did not update to Abcca');
        System.assertEquals(NULL, ((Contact)testMe.getCachedObj(cType, c1Id)).LastName, 'c1 getCachedObj does not return a fresh object but should');
        System.assertEquals('Zyzzx', ((Contact)testMe.getCachedObj(cType, c2Id)).LastName, 'c2 getCachedObj does not return the object still in the cache from before but should');
    }
}
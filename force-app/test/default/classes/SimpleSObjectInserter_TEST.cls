/* **************************************************************************************
* Public Class: SimpleSObjectInserter_TEST
* Unit test for the "SimpleSObjectInserter" class.
* 
* Created by Katie Kodes, September 3, 2019
*****************************************************************************************/

@isTest
public class SimpleSObjectInserter_TEST {
    
    private static Schema.SObjectType cType = Contact.SObjectType;
    
    static testMethod void testGetters() {
        String c1Key = 'ContactUniqueProperty1';
        String c2Key = 'ContactUniqueProperty2';
        Set<String> allKeys = new Set<String>{c1Key, c2Key}; {}
        SimpleSObjectInserter testMe = new SimpleSObjectInserter();
        System.assertNotEquals(NULL, testMe.getCachedObj(cType, c1Key), 'getCachedObj on c1 did not return a value');
        System.assertEquals(cType, testMe.getCachedObj(cType, c1Key).getSObjectType(), 'getCachedObj on c1 was not a Contact');
        System.assertNotEquals(NULL, testMe.getCachedObj(cType, c2Key), 'getCachedObj on c2 did not return a value');
        System.assertEquals(cType, testMe.getCachedObj(cType, c2Key).getSObjectType(), 'getCachedObj on c2 was not a Contact');
        //testMe.getCachedObjs(cType, allKeys); // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
        //System.assertEquals(FALSE, testMe.didWeHaveToAddSObjects()); // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
        String c3Key = 'ContactUniqueProperty3';
        allKeys.add(c3Key);
        Map<String, SObject> returnedObjs2 = testMe.getCachedObjs(cType, allKeys);
        System.assertEquals(3, returnedObjs2.size());
        //System.assertEquals(TRUE, testMe.didWeHaveToAddSObjects()); // NON-PRODUCTION; FOR DESIGN DUMMY-CHECKING
        Contact c1 = (Contact)returnedObjs2.get(c1Key);
        c1.LastName='abcca';
        System.assertEquals('abcca', ((Contact)testMe.getCachedObj(cType, c1Key)).LastName, 'Field value change to local c1 did not propagate to helper class');
    }
    
    static testMethod void testInserterOfAll() {
        String c1Key = 'ContactUniqueProperty1';
        String c2Key = 'ContactUniqueProperty2';
        Set<String> allKeys = new Set<String>{c1Key, c2Key}; {}
        SimpleSObjectInserter testMe = new SimpleSObjectInserter();
        Map<String, SObject> returnedObjs = testMe.getCachedObjs(cType, allKeys);
        Contact c1 = (Contact)returnedObjs.get(c1Key);
        Contact c2 = (Contact)returnedObjs.get(c2Key);
        c1.LastName = 'Xyzzy';
        c2.LastName = 'ZYZZX';
        Test.startTest();
        testMe.insertAllObjectsAndClearTypeCache(cType);
        Test.stopTest();
        List<Contact> csAfter1 = [SELECT Id, LastName FROM Contact WHERE LastName='Xyzzy'];
        List<Contact> csAfter2 = [SELECT Id, LastName FROM Contact WHERE LastName='ZYZZX'];
        System.assertEquals(1, csAfter1.size(), 'c1 Xyzzy did not insert or too many inserted');
        System.assertEquals(1, csAfter2.size(), 'c2 ZYZZX did not insert or too many inserted');
        System.assertEquals(NULL, ((Contact)testMe.getCachedObj(cType, c1Key)).LastName, 'c1 getCachedObj does not return a fresh object');
    }
    
    static testMethod void testInserterOfSome() {
        String c1Key = 'ContactUniqueProperty1';
        String c2Key = 'ContactUniqueProperty2';
        String c3Key = 'ContactUniqueProperty3';
        Set<String> allKeys = new Set<String>{c1Key, c2Key, c3Key}; {}
        Set<String> someKeys = new Set<String>{c1Key, c3Key}; {}
        SimpleSObjectInserter testMe = new SimpleSObjectInserter();
        Map<String, SObject> returnedObjs = testMe.getCachedObjs(cType, allKeys);
        Contact c1 = (Contact)returnedObjs.get(c1Key);
        Contact c2 = (Contact)returnedObjs.get(c2Key);
        Contact c3 = (Contact)returnedObjs.get(c3Key);
        c1.LastName = 'Xyzzy';
        c2.LastName = 'ZYZZX';
        c3.LastName = 'abcca';
        System.assertEquals('Xyzzy', ((Contact)testMe.getCachedObj(cType, c1Key)).LastName, 'c1 getCachedObj does not return the object still in the cache from before');
        System.assertEquals('ZYZZX', ((Contact)testMe.getCachedObj(cType, c2Key)).LastName, 'c2 getCachedObj does not return the object still in the cache from before');
        Test.startTest();
        testMe.insertCertainObjectsAndClearThemFromTypeCache(cType, someKeys);
        Test.stopTest();
        List<Contact> csAfter1 = [SELECT Id, LastName FROM Contact WHERE LastName='Xyzzy'];
        List<Contact> csAfter2 = [SELECT Id, LastName FROM Contact WHERE LastName='ZYZZX'];
        List<Contact> csAfter3 = [SELECT Id, LastName FROM Contact WHERE LastName='abcca'];
        System.assertEquals(1, csAfter1.size(), 'c1 Xyzzy did not insert or too many inserted');
        System.assertEquals(0, csAfter2.size(), 'c2 ZYZZX inserted but should not have');
        System.assertEquals(1, csAfter3.size(), 'c3 abcca did not insert or too many inserted');
        System.assertEquals(NULL, ((Contact)testMe.getCachedObj(cType, c1Key)).LastName, 'c1 getCachedObj does not return a fresh object');
        System.assertEquals('ZYZZX', ((Contact)testMe.getCachedObj(cType, c2Key)).LastName, 'c2 getCachedObj does not return the object still in the cache from before');
    }
}
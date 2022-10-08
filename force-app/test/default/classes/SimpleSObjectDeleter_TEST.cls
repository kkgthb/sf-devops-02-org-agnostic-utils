/* **************************************************************************************
* Public Class: SimpleSObjectDeleter_TEST
* Unit test for the "SimpleSObjectDeleter" class.
* 
* Created by Katie Kodes, April 1, 2021
*****************************************************************************************/

@isTest
public class SimpleSObjectDeleter_TEST {
    
    private static Schema.SObjectType cType = Contact.SObjectType;
    private static Map<Integer, Contact> csBefore = new Map<Integer, Contact>();
    
    private static Contact getCb4(Integer i) { return csBefore.get(i); }
    
    private static void insertBaselineContactsAndValidatePresence() {
        csBefore.put(1, new Contact(LastName='C01'));
        csBefore.put(2, new Contact(LastName='C02'));
        csBefore.put(3, new Contact(LastName='C03'));
        INSERT csBefore.values();
        System.assertEquals(3, [SELECT Id FROM Contact].size(), 'Contacts not properly inserted');
    }
    
    static testMethod void testGetters() {
        insertBaselineContactsAndValidatePresence();
        SimpleSObjectDeleter testMe = new SimpleSObjectDeleter();
        System.assertEquals(0, testMe.getIdsCachedForDeletion(cType).size(), 'Cache size not 0 before starting getter test');
        testMe.cacheIdsForDeletion(cType, new Set<Id>{getCb4(1).Id, getCb4(2).Id});
        System.assertEquals(2, testMe.getIdsCachedForDeletion(cType).size(), 'Cache size not 2');
        Id cId3 = getCb4(3).Id;
        System.assertEquals(FALSE, testMe.isIdCachedForDeletion(cType, cId3), 'Id 3 cached for deletion but should not be');
        testMe.cacheIdForDeletion(cType, cId3);
        System.assertEquals(TRUE, testMe.isIdCachedForDeletion(cType, cId3), 'Id 3 not cached for deletion but should be');
        System.assertEquals(3, testMe.getIdsCachedForDeletion(cType).size(), 'Cache size not 3');
    }
    
    static testMethod void testDeleterOfAll() {
        insertBaselineContactsAndValidatePresence();
        SimpleSObjectDeleter testMe = new SimpleSObjectDeleter();
        Set<Id> idsToDelete = new Set<Id>{getCb4(1).Id, getCb4(2).Id}; {}
        testMe.cacheIdsForDeletion(cType, idsToDelete);
        Test.startTest();
        testMe.deleteAllIdsAndClearTypeCache(cType);
        Test.stopTest();
        System.assertEquals(0, [SELECT Id FROM Contact WHERE Id IN :idsToDelete].size(), 'Contacts not properly deleted');
        System.assertEquals(1, [SELECT Id FROM Contact WHERE Id = :getCb4(3).Id].size(), 'Contact 3 somehow deleted');
    }
    
    static testMethod void testDeleterOfSome() {
        insertBaselineContactsAndValidatePresence();
        Id c1Id = getCb4(1).Id;
        Id c2Id = getCb4(2).Id;
        Id c3Id = getCb4(3).Id;
        Set<Id> allIds = new Set<Id>{c1Id, c2Id, c3Id}; {}
        Set<Id> someIds = new Set<Id>{c1Id, c3Id}; {}
        SimpleSObjectDeleter testMe = new SimpleSObjectDeleter();
        testMe.cacheIdsForDeletion(cType, someIds);
        Test.startTest();
        testMe.deleteCertainIdsAndClearThemFromTypeCache(cType, someIds);
        Test.stopTest();
        System.assertEquals(0, [SELECT Id FROM Contact WHERE Id IN :someIds].size(), 'Contacts not properly deleted');
        System.assertEquals((allIds.size() - someIds.size()), [SELECT Id FROM Contact WHERE Id IN :allIds].size(), 'Contact 3 somehow deleted');
    }
    
}
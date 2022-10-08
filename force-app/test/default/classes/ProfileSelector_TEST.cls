/* **************************************************************************************
* Public Class: ProfileSelector_TEST
* Unit test for the "ProfileSelector" class.
* 
* Created by Katie Kodes, September 6, 2022
*****************************************************************************************/

@isTest
public class ProfileSelector_TEST {
    private static Profile aProfile = [SELECT Id, Name FROM Profile LIMIT 1];
    private static Map<Id, Profile> profilesAfter;
    
    public static testMethod void test() {
        profilesAfter = ProfileSelector.getAllProfilesById();
        System.assertNotEquals(0, profilesAfter.size());
        // Validate that there's data as expected in the "all profiles by ID" function
        System.assertEquals(aProfile.Name, profilesAfter.get(aProfile.Id).Name);
        // Validate that there's data as expected in the "single profile by ID" function
        System.assertEquals(aProfile.Name, ProfileSelector.getProfileById(aProfile.Id).Name);
        // Validate that there's a key as expected in the "all profiles by name" function
        System.assert(ProfileSelector.getAllProfilesByName().containsKey(aProfile.Name));
        // Validate that there's data as expected in the "single profile by name" function
        System.assertEquals(aProfile.Id, ProfileSelector.getProfileByName(aProfile.Name).Id);
    }
    
}
/* **************************************************************************************
* Public Class: ProfileSelector
* 
* Created by Katie Kodes, September 6, 2022
* Unit Tests: ProfileSelector
*****************************************************************************************/

public class ProfileSelector {

    private static Map<Id, Profile> profilesById;
    private static Boolean soqlWasEmpty = FALSE;
    private static Map<String, Profile> profilesByName;

    // ------- Public methods -------
    
    public static Map<Id, Profile> getAllProfilesById() {
        if ( profilesById == NULL ) { 
            profilesById = new Map<Id, Profile>();
            queryProfilesById();
        } else if ( profilesById.isEmpty() && Test.isRunningTest() ) {
            queryProfilesById();
        }
        return profilesById;
    }

    public static Map<String, Profile> getAllProfilesByName() {
        if ( profilesByName == NULL ) {
            profilesByName = new Map<String, Profile>();
        }
        if ( profilesByName.isEmpty() ) {
            getAllProfilesById();
            for ( Profile profile : profilesById.values() ) { 
                if ( profile.Name == NULL ) { continue; }
                profilesByName.put(profile.Name, profile);
            }
        }
        return profilesByName;
    }

    public static Profile getProfileById(Id profileId) {
        if ( profilesById == NULL || profilesById.isEmpty() ) {
            getAllProfilesById();
        }
        return profilesById.get(profileId);
    }

    public static Profile getProfileByName(String profileName) {
        if ( profilesByName == NULL || profilesByName.isEmpty() ) {
            getAllprofilesByName();
        }
        return profilesByName.get(profileName);
    }

    // ------- Private "helper" methods -------
    
    private static void queryProfilesById() {
        profilesById = new Map<Id, Profile>(
            [
                SELECT
                Id
                , Name
                FROM Profile
            ]
        );
        // Profile is a validation table -- it should always have data -- someone probably
        // ran this too soon in an ISTest context and could use a chance to run it again.
        if ( profilesById.isEmpty() && Test.isRunningTest() ) { soqlWasEmpty = TRUE; } // Flip switch on if necessary
        if ( soqlWasEmpty && Test.isRunningTest() && !profilesById.isEmpty() ) { soqlWasEmpty = FALSE; } // Flip switch back off if now all okay
    }

}

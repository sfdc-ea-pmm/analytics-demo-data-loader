public with sharing class ProfileUtils {
	
	public static List<Profile> getProfiles(){
		return [SELECT Id,Name FROM Profile WHERE UserType = 'Standard'];
	}

	public static List<Profile> getProfilesByName(List<String> profileNames){
		return [SELECT Id,Name FROM Profile WHERE UserType = 'Standard' AND Name IN :profileNames];
	}

	public static Set<ID> getProfileUsersIds(Id profileId) {

	    // get all of the ids for the users in this role identified by roleId
	    Map<Id,User> users = new Map<Id, User>([SELECT Id, Name FROM User WHERE ProfileId = :profileId]);
	      
	    // return the ids as a set so you can do what you want with them
	    return users.keySet();
  	}

  	public static Set<ID> getProfilesSetUsersIds(List<ID> profilesIds) {

	    // get all of the ids for the users in this role identified by roleId
	    Map<Id,User> users = new Map<Id, User>([SELECT Id, Name FROM User WHERE ProfileId != null AND ProfileId IN :profilesIds]);
	      
	    // return the ids as a set so you can do what you want with them
	    return users.keySet();
  	}

}
public with sharing class RoleUtils {
	
	public static List<UserRole> getUserRoles(){
		return [SELECT Id,Name FROM UserRole WHERE PortalType = 'None'];
	}

	public static List<UserRole> getUserRolesByName(List<String> roleNames){
		return [SELECT Id,Name FROM UserRole WHERE PortalType = 'None' AND Name IN :roleNames];
	}

	public static Set<ID> getRoleUsersIds(Id roleId) {

	    // get all of the ids for the users in this role identified by roleId
	    Map<Id,User> users = new Map<Id, User>([SELECT Id, Name FROM User WHERE UserRoleId = :roleId]);
	      
	    // return the ids as a set so you can do what you want with them
	    return users.keySet();
  	}
	
	public static Set<ID> getRoleSubordinateUsersIds(Id roleId, Boolean includePassed) {

	    // get all of the roles underneath the user
	    Set<Id> allSubRoleIds = getAllSubRoleIds(new Set<ID>{roleId});
	    if(includePassed){
	    	allSubRoleIds.add(roleId);
	    }	    
	    
	    // get all of the ids for the users in those roles
	    Map<Id,User> users = new Map<Id, User>([SELECT Id, Name FROM User WHERE UserRoleId IN :allSubRoleIds]);
	      
	    // return the ids as a set so you can do what you want with them
	    return users.keySet();
  	}

	private static Set<ID> getAllSubRoleIds(Set<ID> roleIds) {

    	Set<ID> currentRoleIds = new Set<ID>();

		// get all of the roles underneath the passed roles
		for(UserRole userRole :[SELECT Id FROM UserRole WHERE ParentRoleID != null AND ParentRoleId IN :roleIds]){
			currentRoleIds.add(userRole.Id);
		}

		// go fetch some more rolls!
		if(currentRoleIds.size() > 0)
		  currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));

		return currentRoleIds;
	}

}
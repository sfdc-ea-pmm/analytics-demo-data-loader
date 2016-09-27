@isTest
public class SalesWaveScripted_test {
    @testSetup
    static void setup(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

        User u = new User(
            FirstName = 'Guybrush',
            LastName = 'Threepwood',
            UserName = 'guybrush@example.com',
            Email = 'guybrush@example.com',
            Alias = 'guyb',
            CommunityNickname = 'guybrush',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );

        insert u;
        
        // Retrieve record type
        RecordType recType = [SELECT Id FROM RecordType WHERE Name = 'SalesWaveScripted' AND SobjectType = 'Opportunity'];

        Opportunity op = new Opportunity(
            OwnerId = u.Id,
            Name = 'Test Opp',
            StageName = 'Open', 
            CloseDate = Date.today(),
            RecordTypeId = recType.Id
        );

        insert op;

    }
    
    static testmethod void testUpdateQuotasDataset() {
        Test.startTest();
        User u = [SELECT Id FROM User WHERE UserName = 'guybrush@example.com'];
        SalesWaveQuotas.updateQuotaDataset(new Id[]{ u.Id }, 2016, 1, 2, 10000, 'Sales_Wave_Spring_16', 'plain_quota');
        Test.stopTest();
    }

    static testmethod void testRoleUtils(){
        List<UserRole> roles = RoleUtils.getUserRoles();
        
        if(roles.size() > 0){
            RoleUtils.getRoleUsersIds(roles.get(0).Id);         
            UserRole childRole = [SELECT ParentRoleID FROM UserRole WHERE ParentRoleID != null LIMIT 1];
            RoleUtils.getRoleSubordinateUsersIds(childRole.ParentRoleID, true);
        }
    }

    @isTest
    private static void testProfileUtils() {
        List<Profile> profs = ProfileUtils.getProfiles();
        
        if(profs.size() > 0){
            ProfileUtils.getProfileUsersIds(profs.get(0).Id);
            ProfileUtils.getProfilesSetUsersIds(new Id[]{profs.get(0).Id});
        }
    }

    @isTest
    private static void testOpportunityUsers() {
        SalesWaveQuotas.getOpportunitiesUserIds();
    }
    
    @isTest
    private static void testManageQuotaDatasetsController() {
        Dataflow df = [SELECT Id FROM Dataflow WHERE DeveloperName = 'SalesWaveLuc'];
        ManageQuotaDatasetsController controller = new ManageQuotaDatasetsController();
        controller.salesApp = 'SalesWaveLuc';
        controller.dataflowId = df.Id;
        controller.affectedCount = 0;
        controller.save();
        controller.getDataflows();
        controller.getSalesApplications();
        controller.getRoles();
        controller.getProfiles();
        controller.handleAffected();
        controller.useOpportunityOwners = false;
        UserRole childRole = [SELECT ParentRoleID FROM UserRole WHERE ParentRoleID != null LIMIT 1];
        controller.selectedRoleId = childRole.ParentRoleID;
        controller.handleAffected();
        controller.alsoRoleSubordinates = true;
        controller.handleAffected();
        controller.alsoRoleSubordinates = false;
        controller.handleAffected();
        User u = [SELECT ProfileId FROM User LIMIT 1];
        controller.selectedProfilesIds = new Id[]{u.ProfileId};
        controller.handleAffected();
        controller.quotaAmount = 100000;
        controller.useOpportunityOwners = true;
        controller.save();
        controller.useOpportunityOwners = false;
        controller.save();
        controller.alsoRoleSubordinates = true;
        controller.save();
    }
}
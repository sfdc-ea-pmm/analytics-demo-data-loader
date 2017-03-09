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

    @isTest private static void testWaveFoldersCallout(){

        // HTTP Callout Mock
        ManageQuotaDatasetsController controller = new ManageQuotaDatasetsController();
        String mockData = '{"folders":[{"applicationStatus":"completedstatus","assetSharingUrl":"https://na30.salesforce.com/analytics/wave/application?assetId=00l36000001A8o8AAC&orgId=00D36000001H55A&loginHost=na30.salesforce.com&urlType=sharing","canBeSharedExternally":false,"createdBy":{"id":"00536000002AVSiAAO","name":"Dylan Thom","profilePhotoUrl":"https://c.na30.content.force.com/profilephoto/72936000000g24q/T"},"createdDate":"2016-09-09T19:33:34.000Z","icon":{"id":"00l36000001A8o8AAC","name":"6.png","url":"/analytics/wave/web/proto/images/app/icons/6.png"},"id":"00l36000001A8o8AAC","label":"SalesWaveLuc","lastAccessedDate":"2016-10-26T19:14:49.000Z","lastModifiedBy":{"id":"00536000002AVSiAAO","name":"Dylan Thom","profilePhotoUrl":"https://c.na30.content.force.com/profilephoto/72936000000g24q/T"},"lastModifiedDate":"2016-09-09T19:37:22.000Z","name":"SalesWaveLuc","permissions":{"manage":true,"modify":true,"view":true},"shares":[],"templateOptions":{},"templateSourceId":"sfdc_internal__Sales_Analytics","templateValues":{},"templateVersion":"2.0","type":"folder","url":"/services/data/v38.0/wave/folders/00l36000001A8o8AAC"}],"totalSize":1,"url":"/services/data/v38.0/wave/folders"}';
        Map<String, String> responseHeaders = new Map<String, String>();
        responseHeaders.put('Content-Type', 'application/json');
        WaveFolderRestApiHttpCalloutMock mockObj = new WaveFolderRestApiHttpCalloutMock(200, '', mockData, responseHeaders);
        Test.setMock(HttpCalloutMock.class, mockObj);
        Test.startTest();
        List<SelectOption> apps = controller.getSalesApplications();
        Test.stopTest();

        System.assert(apps != null);
    }
    
    @isTest
    private static void testManageQuotaDatasetsController() {

        ManageQuotaDatasetsController controller = new ManageQuotaDatasetsController();
        Dataflow dfServices = [SELECT Id, DeveloperName FROM Dataflow WHERE DeveloperName LIKE 'Service_Wave%' LIMIT 1];
        Dataflow dfSales = [SELECT Id, DeveloperName FROM Dataflow WHERE DeveloperName LIKE 'Sales_Wave%' LIMIT 1];
        controller.salesApp = dfSales.DeveloperName;
        controller.dataflowId = dfSales.Id;
        controller.affectedCount = 0;
        controller.save();
        controller.getDataflows();
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

        controller.salesApp = dfServices.DeveloperName;
        controller.dataflowId = dfServices.Id;
        controller.save();
    }
}
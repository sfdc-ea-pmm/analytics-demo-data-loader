public with sharing class WaveDataManagerController {
	
	public String VisualforceContextHost { get;set; }
    public String Host { get;set; }
	public String RemoteSiteName { get { return 'InstanceHost'; } }
	public String MetadataResponse {get;set;}
	public Boolean MetadataConnectionWarning {get;set;}
	public String MetadataApiException {get;set;}
	public String selectedWaveApp { get; set; }
	public String errorMessage { get; set; }
	public String successMessage  { get; set; }
	public String warningMessage  { get; set; }
	public Id batchProcessId { get; set; }
	public Id queueProcessId { get; set; }
	public List<String> processingLog { get; set; }
	public Set<String> processingLogWithoutTime { get; set; }
	public Integer currentNodeIndex { get; set; }
	public Integer currentTimeShiftingNodeIndex { get; set; }
	public String currentObjectProcessing { get; set; }
	public List<WaveApplicationObject> objectsNodes { get; set; }
	public List<WaveApplicationEdgemart> edgemartsNodes { get; set; }
	public boolean disabledButton { get; set; }
	private WaveMetadata metadata;
	private Map<String, String> appDescriptions; // <appName, appDesc>
	private Map<String, Integer> appIndexes; // <appName, appIndex in this.metadata.waveApplications>
	public String emailAddress { get; set; }
	public List<WaveApplicationRow> applicationRows;
	public WaveMetadataApplication selectedAppMetadata { get; set; }
	public GenericAppConfiguration genericAppConfiguration { get; set; }
	public static final String genericAppConfigurationFileName = 'SEADemoDataLoaderConfig';
	public Boolean pageRendered { get; set; }
	public WaveConfiguratorUtils utils;
	public List<WaveTimeShiftingItem> timeShiftingItems { get; set; }
	public Boolean enableTimeShiftingCheck { get; set; }
	public Boolean enableObjectProcessingCheck { get; set; }
	public String selectedInstallationProcess { get; set; }
	public List<List<SF_MetadataUtils.CustomFieldSpecification>> objectsAndFieldsMatrix;
	public Integer currentObjectIndex;
	public Integer currentFieldIndex;
	public Integer currentEdgemartIndex;
	public Boolean processingObjectsAndFieldsMetadata { get; set; }
	public Boolean processingEdgemartsLoad { get; set;}
	public List<List<SF_MetadataUtils.RecordTypeSpecification>> objectsRecordTypesMatrix;
	public Integer currentRecordTypeIndex;
	public Boolean processingRecordTypes { get; set; }
	public List<UserPhotoInfo> userPhotoNodes;
	public Integer currentUserPhotoNodeIndex;
	public Boolean uploadingUserPhotos { get; set; }
	public Boolean advancedOption { get; set; }
	public Integer daysToShift { get; set; }
	public String timeShiftingcalculatedDateLabel { get; set; }
	public Map<String,Map<String,String>> operationsStatusTable { get; set; }
	public String timeShiftingWhereClause { get; set; }
	public Boolean advancedTimeShifting { get; set; }
	public Boolean overrideDefaultSettingTS { get; set; }
	public List<AnalyticsDemoFAQ> analyticsDemoFAQ { get; set; }
	public String baseUrl { get; set; } 
	public Map<String, Boolean> selectedObjectsToTimeShift { get; set; }
	public CustomModalConfirmation modalMessage { get; set; }
	public Boolean shiftOnlyOfApp { get; set; }
	public String selectedDataflow { get; set; }
	public String selectedDataflowForActionFields { get; set; }
	public String selectedAnalyticsApp { get; set; }
	public Map<String, Map<String, WaveApplicationActionField>> actionInputFields { get; set; }
	public String createCompleteAppId { get; set; }
	public String createCompleteAppLabel { get; set; }
	public String createCompleteAppName { get; set; }
	private Map<String, String> folderIdByDatasetDevName; // <dataset developer name in org, folder id where it is stored>
	private Map<String, String> idsByDatasetDevName; // <dataset developer name in org, dataset id with which it is stored>
	private Map<String, WaveApplicationDataset> datasetsMap; // <dataset name as it comes from JSON, Dataset object as processed>
	private Map<String, WaveApplicationDashboard> dashboardsMap; // <dashboard name as it comes from JSON, Dashboard object as processed>
    private Map<String, String> dashboardImagesMapping;
	private Map<String, String> dashboardsIdsByName;
	private WaveApplicationImage referencedImages;
    public String insightsAppName { get; set; }
    public String insightsAppLabel { get; set; }
    public String insightsAppId { get; set; }
	public String handleCompleteAppFolderId { get; set; }
	public List<WaveApplicationDataset> datasetsNodes { get; set; }
	public Boolean processingLoadDatasets { get; set; }
	public Boolean processingLoadDashboards { get; set; }
	public List<WaveApplicationDashboard> dashboardsNodes { get; set; }
	public Integer currentDatasetIndex { get; set; }
	public Integer currentDashboardIndex { get; set; }

	// Secuence control
	public String installationStep { get; set; }

	public class UserPhotoInfo {
		public String zipFileUrl;
		public String fileNameToExtract;
		public String fileBaseName;
	}

	public WaveDataManagerController() {
		this.objectsNodes = new List<WaveApplicationObject>();
		this.edgemartsNodes = new List<WaveApplicationEdgemart>();
		this.datasetsNodes = new List<WaveApplicationDataset>();
		this.dashboardsNodes = new List<WaveApplicationDashboard>();
		this.timeShiftingItems = new List<WaveTimeShiftingItem>();
		this.processingLog = new List<String>();
		this.processingLogWithoutTime = new Set<String>();
		this.appDescriptions = new Map<String, String>();
		this.appIndexes = new Map<String, Integer>();
		this.emailAddress = UserInfo.getUserEmail();
		this.utils = new WaveConfiguratorUtils();
		this.objectsAndFieldsMatrix = new List<List<SF_MetadataUtils.CustomFieldSpecification>>();
		this.objectsRecordTypesMatrix = new List<List<SF_MetadataUtils.RecordTypeSpecification>>();
		this.MetadataResponse = '';
		this.installationStep = '';
		this.enableTimeShiftingCheck = false;
		this.enableObjectProcessingCheck = false;
		this.processingObjectsAndFieldsMetadata = false;
		this.selectedInstallationProcess = '';
		this.userPhotoNodes = new List<UserPhotoInfo>();
		this.advancedOption = false;
		this.advancedTimeShifting = false;
		this.daysToShift = 0;
		this.overrideDefaultSettingTS = false;
		this.shiftOnlyOfApp = true;
		this.operationsStatusTable = new Map<String,Map<String,String>>();
		this.analyticsDemoFAQ = new List<AnalyticsDemoFAQ>();
		this.selectedObjectsToTimeShift = new Map<String, Boolean>();
		this.modalMessage = new CustomModalConfirmation();
	}

	public PageReference pageLoad()
	{
		// Get Host Domain
		String result = null;
		List<String> fragments = URL.getSalesforceBaseUrl().getHost().split('\\.');

        if(fragments.size() == 3) {
        	result = fragments[0]; // Note: Apex URL: NA14.salesforce.com
    	}
    	else if(fragments.size() == 4){
            result = fragments[0] + '.' + fragments[1]; // Note: Apex URL: pmm-test-org.my.salesforce.com
        }
	    else if(fragments.size() == 5) {
        	result = fragments[1]; // Note: Visualforce URL: mydomain.NA14.visual.force.com
    	}
        
		Host = 'https://' + result + '.salesforce.com';
       	VisualforceContextHost = URL.getSalesforceBaseUrl().toExternalForm();
		
		try{

			//Get App Configuration File
			this.genericAppConfiguration = utils.getAppConfiguration(genericAppConfigurationFileName);
			this.pageRendered = true;
			this.baseUrl = this.genericAppConfiguration.baseUrl;

			if(Test.isRunningTest()){
				this.baseUrl = this.genericAppConfiguration.baseDevUrl;
			}

			this.getFaqJson();
			
			// Attempt to connect to the Metadata API
			MetadataConnectionWarning = false;
			if(!Test.isRunningTest() && !SF_MetadataUtils.checkMetadataAPIConnection())
			{
				this.warningMessage = 'Current Salesforce Instance URL not found in Remote Sites. See details below:';
				MetadataConnectionWarning = true;
				MetadataApiException = '';
				/*if(RollupService.LastMetadataAPIConnectionException!=null)
					MetadataApiException = RollupService.LastMetadataAPIConnectionException.getMessage();*/
			}

			if(applicationRows == null){
				applicationRows = WaveConfiguratorUtils.getWaveApplications(this.baseUrl + this.genericAppConfiguration.waveApplicationsUrl);
				if(this.applicationRows != null){
					Integer index = 0;
		        	for(WaveApplicationRow genericApp: this.applicationRows) {
						this.appIndexes.put(genericApp.Name, index);
						this.appDescriptions.put(genericApp.Name, genericApp.Description);
						index++;
					}
		        }
			}
		} 
		catch(WaveConfiguratorException ex){
			this.errorMessage = ex.getMessage();			
		}

		return null;
	}

	private void logMessage(String msg){

		if(!this.processingLogWithoutTime.contains(msg)){
			DateTime dtNow = DateTime.now();
			this.processingLog.add(String.format('[{0}] {1}', new String[]{ dtNow.format('yyyyMMdd HH:mm:ss') , msg }));
		}

		this.processingLogWithoutTime.add(msg);
	}

	public void getFaqJson(){
		try{
			if(String.isNotBlank(genericAppConfiguration.faqJsonUrl)){
				Http http = new Http();
				HttpRequest req = new HttpRequest();

				req.setEndpoint(this.baseUrl + genericAppConfiguration.faqJsonUrl);
		        req.setMethod('GET');

		        HTTPResponse res = http.send(req);
		        
		        if(WaveConfiguratorUtils.checkStatus(res)){
		        	this.analyticsDemoFAQ = (List<AnalyticsDemoFAQ>)JSON.deserialize(res.getBody(), List<AnalyticsDemoFAQ>.class);
		        }
		        else { 
		        	throw new WaveConfiguratorException('Error ' + res.getStatusCode() + ' - ' + res.getStatus() + ' in the attempt to get the FAQ file. Please make sure that it is pointing to a proper url');
		        }
			} 
			else {
				throw new WaveConfiguratorException('The FAQ file could not be retrieved. Please make sure that it is specified in the configuration file pointing to a proper url.');
			}    
    	} 
    	catch(Exception ex){
    		this.errorMessage = ex.getMessage();
    	}
	}

	public void handleAdvancedSetting(){
		this.advancedOption = !this.advancedOption;
	}

	public void handleAdvancedTimeShifting(){
		this.advancedTimeShifting = !this.advancedTimeShifting;
	}

	public void getWaveApplications(){
		this.errorMessage = '';
		this.applicationRows = null;
		
		try{
			applicationRows = WaveConfiguratorUtils.getWaveApplications(this.baseUrl + this.genericAppConfiguration.waveApplicationsUrl);			
			if(this.applicationRows != null){
				Integer index = 0;
	        	for(WaveApplicationRow genericApp: this.applicationRows) {
					this.appIndexes.put(genericApp.Name, index);
					this.appDescriptions.put(genericApp.Name, genericApp.Description);
					index++;
				}
	        }
        }
        catch(Exception ex){
        	this.errorMessage = 'The ' + this.baseUrl + this.genericAppConfiguration.waveApplicationsUrl + ' URL doesn\'t point to a valid wave applications list resource. Try changing Base URL and/or Application List URI.';
        }
	}

	public List<SelectOption> getWaveApps() {
        
        List<SelectOption> options = new List<SelectOption>();

        if(this.applicationRows != null){
        	for(WaveApplicationRow genericApp: this.applicationRows) {
				options.add(new SelectOption(genericApp.Name, genericApp.Label));
			}
        }

        return options;
    }

	public List<SelectOption> getAvailableProcesses() {
        
        List<SelectOption> options = new List<SelectOption>();

		/*
		<apex:selectOption itemValue="loadObjects" itemLabel="Load Data into Core"/>
		<apex:selectOption itemValue="createMetadata" itemLabel="Create Objects and Fields"/>
		<apex:selectOption itemValue="timeShifting" itemLabel="Time shifting"/>
		<apex:selectOption itemValue="loadEdgemarts" itemLabel="Load Datasets"/>
		<apex:selectOption itemValue="setActionFields" itemLabel="Set Action Fields"/>
		*/		

		if (this.selectedAppMetadata != null) {
			// Options to work with ORG Objects
			if (this.selectedAppMetadata.objects != null && this.selectedAppMetadata.objects.size() > 0) {
				options.add(new SelectOption('loadObjects', 'Load Data into Core'));
				options.add(new SelectOption('createMetadata', 'Create Objects and Fields'));
				options.add(new SelectOption('timeShifting', 'Time shifting'));
			}

			// Options to work with datasets
			if (this.selectedAppMetadata.edgemarts != null && this.selectedAppMetadata.edgemarts.size() > 0) {
				options.add(new SelectOption('loadEdgemarts', 'Load Datasets'));
			}

			if (this.selectedAppMetadata.actionFieldOverrides != null && this.selectedAppMetadata.actionFieldOverrides.size() > 0) {
				options.add(new SelectOption('setActionFields', 'Set Action Fields'));
			}

			if ((this.selectedAppMetadata.datasets != null && this.selectedAppMetadata.datasets.size() > 0) || (this.selectedAppMetadata.dashboards != null && this.selectedAppMetadata.dashboards.size() > 0)) {
				options.add(new SelectOption('createCompleteApp', 'Create App, Datasets and Dashboards'));
			}

			if ((this.selectedAppMetadata.datasets != null && this.selectedAppMetadata.datasets.size() > 0)) {
				options.add(new SelectOption('loadDatasetsToExistingApp', 'Load Datasets into existing app'));
			}

			if (options.size() > 0) {
				options.add(0, new SelectOption('', 'None'));
			}
		}

        return options;
    }

	public List<SelectOption> getOrgDataflows() {
        
        List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('', 'None')); // Empty item

        List<Dataflow> lstDataflows = [SELECT Id, MasterLabel FROM Dataflow WHERE DataflowType = 'User' AND State = 'Active'];
		for(Dataflow dataflowItem: lstDataflows) {
			options.add(new SelectOption(dataflowItem.Id, dataflowItem.MasterLabel));
		}

        return options;
    }

	public List<SelectOption> getOrgAnalyticsApps() {
        
        List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('', 'None')); // Empty item

        List<InsightsApplication> lstApps = [SELECT Id, MasterLabel FROM InsightsApplication WHERE DeveloperName NOT IN ('WAVE_PUBLIC_DATAFLOWS', 'SharedApp')];
		for(InsightsApplication apptem: lstApps) {
			options.add(new SelectOption(apptem.Id, apptem.MasterLabel));
		}

        return options;
    }

	public List<SelectOption> getOrgAnalyticsFolders() {
        
        List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('', 'None')); // Empty item

        List<Folder> lstApps = [SELECT Id, Name FROM Folder WHERE Type = 'Insights' AND Name NOT IN ('WavePublicDataflowsLabel', 'Einstein Bots', 'Einstein Forecasting')];
		for(Folder apptem: lstApps) {
			options.add(new SelectOption(apptem.Id, apptem.Name));
		}

        return options;
    }

    public void saveSetting(){
    	this.overrideDefaultSettingTS = true;
    	this.selectedProcess();
    }

	public void selectedApp(){
		this.selectedInstallationProcess = '';
		if (String.isNotBlank(this.selectedWaveApp)) {
			this.selectAppMetadata();
		}
	}

    public void selectedProcess(){
    	
    	this.resetMessages();

    	try{
			if(this.selectedInstallationProcess == 'timeShifting'){

				if(String.isNotBlank(this.selectedWaveApp)){
					this.getObjectsToTimeShift();
					
					List<String> objNames = new List<String>();

					for(String selectedObjs: this.selectedObjectsToTimeShift.keySet()){
						if(this.selectedObjectsToTimeShift.get(selectedObjs)){
							objNames.add(selectedObjs);
						}
					}

					this.checkForTriggersAndRules(objNames, true);
				}
				this.calculateDaysToShift();
			} 
			else if(this.selectedInstallationProcess == 'loadObjects'){
				
				if(String.isNotBlank(this.selectedWaveApp)){
					this.selectAppMetadata();
					List<String> objNames = new List<String>();

					for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
						objNames.add(wmaObj.name);
					}

					this.checkForTriggersAndRules(objNames, false);
				}
			}
			else if(this.selectedInstallationProcess == 'setActionFields'){
				
				this.actionInputFields = new Map<String, Map<String, WaveApplicationActionField>>();

				if(String.isNotBlank(this.selectedWaveApp)){
					this.selectAppMetadata();
					
					if(this.selectedAppMetadata.actionFieldOverrides != null){
						
						for(WaveMetadataApplicationActionField wmaAF: this.selectedAppMetadata.actionFieldOverrides) {
							
							WaveApplicationActionField waAF = new WaveApplicationActionField();
							waAF.datasetName = wmaAF.datasetName;
							waAF.actionFieldName = wmaAF.actionFieldName;
							waAF.actionFieldLabel = wmaAF.actionFieldLabel;
							waAF.computeExpressionName = wmaAF.computeExpressionName;

							// Build action fields inputText list
							Map<String, WaveApplicationActionField> mapWaf;
							
							if (this.actionInputFields.containsKey(waAF.datasetName)) {
								mapWaf = this.actionInputFields.get(waAF.datasetName);
							}
							else {
								mapWaf = new Map<String, WaveApplicationActionField>();
								this.actionInputFields.put(waAF.datasetName, mapWaf);
							}

							mapWaf.put(waAF.actionFieldName, waAF);
						}
					}
				}
			}
		}
		catch(Exception e){
            System.debug(e.getStackTraceString());
			this.errorMessage = e.getMessage();
		}
    }

    public void checkForTriggersAndRules(List<String> objNames, Boolean timeShifting){

    	List<ApexTrigger> triggers = [SELECT Status, TableEnumOrId FROM ApexTrigger WHERE TableEnumOrId IN :objNames];
    	
    	//Set that will contain the objects with triggers/wk/rules if found.
    	Set<String> objectsToWarn = new Set<String>(); 

    	if(triggers.size() > 0){
    		for(ApexTrigger tr: triggers){
    			if(tr.Status.equalsIgnoreCase('Active')){
    				objectsToWarn.add(tr.TableEnumOrId);
    			}
    		}
    	}

    	//Won't be necessary to search for Workflows/Rules in objects that already have triggers.
    	List<String> objWithoutTriggers = new List<String>();

    	for(String obj: objNames){
    		if(!objectsToWarn.contains(obj)){
    			objWithoutTriggers.add(obj);
    		}
    	}

    	List<String> objWithRulesOrWorkflows = SF_MetadataUtils.getObjectsWithRulesAndOrWorkflows(objWithoutTriggers, genericAppConfiguration.apiVersion);
    	this.buildConfirmationModal(objWithRulesOrWorkflows, objectsToWarn, timeShifting);
    }

	public void checkCreateCompleteAppExistence(){
		this.clearModal();
		if (this.utils.folderExists(this.createCompleteAppName)) {
			this.buildConfirmationModalGeneric('Process confirmation', 'The analytics application that you entered already exists. This action will overwrite all its dashboards and datasets. You may loose any customization made on it. Are you sure you want to continue?');
		}
	}

    public void buildConfirmationModal(List<String> objNames, Set<String> objToDisplay, Boolean timeShifting){
    	
    	this.clearModal();

    	//If there are workflows and/or validation rules, we added it to the main list.
    	if(objNames.size() > 0){
    		objToDisplay.addAll(objNames);
    	}

    	//If we have elements in list, we build the string to display in modal.
    	if(objToDisplay.size() > 0){
			String objectsDetected = '';

			Integer i = 0;
			for(String obj: objToDisplay){
				objectsDetected += obj;

				if(i < objToDisplay.size() - 1){
					objectsDetected += ', ';
				}

				i++;
			}
		
			modalMessage.body = 'Triggers, Workflow Rules and/or Validation Rules detected on the following objects: ' + objectsDetected + '. Make sure they are inactive or process may fail.';
		}
		
		//If time shifting, the modal will be displayed anyway.
    	if(timeShifting){
    		modalMessage.header = 'Process Confirmation';
    		modalMessage.body += ' All records will be time-shifted.';
    	}
    	else {
    		//If not time shifting , we make appear confirmation only when there're Triggers/Workflows/Rules
    		if(objToDisplay.size() > 0){
    			modalMessage.header = 'Process Confirmation';	
    		}
    	}
        
        modalMessage.body += ' Are you sure you want to continue?';
    }	

    public void clearModal(){
    	modalMessage.header = '';
    	modalMessage.body = '';
    }

	public void buildConfirmationModalGeneric(String modalHeader, String modalBody){
    	this.clearModal();
		modalMessage.header = modalHeader;
		modalMessage.body = modalBody;
    }

    public void getObjectsToTimeShift(){
    	this.selectAppMetadata();
    	this.selectedObjectsToTimeShift.clear();

    	for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
    		if(wmaObj.dateFieldsToShift != null && wmaObj.dateFieldsToShift.size() > 0){
    			this.selectedObjectsToTimeShift.put(wmaObj.Name, true);
    		}
    	}
    }

    public void calculateDaysToShift(){
		
		TimeShiftSettings tsSettings = this.selectedAppMetadata.timeShift;

		if(tsSettings != null && (String.isNotBlank(tsSettings.tObject) 
			&& String.isNotBlank(tsSettings.dateField) 
			&& String.isNotBlank(tsSettings.displayText))){
			
			String dateField = tsSettings.dateField;
			String baselineObjectName = tsSettings.tObject;
			this.timeShiftingcalculatedDateLabel = tsSettings.displayText;
		
			if(!this.overrideDefaultSettingTS){
				this.timeShiftingWhereClause = tsSettings.filter;
			}
			
			String dynamicSoql = 'SELECT ' + dateField + ' FROM ' + baselineObjectName;
			
			if(String.isNotBlank(this.timeShiftingWhereClause)){
				dynamicSoql += ' WHERE ' + this.timeShiftingWhereClause;
			}

			dynamicSoql += ' ORDER BY ' + dateField + ' DESC NULLS LAST';
			dynamicSoql += ' LIMIT 1';

			try{
				List<sObject> sobjList = Database.query(dynamicSoql);
				if(sobjList.size() > 0){				
					sObject s = sobjList.get(0);
					DateTime foundDate = (DateTime)s.get(dateField);
					if(foundDate != null) {
						String formattedDate = foundDate.formatGmt('MM/dd/yyyy');

						Date compareDate = Date.today();

						if(String.isNotBlank(tsSettings.compareDate)){
							compareDate = Date.valueOf(tsSettings.compareDate);	
						}

						Datetime dtCompareDate = (DateTime)compareDate;
						this.timeShiftingcalculatedDateLabel += ': ' + formattedDate + ' compared to ' + dtCompareDate.formatGmt('MM/dd/yyyy');
						this.daysToShift = foundDate.dateGMT().daysBetween(compareDate);
					}
					else {
						this.daysToShift = 0;
					}
				}
				else{
					this.daysToShift = 0;
				}
			}
			catch(Exception e){
				this.errorMessage = 'There was an error trying to calculate the days to shift. Error detail: ' + e.getMessage();
			}
		} else {
			this.daysToShift = 0;
			this.warningMessage = 'Unable to calculate the Number of Days to Shift Records. Please enter it manually.';
		}
	}
		

    public void updateSelectedObjectsToTimeShift(){
    	this.timeShiftingItems.clear();
		this.selectAppMetadata();

		List<String> objToCheck = new List<String>();

		for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
			//If object is selected in UI
			if(this.selectedObjectsToTimeShift.containsKey(wmaObj.Name)){
				if(this.selectedObjectsToTimeShift.get(wmaObj.Name)){
					this.addTimeShiftingNode(wmaObj);
					objToCheck.add(wmaObj.Name);
				}
			}
		}

		this.checkForTriggersAndRules(objToCheck, true);
    }

    public String getAppDescription(){
    	
    	String dsc = 'No description available.';

    	if(!String.isBlank(this.selectedWaveApp) && this.appDescriptions.containsKey(this.selectedWaveApp)){
    		dsc =  this.appDescriptions.get(this.selectedWaveApp);
    	}
    	
    	return dsc;
    }

	public void resetMessages(){
		this.errorMessage = '';
		this.successMessage = '';
		this.warningMessage = '';
		this.processingLog.clear();
		this.processingLogWithoutTime.clear();
	}

	public List<WaveApplicationObject> getObjectsToProcess(WaveMetadataApplicationObject wmaObj){
		List<WaveApplicationObject> listToProcess = new List<WaveApplicationObject>();
		
        if(String.isNotBlank(wmaObj.url) && String.isNotBlank(wmaObj.metadataUrl)){
            
            WaveApplicationObject rootObj = new WaveApplicationObject();
            rootObj.name = wmaObj.name;
            rootObj.url = this.baseUrl + wmaObj.url;
            rootObj.additionalDataFiles = wmaObj.additionalDataFiles;
            rootObj.stdFieldsForPermissionSet = wmaObj.stdFieldsForPermissionSet;
    
            listToProcess.add(rootObj);
    
            // We process the fields metadata
            IMockarooHelper iMockHelper = MockarooHelperFactory.getIMockarooHelper();
            
            String metadataUrl = this.baseUrl + wmaObj.metadataUrl;
    
            List<List<String>> csvMetadata = iMockHelper.getData(metadataUrl, false);
            if(csvMetadata.size() > 0){
                // Will extract headers
                List<String> headers = csvMetadata.remove(0);
                Map<String, Integer> fieldPositions = new Map<String, Integer>();
                
                for(Integer i = 0; i < headers.size(); i++) {
                    String fieldName = headers.get(i);
                    fieldName = fieldName.replace('"', '');
                    fieldPositions.put(fieldName, i);
                }
    
                // For each row of data in the CSV
                rootObj.fields = new List<WaveApplicationObjectField>();
    
                try{
                    for(List<String> metadataRow: csvMetadata) {
    
                        WaveApplicationObjectField fieldMetadata = new WaveApplicationObjectField();
                        fieldMetadata.Label = metadataRow.get(fieldPositions.get('Label')).trim();
                        fieldMetadata.Name = metadataRow.get(fieldPositions.get('Name')).trim();
                        fieldMetadata.Type = metadataRow.get(fieldPositions.get('Type')).trim();
                        fieldMetadata.PickListValues = metadataRow.get(fieldPositions.get('PickListValues')).trim();
                        fieldMetadata.ReferenceTo = metadataRow.get(fieldPositions.get('ReferenceTo')).trim();
                        fieldMetadata.Length = Integer.valueOf(metadataRow.get(fieldPositions.get('Length')));
                        fieldMetadata.Precision = Integer.valueOf(metadataRow.get(fieldPositions.get('Precision')));
                        fieldMetadata.Scale = Integer.valueOf(metadataRow.get(fieldPositions.get('Scale')));
                        fieldMetadata.IsExternalId = Boolean.valueOf(metadataRow.get(fieldPositions.get('IsExternalId')));
                        fieldMetadata.IsRequired = Boolean.valueOf(metadataRow.get(fieldPositions.get('IsRequired')));
                        fieldMetadata.DefaultValue = metadataRow.get(fieldPositions.get('DefaultValue')).trim();
                        fieldMetadata.Formula = metadataRow.get(fieldPositions.get('Formula')).trim();
    
                        rootObj.fields.add(fieldMetadata);
                    }	
                } 
                catch(Exception ex){				
                    throw new WaveConfiguratorException('There is a configuration error. Missing csv columns at ' + metadataUrl);
                }
                
            }
            else {
                throw new WaveConfiguratorException('There is a configuration error. No metadata csv found at ' + metadataUrl + ' URL.');
            }
    
            // We process the relations
            rootObj.relations = new List<WaveApplicationObjectRelation>();
            if(wmaObj.relations != null){
                for(WaveMetadataApplicationObjectRelation relObj: wmaObj.relations) {
                    WaveApplicationObjectRelation rel = new WaveApplicationObjectRelation();
                    
                    rel.csvColumnName = relObj.csvColumnName;
                    rel.targetSObject = relObj.targetSObject;
                    rel.targetSObjectLookupField = relObj.targetSObjectLookupField;
                    rel.foreignKeyField = relObj.foreignKeyField;
    
                    if (relObj.compositeForeignKey != null) {
                        // We have a composite foreign key
                        rel.compositeForeignKey = new List<WaveApplicationCompositeForeignKeyPart>();
    
                        for (WaveMetadataCompositeForeignKeyPart wmcFKP : relObj.compositeForeignKey) {
                           WaveApplicationCompositeForeignKeyPart wacFKP = new WaveApplicationCompositeForeignKeyPart();
                           wacFKP.csvColumnName = wmcFKP.csvColumnName;
                           wacFKP.targetSObjectLookupField = wmcFKP.targetSObjectLookupField;
                           rel.compositeForeignKey.add(wacFKP);
                        }
                    }
    
                    rootObj.relations.add(rel);
                }
            }
    
            // Replicate for each adittional data CSV file
    
            // We process the children
            if(wmaObj.children != null) {
                // Now the children objects
                for(WaveMetadataApplicationObject chObj: wmaObj.children) {
                    List<WaveApplicationObject> childrenObjs = getObjectsToProcess(chObj);
                    listToProcess.addAll(childrenObjs);
                }
            }
        }

		return listToProcess;
	}

	private void processCurrentObjectLoadNode(){
		
		try{
			WaveApplicationObject currentNode = this.objectsNodes.get(this.currentNodeIndex);
			this.operationsStatusTable.get(currentNode.Name).put('LoadData','In progress');
			this.logMessage('Loading records for ' + currentNode.name + ' object...');
            
            String csvDataWithHeaders;
            HttpResponse res;
            String url;

            // Check whether we are in the initial chunk of CSV data or not
            if(currentNode.currentDataIndex == 0){
                // We start processing the initial chunk of data
                url = currentNode.url;
				res = WaveConfiguratorUtils.httpGetCallout(url);
                csvDataWithHeaders = res.getBody();
            }
            else {
                url = currentNode.url.substringBeforeLast('.csv') + '-' + currentNode.currentDataIndex + '.csv';
                res = WaveConfiguratorUtils.httpGetCallout(url);
                csvDataWithHeaders = res.getBody();
            }

            if(res.getStatusCode() != 200) {
				throw new WaveConfiguratorException('There is a configuration error. No data csv found at ' + url + ' URL.');            	
            }

			// We search for \n
			Integer indexOfLF = csvDataWithHeaders.indexOf('\n');
			if(indexOfLF != -1){
				
				String headersLine = csvDataWithHeaders.substring(0, indexOfLF);
								
				// We search for \r
				if(headersLine.indexOf('\r') != -1){
					headersLine = headersLine.replace('\r', '');
				}

				headersLine = headersLine.replace('"', '');
				List<String> headers = headersLine.split(',');
				
				currentNode.fieldPositions = new Map<Integer, String>();
					
				for(Integer i = 0; i < headers.size(); i++) {
					currentNode.fieldPositions.put(i, headers[i]);
				}

				String csvData = csvDataWithHeaders.substringAfter('\n');
				if(csvData.length() > 0){

					this.currentObjectProcessing = currentNode.name;

					// Start the batch process
					CsvDataImportBatch batchProcess = new CsvDataImportBatch(Schema.getGlobalDescribe().get(currentNode.name), csvData, currentNode.fieldPositions, currentNode.relations, genericAppConfiguration.apiVersion);
					this.batchProcessId = Database.executeBatch(batchProcess, this.genericAppConfiguration.objectLoadingBatchSize);
					this.enableObjectProcessingCheck = true;					
				}
			}	
		} 
		catch(Exception e){
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.enableObjectProcessingCheck = false;
			this.disabledButton = false;
			this.errorMessage = e.getMessage();
		}	
	}


	private void processTimeShiftingObjects(){
		
		if(this.timeShiftingItems.size() > 0){
			WaveTimeShiftingItem currentNode = this.timeShiftingItems.get(this.currentTimeShiftingNodeIndex);
			this.operationsStatusTable.get(currentNode.objectTypeName).put('TimeShifting','In progress');
			this.logMessage('Loading ' + currentNode.fieldsToTimeShift.size() + ' fields for time shifting for ' + currentNode.objectTypeName + ' object...');

			String externalIdPrefix = '';

			if(this.shiftOnlyOfApp){
				externalIdPrefix = currentNode.externalIdObjectPrefix;
			}

			// Start the batch process
			TimeShiftingBatch batchProcess = new TimeShiftingBatch(currentNode.objectTypeName, currentNode.fieldsToTimeShift, this.daysToShift, externalIdPrefix);
			this.batchProcessId = Database.executeBatch(batchProcess, this.genericAppConfiguration.timeShiftingBatchSize);

		} 
		else{
			this.logMessage('There are no fields for time shifting.');
			this.finishTimeShiftingProcess();			
		}

	}

	private void finishTimeShiftingProcess(){
		this.disabledButton = false;
		this.currentTimeShiftingNodeIndex = 0;
		this.timeShiftingItems.clear();
		this.logMessage('Done.');

		if(this.selectedInstallationProcess == 'timeShifting'){
			this.successMessage = 'The Time Shifting process has finished successfully.';
			WaveConfiguratorUtils.sendEmail(this.emailAddress, 'Time Shifting completed successfully', 'The Time Shifting process of your ORG data has finished successfully.');
		}
	}

	public PageReference checkObjectLoadingStatus(){
		
		try{
			if(!String.isBlank(this.batchProcessId)){

				WaveApplicationObject currentNode = this.objectsNodes.get(this.currentNodeIndex);
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, ExtendedStatus, TotalJobItems FROM AsyncApexJob WHERE Id = :this.batchProcessId];
				
				if(lstJobs.size() > 0){

					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'The process was interrupted due to errors while loading data for the ' + this.objectsNodes.get(this.currentNodeIndex).name + ' object. ';
							if (string.isNotBlank(asyncJob.ExtendedStatus)) {
								this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
							}
							this.currentNodeIndex = 0;
							currentNode.currentDataIndex = 0;
							this.objectsNodes.clear();
							this.disabledButton = false;

							// Rollback
							this.rollbackProcess(this.errorMessage, '');
						}
						else {
							// Completed entire job, inspect if there are more data files 
							// within the current node
							if(currentNode.currentDataIndex < currentNode.additionalDataFiles){
								currentNode.currentDataIndex = currentNode.currentDataIndex + 1;
								this.processCurrentObjectLoadNode();
							}
							else{
								// Entire node finished, reset currentNode.currentDataIndex
								currentNode.currentDataIndex = 0;
								
								// now check whether it was the last one
								if(this.currentNodeIndex == this.objectsNodes.size() - 1){
									this.objectsNodes.clear();
									this.currentTimeShiftingNodeIndex = 0;
									this.enableObjectProcessingCheck = false;

									if(String.isNotBlank(this.selectedAppMetadata.userProfilePicturesUrl)){
										// Build upload photos nodes
										String zipFileUrl = this.baseUrl + this.selectedAppMetadata.userProfilePicturesUrl;
										Blob file = this.utils.getUsersPhotosZipBlob(zipFileUrl);
										Zippex zip = new Zippex(file);
										
										for(String fileName: zip.getFileNames()){
			
											String fileBaseName = fileName;
											
											if(fileName.contains('/')){
												fileBaseName = fileName.substringAfterLast('/');
											}
													
											String nameToSave = fileBaseName.substringBeforeLast('.');

											if(String.isNotBlank(nameToSave)){
												// Add to the node array to be processed
												UserPhotoInfo userPhoto = new UserPhotoInfo();
												userPhoto.fileNameToExtract = fileName;
												userPhoto.fileBaseName = fileBaseName;
												userPhoto.zipFileUrl = zipFileUrl;
												this.userPhotoNodes.add(userPhoto);
											}
										}

										if(this.userPhotoNodes.size() > 0){
											this.logMessage('Loading user profile photos...');
											this.currentUserPhotoNodeIndex = 0;
											this.processCurrentUserPhoto();
											this.uploadingUserPhotos = true;
										}
										else {
											this.finishPrepCoreData();
										}
									}
									else {
										this.finishPrepCoreData();
									}									
								}
								else {
									// There are more nodes to process, increment index and reset
									// currentNode.currentDataIndex
									this.operationsStatusTable.get(currentNode.Name).put('LoadData','Done');
									this.currentNodeIndex = this.currentNodeIndex + 1;
									this.processCurrentObjectLoadNode();
								}
							}
						}		
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while loading data for the ' + this.objectsNodes.get(this.currentNodeIndex).name + ' object.';
						this.currentNodeIndex = 0;
						this.disabledButton = false;
						this.objectsNodes.clear();

						// Rollback
						this.rollbackProcess(this.errorMessage, '');
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while loading data for the ' + this.objectsNodes.get(this.currentNodeIndex).name + ' object. ';
						if (string.isNotBlank(asyncJob.ExtendedStatus)) {
							this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
						}
						this.currentNodeIndex = 0;
						this.disabledButton = false;
						this.objectsNodes.clear();

						// Rollback
						this.rollbackProcess(this.errorMessage, '');
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());

			this.objectsNodes.clear();
			this.currentNodeIndex = 0;
			this.disabledButton = false;
			
			// Rollback
			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}

		return null;
	}

	public void processCurrentUserPhoto(){
		// Launch current queueable job
		UserPhotoInfo currentNode = this.userPhotoNodes.get(this.currentUserPhotoNodeIndex);		
		UploadUserPhotoQueueable userPhotoUploadQueue = new UploadUserPhotoQueueable(currentNode.zipFileUrl, currentNode.fileNameToExtract, currentNode.fileBaseName);
		this.queueProcessId = System.enqueueJob(userPhotoUploadQueue);
	}

	public PageReference checkUserPhotoUploadStatus(){
		
		try {
			if(!String.isBlank(this.queueProcessId)){
				UserPhotoInfo currentNode = this.userPhotoNodes.get(this.currentUserPhotoNodeIndex);
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, ExtendedStatus, TotalJobItems FROM AsyncApexJob WHERE Id = :this.queueProcessId];
				
				if(lstJobs.size() > 0){

					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'The process was interrupted due to errors while uploading ' + this.userPhotoNodes.get(this.currentUserPhotoNodeIndex).fileBaseName + ' photo. ';
							if (string.isNotBlank(asyncJob.ExtendedStatus)) {
								this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
							}
							this.currentUserPhotoNodeIndex = 0;
							this.userPhotoNodes.clear();
							this.disabledButton = false;
							this.uploadingUserPhotos = false;
						}
						else {
							// now check whether it was the last one
							if(this.currentUserPhotoNodeIndex == this.userPhotoNodes.size() - 1){
								this.finishPrepCoreData();
							}
							else {
								// There are more nodes to process, increment index and reset
								this.currentUserPhotoNodeIndex = this.currentUserPhotoNodeIndex + 1;
								this.processCurrentUserPhoto();
							}
						}		
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while uploading ' + this.userPhotoNodes.get(this.currentUserPhotoNodeIndex).fileBaseName + ' photo.';
						this.currentUserPhotoNodeIndex = 0;
						this.userPhotoNodes.clear();
						this.disabledButton = false;
						this.uploadingUserPhotos = false;
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while uploading ' + this.userPhotoNodes.get(this.currentUserPhotoNodeIndex).fileBaseName + ' photo. ';
						if (string.isNotBlank(asyncJob.ExtendedStatus)) {
							this.errorMessage = this.errorMessage + 'Error: ' +  asyncJob.ExtendedStatus;
						}
						this.currentUserPhotoNodeIndex = 0;
						this.userPhotoNodes.clear();
						this.disabledButton = false;
						this.uploadingUserPhotos = false;
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			
			this.userPhotoNodes.clear();
			this.currentUserPhotoNodeIndex = 0;
			this.disabledButton = false;
			this.uploadingUserPhotos = false;
		}

		return null;
	}

	public void finishPrepCoreData(){
		this.disabledButton = false;
		this.uploadingUserPhotos = false;
		this.currentUserPhotoNodeIndex = 0;
		this.userPhotoNodes.clear();
		this.logMessage('Done.');
		this.successMessage = 'Data loaded successfully.';								
		WaveConfiguratorUtils.sendEmail(this.emailAddress, 'Prep Core Data completed successfully', 'The Prep Core Data has finished successfully.');
	}

	public PageReference checkTimeShiftingStatus(){
		
		try {
			if(!String.isBlank(this.batchProcessId)){
				WaveTimeShiftingItem currentNode = this.timeShiftingItems.get(this.currentTimeShiftingNodeIndex);
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, ExtendedStatus, TotalJobItems FROM AsyncApexJob WHERE Id = :this.batchProcessId];
				
				if(lstJobs.size() > 0){

					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'The process was interrupted due to errors while time shifting data for the ' + this.timeShiftingItems.get(this.currentTimeShiftingNodeIndex).objectTypeName + ' object. ';
							if (string.isNotBlank(asyncJob.ExtendedStatus)) {
								this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
							}
							this.currentTimeShiftingNodeIndex = 0;
							this.timeShiftingItems.clear();
							this.disabledButton = false;

							// Rollback
							this.rollbackProcess(this.errorMessage, '');
						}
						else {
							// now check whether it was the last one
							if(this.currentTimeShiftingNodeIndex == this.timeShiftingItems.size() - 1){
								this.finishTimeShiftingProcess();
							}
							else {
								// There are more nodes to process, increment index and reset
								this.operationsStatusTable.get(currentNode.objectTypeName).put('TimeShifting','Done');
								this.currentTimeShiftingNodeIndex = this.currentTimeShiftingNodeIndex + 1;
								this.processTimeShiftingObjects();
							}
						}		
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while time shifting data for the ' + this.timeShiftingItems.get(this.currentTimeShiftingNodeIndex).objectTypeName + ' object.';
						this.currentTimeShiftingNodeIndex = 0;
						this.timeShiftingItems.clear();
						this.disabledButton = false;

						// Rollback
						this.rollbackProcess(this.errorMessage, '');
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while time shifting data for the ' + this.timeShiftingItems.get(this.currentTimeShiftingNodeIndex).objectTypeName + ' object. ';
						if (string.isNotBlank(asyncJob.ExtendedStatus)) {
							this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
						}
						this.currentTimeShiftingNodeIndex = 0;
						this.timeShiftingItems.clear();
						this.disabledButton = false;

						// Rollback
						this.rollbackProcess(this.errorMessage, '');
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			
			this.timeShiftingItems.clear();
			this.currentTimeShiftingNodeIndex = 0;
			this.disabledButton = false;

			// Rollback
			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}

		return null;
	}

	public PageReference displayMetadataResponse()
	{
		// Display the response from the client side Metadata API callout
		if(this.MetadataResponse.length() == 0)
		{
			this.warningMessage = '';
			this.successMessage = 'Remote Site Settings have been created. Now you can continue using Analytics Demo Data Tool.';
			MetadataConnectionWarning = false;
		}
		else
		{
			this.warningMessage = '';
			this.errorMessage = this.MetadataResponse;
			MetadataConnectionWarning = true;
		}
		return null;
	}

	private void rollbackProcess(String mainMessage, String stackTrace){

		this.disabledButton = false;
		this.enableObjectProcessingCheck = false;
		this.enableTimeShiftingCheck = false;
	}

	public void launchObjectsLoading(){
		if(this.objectsNodes.size() > 0){
			// We start loading data for each object
			this.logMessage('This process can take up to 30 minutes. We will refresh status every 5 seconds.');
			this.currentNodeIndex = 0;
			this.disabledButton = true;

			// This launchs all the process of loading data to salesforce objects
			this.processCurrentObjectLoadNode();
		}
		else {
			this.logMessage('There are no objects to load.');
		}
	}

	private void launchRecordTypeCreation(){
		if(this.objectsRecordTypesMatrix.size() > 0){
			this.currentObjectIndex = 0;
			this.currentRecordTypeIndex = 0;
			this.processCurrentRecordType(true);
			this.processingRecordTypes = true;
		}
	}

	public void loadAllObjects(){
		try {
			if(this.installationStep == 'LoadObjects'){
				this.launchObjectsLoading();				
			}
		}
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.errorMessage = e.getMessage();
			this.installationStep = '';

			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}
		finally {
			// We reset this, don't want to re-execute this method. If we don't do this, 
			// page will recall this method.
			this.installationStep = '';
		}
	}

	public void executeSelectedProcess(){

		Boolean passedValidation = true;
		this.resetMessages();
		this.getWaveApplications();

		try{
			
			if(String.isBlank(this.selectedWaveApp)){
				throw new WaveConfiguratorException('Please select an App to configure.');
			}

			if(this.selectedInstallationProcess == 'createMetadata'){
				this.disabledButton = true;
				this.selectAppMetadata();

				if(this.selectedAppMetadata.objects != null){
					
					List<WaveApplicationObject> lstObjects = new List<WaveApplicationObject>();
					// Retrieve objects to process

					for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
						this.operationsStatusTable.get(wmaObj.Name).put('CreateObjectsAndFields','Pending');
						List<WaveApplicationObject> objs = this.getObjectsToProcess(wmaObj);
						lstObjects.addAll(objs);
						this.addRecordTypeNodes(wmaObj);
					}

					this.objectsNodes = lstObjects;
					createObjectsAndFields(this.objectsNodes);
				}
			}
			else if(this.selectedInstallationProcess == 'timeShifting'){
				this.disabledButton = true;
				this.currentTimeShiftingNodeIndex = 0;
				this.enableTimeShiftingCheck = true;
				this.timeShiftingItems.clear();

				for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
					//If object is selected in UI
					if(this.selectedObjectsToTimeShift.containsKey(wmaObj.Name)){
						if(this.selectedObjectsToTimeShift.get(wmaObj.Name)){
							this.addTimeShiftingNode(wmaObj);
						}
					}
				}

				this.processTimeShiftingObjects();
			}
			else if(this.selectedInstallationProcess == 'loadObjects'){
				this.disabledButton = true;
				this.selectAppMetadata();

				if(this.selectedAppMetadata.objects != null){
					this.timeShiftingItems.clear();
				
					for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
						this.addTimeShiftingNode(wmaObj);
					}
					
					List<WaveApplicationObject> lstObjects = new List<WaveApplicationObject>();
					// Retrieve objects to process
					for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
						this.operationsStatusTable.get(wmaObj.Name).put('LoadData','Pending');
						List<WaveApplicationObject> objs = this.getObjectsToProcess(wmaObj);
						lstObjects.addAll(objs);
						this.addRecordTypeNodes(wmaObj);
					}

					this.objectsNodes = lstObjects;
					//createObjectsAndFields(this.objectsNodes); UNCOMMENT
					this.launchObjectsLoading(); // COMMENT
				}
			} 
			else if(this.selectedInstallationProcess == 'loadEdgemarts'){
				this.disabledButton = true;
				this.selectAppMetadata();
				this.edgemartsNodes.clear();

				if(this.selectedAppMetadata.edgemarts != null){
					
					for(WaveMetadataApplicationEdgemart wmaEdg: this.selectedAppMetadata.edgemarts) {
						
						WaveApplicationEdgemart waEdg = new WaveApplicationEdgemart();
						waEdg.edgemartDeveloperName = wmaEdg.edgemartDeveloperName;
						waEdg.edgemartLabel = wmaEdg.edgemartLabel;
						waEdg.edgemartCsvDataUrl = wmaEdg.edgemartCsvDataUrl;
						waEdg.edgemartJsonSchemaUrl = wmaEdg.edgemartJsonSchemaUrl;
						waEdg.edgemartNodeNameInDataflow = wmaEdg.edgemartNodeNameInDataflow;
						waEdg.edgemartNodeNameToReplaceInDataflow = wmaEdg.edgemartNodeNameToReplaceInDataflow;
						waEdg.objectName = wmaEdg.objectName;
						waEdg.replaceData = wmaEdg.replaceData;

						this.edgemartsNodes.add(waEdg);
					}
					
					loadEdgemarts();
				}
			}
			else if(this.selectedInstallationProcess == 'setActionFields'){
				setActionFields();				
			}
			else if (this.selectedInstallationProcess == 'createCompleteApp') {
				// Process specific pre validation

				this.resetMessages();
				// Start with validations
				if(String.isBlank(this.createCompleteAppName)){
					passedValidation = false;
					this.warningMessage = 'Analytics application name must be specified.';
				}
				
				if(String.isBlank(this.createCompleteAppLabel)){
					passedValidation = false;
					this.warningMessage = 'Analytics application label name must be specified.';
				}				

				if (passedValidation) {
					this.disabledButton = true;
					this.selectAppMetadata();
					this.datasetsNodes.clear();
					this.dashboardsNodes.clear();

					if(this.selectedAppMetadata.datasets != null){
						
						for(WaveMetadataApplicationDataset wmaEdg: this.selectedAppMetadata.datasets) {
							
							WaveApplicationDataset waDataset = new WaveApplicationDataset();
							waDataset.name = wmaEdg.name;
							waDataset.label = wmaEdg.label;
							waDataset.jsonSchemaUrl = wmaEdg.jsonSchemaUrl;
							waDataset.csvDataUrl = wmaEdg.csvDataUrl;
							waDataset.xmdUrl = wmaEdg.xmdUrl;
							waDataset.dataParts = wmaEdg.dataParts;

							this.datasetsNodes.add(waDataset);
						}
					}

					if(this.selectedAppMetadata.dashboards != null){
						
						for(WaveMetadataApplicationDashboard wmaDash: this.selectedAppMetadata.dashboards) {
							
							WaveApplicationDashboard waDashboard = new WaveApplicationDashboard();
							waDashboard.name = wmaDash.name;
							waDashboard.referencedDatasets = wmaDash.referencedDatasets;
							waDashboard.referencedDashboards = wmaDash.referencedDashboards;
							waDashboard.referencedImages = wmaDash.referencedImages;
							waDashboard.jsonUrl = wmaDash.jsonUrl;

							this.dashboardsNodes.add(waDashboard);
						}
					}

					handleCompleteApp(true);
				}
			}
			else if(this.selectedInstallationProcess == 'loadDatasetsToExistingApp'){
				this.resetMessages();
				
				// Start with validations
				if(String.isBlank(this.handleCompleteAppFolderId)){
					passedValidation = false;
					this.warningMessage = 'An Analytics Application name must be selected.';
				}

				if (passedValidation) {
					this.disabledButton = true;
					this.selectAppMetadata();
					this.datasetsNodes.clear();
					this.dashboardsNodes.clear();

					if(this.selectedAppMetadata.datasets != null){
						
						for(WaveMetadataApplicationDataset wmaEdg: this.selectedAppMetadata.datasets) {
							
							WaveApplicationDataset waDataset = new WaveApplicationDataset();
							waDataset.name = wmaEdg.name;
							waDataset.label = wmaEdg.label;
							waDataset.jsonSchemaUrl = wmaEdg.jsonSchemaUrl;
							waDataset.csvDataUrl = wmaEdg.csvDataUrl;
							waDataset.xmdUrl = wmaEdg.xmdUrl;
							waDataset.dataParts = wmaEdg.dataParts;

							this.datasetsNodes.add(waDataset);
						}
					}

					handleCompleteApp(false);
				}
			}
		}
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.errorMessage = e.getMessage();
			this.disabledButton = false;
			this.installationStep = '';
			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}
	}

	public void setActionFields(){
		if(String.isBlank(this.selectedDataflowForActionFields)){
			throw new WaveConfiguratorException('You are required to select dataflow for this operation.');
		}

		List<WaveApplicationActionField> fieldsToSet = new List<WaveApplicationActionField>();
		
		for (String dsName: this.actionInputFields.keySet()) {
			for (WaveApplicationActionField v: this.actionInputFields.get(dsName).values()) {
				if (!String.isBlank(v.actionFieldValue)) {
					fieldsToSet.add(v); // Value was set by the user
					this.logMessage('Setting ' + v.actionFieldValue + ' value for ' + v.actionFieldLabel + ' field in ' + v.datasetName + ' dataset.');
				}
			}
		}

		AnalyticsDemoDataflowHelper dataflowHelper = new AnalyticsDemoDataflowHelper('v' + this.genericAppConfiguration.apiVersion);
		dataflowHelper.setComputeExpressionsForActionFields(this.selectedDataflowForActionFields, fieldsToSet);
		this.successMessage = 'The Set Action Fields process has finished successfully.';
	}

	public void loadEdgemarts(){
		// Check if there are edgemarts to load
		if(this.edgemartsNodes.size() > 0){

			this.currentEdgemartIndex = 0;
			this.processCurrentEdgemartLoad();
			this.processingEdgemartsLoad = true;
			
		}
		else {
			// We DON'T have metadata to process
			this.logMessage('No edgemarts to load.');
			this.disabledButton = false;
			this.processingEdgemartsLoad = false;
		}
	}

	public void processCurrentEdgemartLoad(){
		WaveApplicationEdgemart edg = this.edgemartsNodes.get(this.currentEdgemartIndex);
		LoadEdgemartQueueable edgCreationQueue = new LoadEdgemartQueueable(edg, this.selectedAnalyticsApp, UserInfo.getSessionId());
		this.queueProcessId = System.enqueueJob(edgCreationQueue);
		this.logMessage('Loading ' + edg.edgemartLabel + ' dataset.');
	}

	public PageReference checkEdgemartLoadStatus(){
		try {
			if(!String.isBlank(this.queueProcessId) && this.processingEdgemartsLoad){
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, ExtendedStatus, TotalJobItems FROM AsyncApexJob WHERE Id = :this.queueProcessId];
				WaveApplicationEdgemart currentEdg = this.edgemartsNodes.get(this.currentEdgemartIndex);

				if(lstJobs.size() > 0){
					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'Error while loading edgemart for the ' + currentEdg.objectName + ' object.';
							if (string.isNotBlank(asyncJob.ExtendedStatus)) {
								this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
							}
							this.currentEdgemartIndex = 0;
							this.processingEdgemartsLoad = false;
							this.disabledButton = false;
						}
						else {
							if(this.currentEdgemartIndex == this.edgemartsNodes.size() - 1){
								
								AnalyticsDemoDataflowHelper dataflowHelper = new AnalyticsDemoDataflowHelper('v' + this.genericAppConfiguration.apiVersion);
								
								// Dataflow will be edited?
								if (String.isNotBlank(this.selectedDataflow)) {									
									dataflowHelper.replaceSfdcDigestByEdgemarts(this.selectedDataflow, this.edgemartsNodes);
								}

								// App will be edited?
								if (String.isNotBlank(this.selectedAnalyticsApp)) {
									dataflowHelper.remapNamesInAssets(this.selectedAnalyticsApp);
								}

								// We are finished loading edgemarts
								this.finishEdgemartLoadProcess();
							}
							else {
								this.currentEdgemartIndex = this.currentEdgemartIndex + 1;
								this.processCurrentEdgemartLoad();
							}
						}		
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while loading edgemart for the ' + currentEdg.objectName + ' object.';
						this.currentEdgemartIndex = 0;
						this.processingEdgemartsLoad = false;
						this.disabledButton = false;
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while loading edgemart for the ' + currentEdg.objectName + ' object.';
						if (string.isNotBlank(asyncJob.ExtendedStatus)) {
							this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
						}
						this.currentEdgemartIndex = 0;
						this.processingEdgemartsLoad = false;
						this.disabledButton = false;
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.currentEdgemartIndex = 0;
			this.processingEdgemartsLoad = false;
			this.disabledButton = false;
		}

		return null;
	}

	private void finishEdgemartLoadProcess(){
		this.disabledButton = false;
		this.currentEdgemartIndex = 0;
		this.edgemartsNodes.clear();
		this.logMessage('Done.');
		this.processingEdgemartsLoad = false;

		if(this.selectedInstallationProcess == 'loadEdgemarts'){
			this.successMessage = 'The Load Datasets process has finished successfully.';
			WaveConfiguratorUtils.sendEmail(this.emailAddress, 'Load Datasets completed successfully', 'The Load Datasets process of your ORG data has finished successfully.');
		}
	}	

	public void addRecordTypeNodes(WaveMetadataApplicationObject wmaObj){
		
		if(wmaObj.recordTypes != null && wmaObj.recordTypes.size() > 0){
			
			List<SF_MetadataUtils.RecordTypeSpecification> recordTypesToCreate = new List<SF_MetadataUtils.RecordTypeSpecification>();
			
			for(WaveRecordTypeItem rt: wmaObj.recordTypes){
				SF_MetadataUtils.RecordTypeSpecification rtSpec = new SF_MetadataUtils.RecordTypeSpecification();
				rtSpec.ObjectName = wmaObj.name;
				rtSpec.Name = rt.Label;
				rtSpec.DeveloperName = rt.developerName;
				rtSpec.BusinessProcessName = rt.businessProcessName;

				recordTypesToCreate.add(rtSpec);
			}

			if(recordTypesToCreate.size() > 0){
				this.objectsRecordTypesMatrix.add(recordTypesToCreate);
			}
		}
		
	}

	public void addTimeShiftingNode(WaveMetadataApplicationObject wmaObj){
		if(wmaObj.dateFieldsToShift != null && wmaObj.dateFieldsToShift.size() > 0){
			WaveTimeShiftingItem timeShiftingItem = new WaveTimeShiftingItem();
			timeShiftingItem.appType = this.selectedAppMetadata.appType;
			timeShiftingItem.objectTypeName = wmaObj.Name;
			timeShiftingItem.fieldsToTimeShift = wmaObj.dateFieldsToShift;
			timeShiftingItem.externalIdObjectPrefix = wmaObj.externalIdPrefix;

			this.selectedObjectsToTimeShift.put(wmaObj.Name, true);
			this.timeShiftingItems.add(timeShiftingItem);
		}
	}

	public void selectAppMetadata(){
		Integer appIndex = this.appIndexes.get(this.selectedWaveApp);
		WaveApplicationRow appRow = this.applicationRows.get(appIndex);
		
		// Retrieve and parse metadata
		HttpRequest req = new HttpRequest();
		req.setEndpoint(appRow.MetadataUrl);
        req.setMethod('GET');
		Http http = new Http();
        HTTPResponse res = http.send(req);

        if(res.getStatusCode() != 200){
        	throw new WaveConfiguratorException('There is a configuration error. No app configuration was found at the ' + appRow.MetadataUrl + ' URL.');
        }
		
		String jsonMetadata = res.getBody();
		this.selectedAppMetadata = (WaveMetadataApplication)JSON.deserialize(jsonMetadata, WaveMetadataApplication.class);
		
		if (this.selectedAppMetadata != null && this.selectedAppMetadata.objects != null) {
			for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
				Map<String,String> operationMap = new Map<String,String>();
				operationMap.put('CreateObjectsAndFields','N/A');
				operationMap.put('LoadData','N/A');
				operationMap.put('TimeShifting','N/A');
				operationMap.put('LoadEdgemarts','N/A');
				operationMap.put('SetActionFields', 'N/A');
				this.operationsStatusTable.put(wmaObj.Name, operationMap);
			}
		}
	}

	public void createObjectsAndFields(List<WaveApplicationObject> lstObjects){
		
		// Check if there are objects data to load
		if(lstObjects.size() > 0){

			// Objects and fields Setup

			for(WaveApplicationObject waObj: lstObjects) {
				List<SF_MetadataUtils.CustomFieldSpecification> fieldsToCreate = new List<SF_MetadataUtils.CustomFieldSpecification>();

				// Check fields existence using waObj.fields property
				for(WaveApplicationObjectField field: waObj.fields) {			
					
					if(field.Name.endsWithIgnoreCase('__c'))
					{
						SF_MetadataUtils.CustomFieldSpecification fieldSpec = new SF_MetadataUtils.CustomFieldSpecification();
						fieldSpec.ObjectName = waObj.name;
						fieldSpec.Name = field.Name;
				    	fieldSpec.Label = field.Label;
				    	fieldSpec.Type = field.Type;
				    	fieldSpec.PickListValues = field.PickListValues;
						fieldSpec.ReferenceTo = field.ReferenceTo;
						fieldSpec.Length = field.Length;
						fieldSpec.Precision = field.Precision;
						fieldSpec.Scale = field.Scale;
						fieldSpec.IsExternalId = field.IsExternalId;
						fieldSpec.IsRequired = field.IsRequired;
						fieldSpec.DefaultValue = field.DefaultValue;
						fieldSpec.Formula = field.Formula;

						fieldsToCreate.add(fieldSpec);
					}
				}			

				if(fieldsToCreate.size() > 0){
					this.objectsAndFieldsMatrix.add(fieldsToCreate);
				}
			}

			if(this.objectsAndFieldsMatrix.size() > 0){
				// We have metadata to process
				this.currentObjectIndex = 0;
				this.currentFieldIndex = 0;
				this.processCurrentObjectAndFieldsMetadata(true);
				this.processingObjectsAndFieldsMetadata = true;
			}
			else {
				// We DON'T have metadata to process
				this.logMessage('No need to create new objects and fields.');
				
				for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
					this.operationsStatusTable.get(wmaObj.Name).put('CreateObjectsAndFields','Done');
				}
				
				if(this.objectsRecordTypesMatrix.size() > 0){
					this.launchRecordTypeCreation();
				}
				else {
					
					if(this.selectedInstallationProcess == 'loadObjects'){
						// We chain this with object data loading
						this.launchObjectsLoading();
					}
					else if(this.selectedInstallationProcess == 'createMetadata'){
						this.disabledButton = false;
					}
				}
			}
		}
		else {
			this.currentObjectIndex = 0;
			this.currentFieldIndex = 0;
			this.processingObjectsAndFieldsMetadata = false;
			this.disabledButton = false;
			this.logMessage('There are no objects and fields to create.');
		}
	}

	private void processCurrentRecordType(Boolean startingWithObject){
		SF_MetadataUtils.RecordTypeSpecification initialRecordType = this.objectsRecordTypesMatrix.get(this.currentObjectIndex).get(this.currentRecordTypeIndex);
		
		if(startingWithObject){
			this.logMessage('Processing ' + initialRecordType.ObjectName + ' record type...');
		}

		CreateRecordTypesQueueable recordTypeCreationQueue = new CreateRecordTypesQueueable(initialRecordType, UserInfo.getSessionId());
		this.queueProcessId = System.enqueueJob(recordTypeCreationQueue);		
	}

	public PageReference checkRecordTypeCreationStatus(){
		
		try {
			if(!String.isBlank(this.queueProcessId) && this.processingRecordTypes){
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, ExtendedStatus, TotalJobItems FROM AsyncApexJob WHERE Id = :this.queueProcessId];
				SF_MetadataUtils.RecordTypeSpecification currentRecordType = this.objectsRecordTypesMatrix.get(this.currentObjectIndex).get(this.currentRecordTypeIndex);

				if(lstJobs.size() > 0){
					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'Error while processing ' + currentRecordType.Name + ' record type for the ' + currentRecordType.ObjectName + ' object. ';
							if (string.isNotBlank(asyncJob.ExtendedStatus)) {
								this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
							}
							this.currentObjectIndex = 0;
							this.currentRecordTypeIndex = 0;
							this.processingRecordTypes = false;
							this.disabledButton = false;
						}
						else {
							// now check whether it was the last one
							List<SF_MetadataUtils.RecordTypeSpecification> currentRecordTypeList = this.objectsRecordTypesMatrix.get(this.currentObjectIndex);

							if(this.currentObjectIndex == this.objectsRecordTypesMatrix.size() - 1){
								
								if(this.currentRecordTypeIndex == currentRecordTypeList.size() - 1){
									this.currentObjectIndex = 0;
									this.currentRecordTypeIndex = 0;
									this.objectsRecordTypesMatrix.clear();
									this.processingRecordTypes = false;
									this.disabledButton = false;
									this.logMessage('All needed metadata was created successfully.');

									if(this.selectedInstallationProcess == 'loadObjects'){
										this.launchObjectsLoading();
									}
								}
								else{
									this.currentRecordTypeIndex = this.currentRecordTypeIndex + 1;
									this.processCurrentRecordType(false);
								}
							}
							else {
								if(this.currentRecordTypeIndex == currentRecordTypeList.size() - 1){
									this.currentObjectIndex = this.currentObjectIndex + 1;
									this.currentRecordTypeIndex = 0;
									this.processCurrentRecordType(true);
								}
								else{
									this.currentRecordTypeIndex = this.currentRecordTypeIndex + 1;
									this.processCurrentRecordType(false);
								}
							}
						}		
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while processing ' + currentRecordType.Name + ' record type for the ' + currentRecordType.ObjectName + ' object.';
						this.currentObjectIndex = 0;
						this.currentRecordTypeIndex = 0;
						this.processingRecordTypes = false;
						this.disabledButton = false;
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while processing ' + currentRecordType.Name + ' record type for the ' + currentRecordType.ObjectName + ' object. ';
						if (string.isNotBlank(asyncJob.ExtendedStatus)) {
							this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
						}
						this.currentObjectIndex = 0;
						this.currentRecordTypeIndex = 0;
						this.processingRecordTypes = false;
						this.disabledButton = false;
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.currentObjectIndex = 0;
			this.currentRecordTypeIndex = 0;
			this.processingRecordTypes = false;
			this.disabledButton = false;
			this.objectsRecordTypesMatrix.clear();
		}

		return null;
	}

	private void processCurrentObjectAndFieldsMetadata(Boolean startingWithObject){

		SF_MetadataUtils.CustomFieldSpecification initialField = this.objectsAndFieldsMatrix.get(this.currentObjectIndex).get(this.currentFieldIndex);
		
		if(startingWithObject){
			this.operationsStatusTable.get(initialField.ObjectName).put('CreateObjectsAndFields','In progress');
			this.logMessage('Processing ' + initialField.ObjectName + ' object metadata...');
			
			if(!SF_MetadataUtils.objectExists(initialField.ObjectName)){
				this.logMessage(initialField.ObjectName + ' doesn\'t exists. Attempting to create it...');										
			}
		}

		CreateObjectsAndFieldsQueueable metadataCreationQueue = new CreateObjectsAndFieldsQueueable(initialField, UserInfo.getSessionId());
		this.queueProcessId = System.enqueueJob(metadataCreationQueue);
	}

	public PageReference checkMetadataCreationStatus(){
		
		try {
			if(!String.isBlank(this.queueProcessId) && this.processingObjectsAndFieldsMetadata){
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, ExtendedStatus, TotalJobItems FROM AsyncApexJob WHERE Id = :this.queueProcessId];
				SF_MetadataUtils.CustomFieldSpecification currentField = this.objectsAndFieldsMatrix.get(this.currentObjectIndex).get(this.currentFieldIndex);

				if(lstJobs.size() > 0){
					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'Error while processing metadata for the ' + currentField.ObjectName + ' object. Field: ' + currentField.Name + '. ';
							if (string.isNotBlank(asyncJob.ExtendedStatus)) {
								this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
							}
							this.currentObjectIndex = 0;
							this.currentFieldIndex = 0;
							this.processingObjectsAndFieldsMetadata = false;
							this.disabledButton = false;
						}
						else {
							// now check whether it was the last one
							List<SF_MetadataUtils.CustomFieldSpecification> currentFieldList = this.objectsAndFieldsMatrix.get(this.currentObjectIndex);

							if(this.currentObjectIndex == this.objectsAndFieldsMatrix.size() - 1){
								
								if(this.currentFieldIndex == currentFieldList.size() - 1){
									this.currentObjectIndex = 0;
									this.currentFieldIndex = 0;
									this.objectsAndFieldsMatrix.clear();
									this.processingObjectsAndFieldsMetadata = false;
									this.createPermissionSet();

									if(this.selectedInstallationProcess == 'loadObjects'){
										if(this.objectsRecordTypesMatrix.size() > 0){
											this.launchRecordTypeCreation();
										} 
										else{
											this.launchObjectsLoading();
										}
									}
									else if(this.selectedInstallationProcess == 'createMetadata'){
										this.logMessage('All needed metadata was created successfully.');
										this.disabledButton = false;
									}

								}
								else{
									this.currentFieldIndex = this.currentFieldIndex + 1;
									this.processCurrentObjectAndFieldsMetadata(false);
								}
							}
							else {
								if(this.currentFieldIndex == currentFieldList.size() - 1){
									this.currentObjectIndex = this.currentObjectIndex + 1;
									this.currentFieldIndex = 0;

									if(this.operationsStatusTable.containsKey(currentField.ObjectName)){
										this.operationsStatusTable.get(currentField.ObjectName).put('CreateObjectsAndFields','Done');
									}
								
									this.processCurrentObjectAndFieldsMetadata(true);
								}
								else{
									this.currentFieldIndex = this.currentFieldIndex + 1;
									this.processCurrentObjectAndFieldsMetadata(false);
								}
							}
						}		
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while processing metadata for the ' + currentField.ObjectName + ' object. Field: ' + currentField.Name + '.';
						this.currentObjectIndex = 0;
						this.currentFieldIndex = 0;
						this.processingObjectsAndFieldsMetadata = false;
						this.disabledButton = false;
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while processing metadata for the ' + currentField.ObjectName + ' object. Field: ' + currentField.Name + '. ';
						if (string.isNotBlank(asyncJob.ExtendedStatus)) {
							this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
						}
						this.currentObjectIndex = 0;
						this.currentFieldIndex = 0;
						this.processingObjectsAndFieldsMetadata = false;
						this.disabledButton = false;
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.currentObjectIndex = 0;
			this.currentFieldIndex = 0;
			this.processingObjectsAndFieldsMetadata = false;
			this.disabledButton = false;
			this.objectsAndFieldsMatrix.clear();
		}

		return null;
	}

	private void createPermissionSet(){
		List<PermissionSet> pr = [SELECT Id, Name, Label FROM PermissionSet WHERE Name = 'Analytics_Demo_Integration'];
		
		Id pSetId;
		
		if(pr.size() == 0){
			PermissionSet newPr = new PermissionSet();
		    newPr.Label = 'Analytics Demo Integration';
			newPr.Name = 'Analytics_Demo_Integration';

			insert newPr;
			pSetId = newPr.Id;
		} 
		else {
			pSetId = pr.get(0).Id;
		}


		Set<FieldPermissions> fieldPermissions = new Set<FieldPermissions>();
		
		List<String> fieldsToPermissionSet = new List<String>();

		for(WaveApplicationObject obj: this.objectsNodes){
			//Add to list the objects that were put in JSON
			if(obj.stdFieldsForPermissionSet != null){
				for(String field: obj.stdFieldsForPermissionSet){
					fieldsToPermissionSet.add(obj.Name + '.' + field);
				}
			}

			//Add to list the custom objects in org.
			List<String> customFields = this.getCustomFieldsForPermissionSet(obj.Name);
			fieldsToPermissionSet.addAll(customFields);
		}


		for(String field: fieldsToPermissionSet){
			
			FieldPermissions fp = new FieldPermissions();
			fp.Field = field;
			fp.ParentId = pSetId;
			fp.PermissionsRead = true;
			fp.SobjectType = field.substringBefore('.');

			fieldPermissions.add(fp);
		}
		
		List<FieldPermissions> alreadyThere = [SELECT Field, PermissionsRead FROM FieldPermissions WHERE ParentId = :pSetId];
		Map<String, Boolean> mapFieldPermissions = new Map<String, Boolean>();
		
		for(FieldPermissions existentField: alreadyThere){
		    mapFieldPermissions.put(existentField.Field, existentField.PermissionsRead);
		}

		List<FieldPermissions> fpToUpsert = new List<FieldPermissions>();

		for(FieldPermissions fp: fieldPermissions){
			//If permission field not exists for that parent
		    if(!mapFieldPermissions.containsKey(fp.Field)){
		        fpToUpsert.add(fp);
		    }
		    //If permissionRead is false
		    else if(!mapFieldPermissions.get(fp.Field)){
		    	fpToUpsert.add(fp);
		    }
		}

		if(fpToUpsert.size() > 0){
			upsert fpToUpsert;
		}
		
		List<User> analyticsCloudUsers = [SELECT Id FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Analytics Cloud Integration User')];
		List<PermissionSetAssignment> pSetAlreadyThere = [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN :analyticsCloudUsers AND PermissionSetId = :pSetId];

		if(pSetAlreadyThere.size() == 0){

			if(analyticsCloudUsers.size() > 0){
				List<PermissionSetAssignment> pAssignments = new List<PermissionSetAssignment>();

				for(User u: analyticsCloudUsers){
					PermissionSetAssignment pAssignment = new PermissionSetAssignment();
					pAssignment.AssigneeId = u.Id;
					pAssignment.PermissionSetId = pSetId;

					pAssignments.add(pAssignment);
				}
			
				insert pAssignments;
			}
		}
	}

	private List<String> getCustomFieldsForPermissionSet(String obj){
		
		if(Schema.getGlobalDescribe().containsKey(obj)){		
			Map<String, Schema.SObjectField> objectMap = Schema.getGlobalDescribe().get(obj).getDescribe().fields.getMap();

			List<String> fields = new List<String>();

			for(String f: objectMap.keySet()){
				Schema.DescribeFieldResult fieldDetails = objectMap.get(f).getDescribe();

				if(fieldDetails.isPermissionable() && f.endsWithIgnoreCase('__c')){
					fields.add(obj + '.' + String.valueOf(objectMap.get(f)));
				}
			}

			return fields;
		} 
		else {
			throw new WaveConfiguratorException(obj + ' object not supported.');
		}
	}

	private void getDatasetMappingToFolderId(){
		this.folderIdByDatasetDevName = new Map<String, String>();
		for (EdgeMart edg: [SELECT DeveloperName, FolderId FROM EdgeMart WHERE IsDeleted = false]) {
			this.folderIdByDatasetDevName.put(edg.DeveloperName, edg.FolderId);
		}
	}

	public void handleCompleteApp(Boolean createApp){
		// Check if there are datasets to load
		if (this.datasetsNodes.size() == 0 && this.dashboardsNodes.size() == 0) {
			// We DON'T have datasets or dashboards to process
			this.warningMessage = 'There are no datasets or dashboards to load to application.';
			this.disabledButton = false;
			this.processingLoadDatasets = false;
			this.processingLoadDashboards = false;
		}
		else {
			if (createApp) {
				// 1st, create app
				if(!this.utils.folderExists(this.createCompleteAppName)){
					this.handleCompleteAppFolderId = this.utils.insertFolder(this.createCompleteAppLabel, this.createCompleteAppName);
				}
				else {
					this.handleCompleteAppFolderId = this.utils.getFolderIdByDevName(this.createCompleteAppName);
				}

				// At this point we should have an InsightsApplication object created in the org with FolderId = this.handleCompleteAppFolderId
				this.insightsAppId = this.utils.getAnalyticsAppIdByDevName(this.createCompleteAppName);
			}
			else {
				this.insightsAppId = this.utils.getAnalyticsAppIdByFolderId(this.handleCompleteAppFolderId);
			}

			this.getDatasetMappingToFolderId();
			
			// Need to define dataset developer names
			for (WaveApplicationDataset ds : this.datasetsNodes) {
				// As default, we try to use it as it comes from config
				ds.nameToSave = ds.name;
				
				if (this.folderIdByDatasetDevName.containsKey(ds.name) && !this.folderIdByDatasetDevName.get(ds.name).equalsIgnoreCase(this.handleCompleteAppFolderId)) {
					// The dataset already exists in the org but it is contained in another app, need to generate new name
					Integer iSuffix = 0;
                    String edgNameCandidate = ds.Name;
					while(this.folderIdByDatasetDevName.containsKey(edgNameCandidate)){
						iSuffix++;
						edgNameCandidate = ds.Name + iSuffix;
					}
					
					ds.nameToSave = edgNameCandidate;
				}
			}			

			if(this.datasetsNodes.size() > 0){
				this.currentDatasetIndex = 0;
				this.processingLoadDatasets = true;
				this.processingLoadDashboards = false;
				this.processCurrentDatasetLoad();				
			}
			else if(this.dashboardsNodes.size() > 0){
				this.currentDashboardIndex = 0;
				this.processingLoadDatasets = false;
				this.processingLoadDashboards = true;
				this.processCurrentDashboardLoad();				
			}
		}
	}

	public void processCurrentDatasetLoad(){
		WaveApplicationDataset edg = this.datasetsNodes.get(this.currentDatasetIndex);
		LoadDatasetBatch dsBatch = new LoadDatasetBatch(edg, this.insightsAppId);
		this.batchProcessId = Database.executeBatch(dsBatch, 1);
		this.logMessage('Loading ' + edg.label + ' dataset.');
	}

	public void suggestAnalyticsAppName(){
		if (String.isBlank(this.createCompleteAppName) && String.isNotBlank(this.createCompleteAppLabel)) {
			
			String nameToSuggest = this.createCompleteAppLabel.trim();
			while (nameToSuggest.substring(0 ,1).isNumeric()) {
				nameToSuggest = nameToSuggest.substring(1);
			}
			
			this.createCompleteAppName = nameToSuggest.replaceAll('[^a-zA-Z0-9]', '_');
			this.checkCreateCompleteAppExistence();
		}
	}

	public PageReference checkDatasetLoadStatus(){
		try {
			if(!String.isBlank(this.batchProcessId) && this.processingLoadDatasets){
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, ExtendedStatus, TotalJobItems FROM AsyncApexJob WHERE Id = :this.batchProcessId];
				WaveApplicationDataset currentEdg = this.datasetsNodes.get(this.currentDatasetIndex);

				if(lstJobs.size() > 0){
					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'Error while loading dataset: ' + currentEdg.label;
							if (string.isNotBlank(asyncJob.ExtendedStatus)) {
								this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
							}
							this.currentDatasetIndex = 0;
							this.processingLoadDatasets = false;
							this.disabledButton = false;
							this.createCompleteAppName = '';
							this.handleCompleteAppFolderId = '';
							this.insightsAppId = '';
						}
						else {
							String datasetLoadStatus = WaveConfiguratorUtils.getDatasetUploadStatus(currentEdg.nameToSave);
							if (datasetLoadStatus.equalsIgnoreCase('Completed') || datasetLoadStatus.equalsIgnoreCase('CompletedWithWarnings')) {
								if (datasetLoadStatus.equalsIgnoreCase('CompletedWithWarnings')) {
									this.logMessage('Load completed with warnings. Please go to Analytics Studio / Data Manager for details.');
								}
								// Dataset upload completed
								//Load XMD ?
								// XMD
								if (String.isNotBlank(currentEdg.xmdUrl)) {
									WaveConfiguratorUtils.setXmdForDataset(currentEdg.nameToSave, currentEdg.xmdUrl, this.genericAppConfiguration.apiVersion);
								}
								
								//Now we have to finish or move to next dataset upload
								if(this.currentDatasetIndex == this.datasetsNodes.size() - 1){
									
									// We are finished loading app datasets
									this.processingLoadDatasets = false;

									if (this.selectedInstallationProcess.equals('createCompleteApp')) {
										// Creating complete app, now launch dashboards load
										this.currentDashboardIndex = 0;
										this.processingLoadDatasets = false;
										this.processingLoadDashboards = true;
										this.processCurrentDashboardLoad();	
									}
									else if(this.selectedInstallationProcess.equals('loadDatasetsToExistingApp')){
										// Only loading datasets into existing app, finish
										this.finishHandleCompleteAppProcess();
									}
								}
								else {
									// Not finished yet, move to next dataset upload
									this.currentDatasetIndex = this.currentDatasetIndex + 1;
									this.processCurrentDatasetLoad();
								}
							}
							else if (datasetLoadStatus.equalsIgnoreCase('Failed')) {
								this.errorMessage = 'The dataset: ' + currentEdg.label + ' failed to load. Please go to Analytics Studio / Data Manager for details.';
								this.currentDatasetIndex = 0;
								this.processingLoadDatasets = false;
								this.disabledButton = false;
								this.createCompleteAppName = '';
								this.handleCompleteAppFolderId = '';
								this.insightsAppId = '';
							}
						}
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while loading dataset: ' + currentEdg.label;
						this.currentDatasetIndex = 0;
						this.processingLoadDatasets = false;
						this.disabledButton = false;
						this.createCompleteAppName = '';
						this.handleCompleteAppFolderId = '';
						this.insightsAppId = '';
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while loading dataset: ' + currentEdg.label;
						if (string.isNotBlank(asyncJob.ExtendedStatus)) {
							this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
						}
						this.currentDatasetIndex = 0;
						this.processingLoadDatasets = false;
						this.disabledButton = false;
						this.createCompleteAppName = '';
						this.handleCompleteAppFolderId = '';
						this.insightsAppId = '';
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.currentDatasetIndex = 0;
			this.processingLoadDatasets = false;
			this.processingLoadDashboards = false;
			this.disabledButton = false;
			this.createCompleteAppName = '';
			this.handleCompleteAppFolderId = '';
			this.insightsAppId = '';
		}

		return null;
	}

	public void processCurrentDashboardLoad(){
		if (this.currentDashboardIndex == 0) {
			// Get Dataset Name, Id mapping
			List<String> lstDatasetDevNames = new List<String>();
			for (WaveApplicationDataset ds : this.datasetsNodes) {
				lstDatasetDevNames.add(ds.nameToSave);
			}
			this.idsByDatasetDevName = this.utils.getDatasetIdByDevNameMapping(lstDatasetDevNames);
			this.datasetsMap = new Map<String, WaveApplicationDataset>();
			for (WaveApplicationDataset ds : this.datasetsNodes) {
				ds.Id = this.idsByDatasetDevName.get(ds.nameToSave);
				this.datasetsMap.put(ds.name, ds);
			}
			
			// Load all dashboards so we can get the api names
			List<StaticResource> srList = [SELECT Body FROM StaticResource WHERE Name = 'BlankDashboardTemplate'];
			if(srList.size() == 0){
				throw new WaveConfiguratorException('BlankDashboardTemplate Static Resource not found.');
			}
			// We create the dummy dashboards and the Map for storing resulting IDs
			this.dashboardsIdsByName = new Map<String, String>();
			String dummyDashboardJson = srList.get(0).Body.toString();
			dummyDashboardJson = dummyDashboardJson.replace('{#FolderId}', this.handleCompleteAppFolderId);

			// Find if there exists dashboard
			Map<String, String> dashboardFoldersByName = new Map<String, String>();			
			for (Lens l: [SELECT DeveloperName, FolderId FROM Lens WHERE Type = 'dashboard' AND IsDeleted = false]) {
				dashboardFoldersByName.put(l.DeveloperName, l.FolderId);
			}

			Set<String> dashboardNames = dashboardFoldersByName.keySet();
			this.dashboardsMap = new Map<String, WaveApplicationDashboard>();

			for (WaveApplicationDashboard dash : this.dashboardsNodes) {
				
				dash.nameToSave = dash.name;

				if (!dashboardFoldersByName.containsKey(dash.name) || (dashboardFoldersByName.containsKey(dash.name) && !dashboardFoldersByName.get(dash.name).equals(this.handleCompleteAppFolderId))) {
					
					// Have to create new dashboard
					
					if (dashboardFoldersByName.containsKey(dash.name) && !dashboardFoldersByName.get(dash.name).equals(this.handleCompleteAppFolderId)) {
						// Dashboard already exists in the org but contained in another app. Need to find new name for it
						String dashNameCandidate = dash.name;
						Integer iSuffix = 0;                
						while(dashboardNames.contains(dashNameCandidate)){
							iSuffix++;
							dashNameCandidate = dash.name + iSuffix;
						}

						dash.nameToSave = dashNameCandidate;
					}

					String currDashJson = dummyDashboardJson.replace('{#DashboardName}', dash.nameToSave);
					this.utils.insertDashboard(currDashJson);
				}

				this.dashboardsMap.put(dash.name, dash);
			}

			// If there are images to load for dashboards
			this.dashboardImagesMapping = new Map<String, String>();
			if(this.selectedAppMetadata.referencedImages != null){
				this.referencedImages = new WaveApplicationImage();
				this.referencedImages.type = this.selectedAppMetadata.referencedImages.type;
				this.referencedImages.names = this.selectedAppMetadata.referencedImages.names;
				this.referencedImages.zipUrl = this.selectedAppMetadata.referencedImages.zipUrl;
				
				this.dashboardImagesMapping = this.utils.insertAnalyticsImages(this.referencedImages);
			}
		}

		WaveApplicationDashboard d = this.dashboardsNodes.get(this.currentDashboardIndex);
		LoadDashboardQueueable dashQueueable = new LoadDashboardQueueable(d, this.datasetsMap, this.dashboardsMap, this.referencedImages, this.dashboardImagesMapping, this.handleCompleteAppFolderId, genericAppConfiguration.apiVersion, UserInfo.getSessionId());
		this.queueProcessId = System.enqueueJob(dashQueueable);
		this.logMessage('Loading ' + d.name + ' dashboard.');
	}

	public PageReference checkDashboardLoadStatus(){
		try {
			if(!String.isBlank(this.queueProcessId) && this.processingLoadDashboards){
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, ExtendedStatus, TotalJobItems FROM AsyncApexJob WHERE Id = :this.queueProcessId];
				WaveApplicationDashboard currentDashboard = this.dashboardsNodes.get(this.currentDashboardIndex);

				if(lstJobs.size() > 0){
					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'Error while loading ' + currentDashboard.name + ' dashboard.';
							if (string.isNotBlank(asyncJob.ExtendedStatus)) {
								this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
							}
							this.currentDashboardIndex = 0;
							this.processingLoadDashboards = false;
							this.disabledButton = false;
							this.createCompleteAppName = '';
							this.handleCompleteAppFolderId = '';
							this.insightsAppId = '';
						}
						else {
							if(this.currentDashboardIndex == this.dashboardsNodes.size() - 1){
								
								// We are finished loading dashboards, finish process
								this.finishHandleCompleteAppProcess();
							}
							else {
								this.currentDashboardIndex = this.currentDashboardIndex + 1;
								this.processCurrentDashboardLoad();
							}
						}
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while loading ' + currentDashboard.name + ' dashboard.';
						this.currentDashboardIndex = 0;
						this.processingLoadDashboards = false;
						this.disabledButton = false;
						this.createCompleteAppName = '';
						this.handleCompleteAppFolderId = '';
						this.insightsAppId = '';
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while loading ' + currentDashboard.name + ' dasboard.';
						if (string.isNotBlank(asyncJob.ExtendedStatus)) {
							this.errorMessage = this.errorMessage + 'Detail: ' +  asyncJob.ExtendedStatus;
						}
						this.currentDashboardIndex = 0;
						this.processingLoadDashboards = false;
						this.disabledButton = false;
						this.createCompleteAppName = '';
						this.handleCompleteAppFolderId = '';
						this.insightsAppId = '';
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.currentDashboardIndex = 0;
			this.processingLoadDashboards = false;
			this.disabledButton = false;
			this.createCompleteAppName = '';
			this.handleCompleteAppFolderId = '';
			this.insightsAppId = '';
		}

		return null;
	}

	private void finishHandleCompleteAppProcess(){
		
		this.disabledButton = false;
		this.currentDatasetIndex = 0;
		this.currentDashboardIndex = 0;
		this.datasetsNodes.clear();
		this.dashboardsNodes.clear();
		this.logMessage('Done.');
		this.processingLoadDatasets = false;
		this.processingLoadDashboards = false;
		this.createCompleteAppName = '';
		this.handleCompleteAppFolderId = '';
		this.insightsAppId = '';

		if(this.selectedInstallationProcess == 'createCompleteApp'){
			this.successMessage = 'The Create App, Datasets and Dashboards process has finished successfully.';
			WaveConfiguratorUtils.sendEmail(this.emailAddress, 'Create App, Datasets and Dashboards completed successfully', 'The Create App, Datasets and Dashboards process of your ORG data has finished successfully.');
		}
		else if(this.selectedInstallationProcess == 'loadDatasetsToExistingApp'){
			this.successMessage = 'The Load Datasets Into Existing App process has finished successfully.';
			WaveConfiguratorUtils.sendEmail(this.emailAddress, 'Load Datasets Into Existing App completed successfully', 'The Load Datasets Into Existing App process of your ORG data has finished successfully.');
		}
	}
}
global class CsvDataImportBatch implements Database.Batchable<List<String>>, Database.Stateful {
	
	private List<List<String>> csvData;
	private Map<Integer, String> fieldPositions;
	private SObjectType objectType;
	private List<SmartLookup> nameSmartLookups;
	private List<SmartLookup> externalIdSmartLookups;
	private List<String> debugMessages;
	
	global CsvDataImportBatch(SObjectType objectType, List<List<String>> csvData, Map<Integer, String> fieldPositions) {
		this.objectType = objectType;
		this.csvData = csvData;
		this.fieldPositions = fieldPositions;
		this.nameSmartLookups = new List<SmartLookup>();
		this.externalIdSmartLookups = new List<SmartLookup>();
		this.debugMessages = new List<String>();
	}
	
	global Iterable<List<String>> start(Database.BatchableContext BC) {
		// Prepare headers and return all data
		this.prepareNameSmartLookups();
		this.prepareExternalIdSmartLookups();

		return this.csvData;
	}

   	global void execute(Database.BatchableContext BC, List<List<String>> scope) {

   		System.debug('About to process ' + scope.size() + ' records of type ' + this.objectType.getDescribe().getName());
		
   		// First handle smart lookups
   		this.smartLookupNameToId(scope);
   		this.smartLookupExternalId(scope);

   		List<SObject> objectsBatch = new List<SObject>();
   		List<String> lstExternalIds = new List<String>();
   		Map<String, Schema.SObjectField> objectFields = this.objectType.getDescribe().fields.getMap();

		for(List<String> sObjRow: scope) {

			SObject objToCreate = this.objectType.newSObject();

			for(Integer i = 0; i < sObjRow.size(); i++) {
				
				String fieldName = this.fieldPositions.get(i);
				String fieldValue = sObjRow[i];

				if(objectFields.containsKey(fieldName)){
					
					// Get field datatype
					Schema.DisplayType fieldType  = objectFields.get(fieldName).getDescribe().getType();

					if(fieldType == Schema.DisplayType.Boolean){
						objToCreate.put(fieldName, Boolean.valueOf(fieldValue));
					}
					else if (fieldType == Schema.DisplayType.Currency || fieldType == Schema.DisplayType.Double || fieldType == Schema.DisplayType.Percent) {
						System.debug(fieldName);
						objToCreate.put(fieldName, Double.valueOf(fieldValue));
					}
					else if (fieldType == Schema.DisplayType.Integer) {
						objToCreate.put(fieldName, Integer.valueOf(fieldValue));
					}
					else if (fieldType == Schema.DisplayType.Date) {
						objToCreate.put(fieldName, Date.valueOf(fieldValue));	
					}
					else if (fieldType == Schema.DisplayType.DateTime) {
						objToCreate.put(fieldName, DateTime.valueOf(fieldValue));
					}
					else {
						if(!(this.objectType.getDescribe().getName() == 'User' && fieldName == 'Name')){
							objToCreate.put(fieldName, fieldValue);	
						}
					}

					if(fieldName.equalsIgnoreCase('External_Id__c')){
						lstExternalIds.add(fieldValue);
					}
				}
			}

			objectsBatch.add(objToCreate);
		}

		if(objectsBatch.size() > 0) {
			
			// We must determine which objects to insert, and which to update
			String genQuery = 'SELECT Id, External_Id__c FROM ' + this.objectType.getDescribe().getName() + ' WHERE External_Id__c IN :lstExternalIds';
	        List<SObject> alreadyThere = Database.query(genQuery);
	        Map<String, String> sfIdsByExternalId = new Map<String, String>();
	        
	        for(SObject sObj: alreadyThere) {
	        	sfIdsByExternalId.put(String.valueOf(sObj.get('External_Id__c')), String.valueOf(sObj.get('Id')));
	        }

	        List<SObject> lstToInsert = new List<SObject>();
	        List<SObject> lstToUpdate = new List<SObject>();

	        for(SObject sObj: objectsBatch) {
	        	if(sfIdsByExternalId.containsKey(String.valueOf(sObj.get('External_Id__c')))){
	        		sObj.put('Id', sfIdsByExternalId.get(String.valueOf(sObj.get('External_Id__c'))));
	        		lstToUpdate.add(sObj);
	        	}
	        	else {
	        		lstToInsert.add(sObj);
	        	}
	        }

	        System.debug(lstToInsert.size() + ' objects to insert.');
	        System.debug(lstToUpdate.size() + ' objects to update.');

	        // DML
	        update lstToUpdate;
			insert lstToInsert;
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}

	// Prepares fields like UserRole.Name and Profile.Name
	private void prepareNameSmartLookups(){
		
    	this.nameSmartLookups = new List<SmartLookup>();

    	for(Integer columnNumber: this.fieldPositions.keySet()) {
    		String headerValue = this.fieldPositions.get(columnNumber);
    		if (headerValue.endsWith('.Name')) {
            	this.nameSmartLookups.add(new SmartLookup(columnNumber, headerValue.remove('.Name')));                	
        	}
    	}

    	for(Integer columnNumber: this.fieldPositions.keySet()) {
    		//System.debug(this.fieldPositions.get(columnNumber));
    		String headerValue = this.fieldPositions.get(columnNumber);
    		if (headerValue.endsWith('.Name')) {
            	// Replace column headers with .Id
            	headerValue = headerValue.replace('.Name', 'Id');
            	this.fieldPositions.put(columnNumber, headerValue);
        	}
    	}
	}
	
	// Handles fields like UserRole.Name and Profile.Name - replace values in parsed CSV with ID Equivalent.	
	// Get eligible fields and their respective column numbers
	private void smartLookupNameToId(List<List<String>> scope){
	
		if(scope != null) {		

        	// Get all possible unique values to be replaced with IDs
	        for (SmartLookup smLookUp : this.nameSmartLookups) {
	            for (List<String> row : scope) {
	                smLookUp.plainTextValues.add(row[smLookUp.columnNumber]);
	            }
	        }

	        // Get mapping of id to name, and add to lookup object
	        for (SmartLookup s : this.nameSmartLookups) {

	        	System.debug('Handling smart lookups Name To Id for objects of type: ' + s.SObjectType + '.');
	            
	            List<String> relevantValues = new List<String>(s.plainTextValues);
				String generatedQuery = 'SELECT Id, Name FROM ' + s.SObjectType + ' WHERE Name IN :relevantValues';
	            List<SObject> temp = Database.query(generatedQuery);
	            
	            for (SObject t: temp) {
	                s.replaceValues.put(String.valueOf(t.get('Name')), String.valueOf(t.get('Id')));
	            }

	            // Search whether there are names with not found id
	            for(String relVal: relevantValues) {
	            	if(!s.replaceValues.containsKey(relVal)){
	            		// Log Ids that weren't found for the name
	            		System.debug(String.format('Id not found for name {0}, SObject: {1}. This may cause an exception.', new String[]{ relVal, s.SObjectType }));
	            	}
	            	else {
						System.debug('Id for ' + relVal + ': ' + s.replaceValues.get(relVal));
	            	}
	            }	            
	        }
	        
	        // Replace name values with Id equivalent
	        for (List<String> row : scope) {
	            for (SmartLookup s: this.nameSmartLookups) {
	            	row[s.ColumnNumber] = s.replaceValues.get(row[s.ColumnNumber]);
	            }
	        }
		}
	}

	// Handles fields like Case.External_Id__c and Owner.External_Id__c
	private void prepareExternalIdSmartLookups(){

		this.externalIdSmartLookups = new List<SmartLookup>();

    	for(Integer columnNumber: this.fieldPositions.keySet()) {
    		String headerValue = this.fieldPositions.get(columnNumber);
    		if (headerValue.endsWithIgnoreCase('.External_Id__c')) {
            	this.externalIdSmartLookups.add(new SmartLookup(columnNumber, headerValue.removeEndIgnoreCase('.External_Id__c')));
        	}
    	}

    	for(Integer columnNumber: this.fieldPositions.keySet()) {
    		//System.debug(this.fieldPositions.get(columnNumber));
    		String headerValue = this.fieldPositions.get(columnNumber);
    		if (headerValue.endsWithIgnoreCase('.External_Id__c')) {
            	// Replace column headers with .Id
            	headerValue = headerValue.replace('.External_Id__c', 'Id');
            	this.fieldPositions.put(columnNumber, headerValue);
        	}
    	}
	}

	private void smartLookupExternalId(List<List<String>> scope){
		
		if(scope != null) {

        	// Get all possible unique values to be replaced with IDs
	        for (SmartLookup smLookUp : this.externalIdSmartLookups) {
	            for (List<String> row : scope) {
	                smLookUp.plainTextValues.add(row[smLookUp.columnNumber]);
	            }
	        }

	        // Get mapping of id to name, and add to lookup object
	        for (SmartLookup s : this.externalIdSmartLookups) {	        	
	            
	            List<String> relevantValues = new List<String>(s.plainTextValues);
	            String sObjToQuery = s.SObjectType;
	            if(sObjToQuery == 'Owner'){
	            	sObjToQuery = 'User';
	            }

	            System.debug('Handling smart lookups External_Id__c To Id for objects of type: ' + sObjToQuery + '.');

				String generatedQuery = 'SELECT Id, External_Id__c FROM ' + sObjToQuery + ' WHERE External_Id__c IN :relevantValues';
	            List<SObject> temp = Database.query(generatedQuery);
	            
	            for (SObject t: temp) {
	                s.replaceValues.put(String.valueOf(t.get('External_Id__c')), String.valueOf(t.get('Id')));
	            }

	            // Search whether there are Extenal_Id__c with not found id
	            for(String relVal: relevantValues) {
	            	if(!s.replaceValues.containsKey(relVal)){
	            		// Log Ids that weren't found for the name
	            		System.debug(String.format('Id not found for External_Id__c {0}, SObject: {1}. This may cause an exception.', new String[]{ relVal, sObjToQuery }));
	            	}
	            	else {
	            		System.debug('Id for ' + relVal + ': ' + s.replaceValues.get(relVal));
	            	}
	            }
	        }
	        
	        // Replace name values with Id equivalent
	        for (List<String> row : scope) {
	            for (SmartLookup s: this.externalIdSmartLookups) {
	            	row[s.ColumnNumber] = s.replaceValues.get(row[s.ColumnNumber]);
	            }
	        }
		}
	}
}
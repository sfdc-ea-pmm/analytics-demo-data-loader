public abstract class DataflowDefinitionEditor {
	
	protected Id relevantDataflowId;
	protected Map<String, Object> dataflowDefinitionObject;

	public abstract void processDataflowNodes(Integer numberOfMonths);
	public abstract List<String> validateEdition();

	public void processEdition(String newDataflowName, String newDataflowLabel, Integer numberOfMonths){

		// Rely on subclasses implementation
		this.processDataflowNodes(numberOfMonths);

		Id dataflowId;
		Dataflow ndf = null;
		Dataflow sourceDataflow = [SELECT FolderId, State FROM Dataflow WHERE Id = :this.relevantDataflowId];

		// 1) Check if the dataset exists
		Dataflow[] lstDataflows = [SELECT FolderId, State, DeveloperName, MasterLabel, CurrentId FROM Dataflow WHERE DeveloperName = :newDataflowName];
		if(lstDataflows.size() == 0){
			
			// Attemp to create new Dataflow object
			ndf = new Dataflow();
			ndf.DeveloperName = newDataflowName;
			ndf.MasterLabel = newDataflowLabel;
			ndf.State = sourceDataflow.State;
			ndf.FolderId = sourceDataflow.FolderId;
			ndf.DataflowType = 'User';
			
			RestApiResponseBody createResult = this.insertDataflow(JSON.serialize(ndf));
			if(createResult.success){
				dataflowId = createResult.id;
				System.debug(String.format('Dataflow {0} successfully created. Id: {1}.', new String[]{ newDataflowLabel, dataflowId }));
			}
			else {
				System.debug(String.format('Dataflow {0} couldn\'t be created.', new String[]{newDataflowLabel}));
			}
		}
		else {
			ndf = lstDataflows[0];
			dataflowId = ndf.Id;
			ndf.DeveloperName = newDataflowName;
			ndf.MasterLabel = newDataflowLabel;
			ndf.CurrentId = this.relevantDataflowId;
		}

		if(!String.isBlank(dataflowId)){
			String newDataflowDefinition = JSON.serialize(this.dataflowDefinitionObject);
			DataflowVersion newDataflowVersion = new DataflowVersion();	
			newDataflowVersion.DataflowId = dataflowId;
			newDataflowVersion.DataflowDefinition = newDataflowDefinition;
			RestApiResponseBody versionResult = insertDataflowVersion(JSON.serialize(newDataflowVersion));
			
			if(versionResult.success){
				ndf.CurrentId = versionResult.id;
				System.debug(String.format('Dataflow version successfully created. Id: {1}.', new String[]{ newDataflowLabel, ndf.CurrentId }));
			}
			else {
				System.debug(String.format('Couldn\'t create version for Dataflow {0}.', new String[]{newDataflowLabel}));
			}
			
			this.updateDataflow(dataflowId, ndf);
		}
	}

	// Edit an Extract node
	public void editExtractNode (String nodeName, String srcObject, String complexFilterConditions, String fieldDefnJSON, String schemaJSON) {

		// Node name must exist
		if(this.dataflowDefinitionObject.containsKey(nodeName)){
			
			Map<String, Object> node = (Map<String, Object>)this.dataflowDefinitionObject.get(nodeName);
			
			// If parameters exist
			if(node.containsKey('parameters')) {
				Map<String, Object> nodeParams = (Map<String, Object>)node.get('parameters');

				if(!String.isBlank(fieldDefnJSON)){
					// Deserialize the field definition json
					Object o = JSON.deserializeUntyped(fieldDefnJSON);
					nodeParams.put('fields', o);
				}
				
				if(!String.isBlank(srcObject)) {
					nodeParams.put('object', srcObject);
				}
				
				if(!String.isBlank(complexFilterConditions)){
					nodeParams.put('complexFilterConditions', complexFilterConditions);
				}

				node.put('parameters', nodeParams);
			}

			// If schema exist
			if(node.containsKey('schema') && !String.isBlank(schemaJSON)) {
				// Deserialize the field definition json
				Object oSchema = JSON.deserializeUntyped(schemaJSON);
				node.put('schema', oSchema);
			}

			// Overwrite the node
			dataflowDefinitionObject.put(nodeName, node);
		}		
	}

	// Edit a computeRelative node
	public void editComputeRelativeNode (String nodeName, String sourceNode, String partitionField, String orderByField, String orderType, String compFieldsDefnJSON) {

		// Node name must exist
		if(this.dataflowDefinitionObject.containsKey(nodeName)){

			Map<String, Object> node = (Map<String, Object>)this.dataflowDefinitionObject.get(nodeName);
			
			// If parameters exist
			if(node.containsKey('parameters')) {
				
				Map<String, Object> nodeParams = (Map<String, Object>)node.get('parameters');

				if(!String.isBlank(sourceNode)){
					nodeParams.put('source', sourceNode);
				}

				if(!String.isBlank(orderByField) && !String.isBlank(orderType)){
					String orderByJson = '[{ "name": "' + orderByField + '", "direction": "' + orderType + '" } ]';
					Object orderBy = JSON.deserializeUntyped(orderByJson);
					nodeParams.put('orderBy', orderBy);
				}
				
				if(!String.isBlank(compFieldsDefnJSON)) {
					Object computedFields = JSON.deserializeUntyped(compFieldsDefnJSON);
					nodeParams.put('computedFields', computedFields);
				}

				if(!String.isBlank(partitionField)) {
					String partitionByJson = '["' + partitionField + '"]';
					Object partitionBy = JSON.deserializeUntyped(partitionByJson);
					nodeParams.put('partitionBy', partitionBy);
				}

				node.put('parameters', nodeParams);
			}

			this.dataflowDefinitionObject.put(nodeName, node);
		}		
	}

	// Edit a computeRelative node
	public void editComputeExpressionNode (String nodeName, String sourceNode, Boolean mergeWithSource, String compFieldsDefnJSON) {

		// Node name must exist
		if(this.dataflowDefinitionObject.containsKey(nodeName)) {
			
			Map<String, Object> node = (Map<String, Object>)this.dataflowDefinitionObject.get(nodeName);
			
			// If parameters exist
			if(node.containsKey('parameters')) {

				Map<String, Object> nodeParams = (Map<String, Object>)node.get('parameters');
				
				nodeParams.put('mergeWithSource', mergeWithSource);

				if(!String.isBlank(sourceNode)){
					nodeParams.put('source', sourceNode);
				}
				
				if(!String.isBlank(compFieldsDefnJSON)) {
					Object computedFields = JSON.deserializeUntyped(compFieldsDefnJSON);
					nodeParams.put('computedFields', computedFields);
				}
				
				node.put('parameters', nodeParams);				
			}

			this.dataflowDefinitionObject.put(nodeName, node);
		}
	}

	// Adds a new node to the dataflow definition
	public void appendNode(String nodeNameToAppend, String nodeJson) {
		Object o = JSON.deserializeUntyped(nodeJson);
		this.dataflowDefinitionObject.put(nodeNameToAppend, o);
	}

	// Edits an augment transformation node
	public void editAugmentNode(String nodeName, String leftSide, String leftKey, String rightSide, String rightKey, String relationshipName, List<String> righSelectFields) {

		Map<String, Object> node = (Map<String, Object>)this.dataflowDefinitionObject.get(nodeName);
		Map<String, Object> nodeParams = (Map<String, Object>)node.get('parameters');

		// Must be comma separated list of keys
		if(String.isNotBlank(leftKey)){
			nodeParams.put('left_key', leftKey);
		}

		if(String.isNotBlank(leftSide)){
			nodeParams.put('left', leftSide);
		}
		
		// Must be comma separated list of keys
		if(String.isNotBlank(rightKey)) {
			nodeParams.put('right_key', rightKey);	
		}

		if(String.isNotBlank(rightSide)) {
			nodeParams.put('right', rightSide);	
		}

		if(String.isNotBlank(relationshipName)) {
			nodeParams.put('relationship', relationshipName);	
		}

		// Must be list of field names
		if(righSelectFields != null && righSelectFields.size() > 0){
			nodeParams.put('right_select', JSON.serialize(righSelectFields));
		}
		
		node.put('parameters', nodeParams);
		this.dataflowDefinitionObject.put(nodeName, node);
	}

	// This method invokes the SFDC REST API for creating a DataflowVersion object
	public RestApiResponseBody insertDataflowVersion(String jsonToPost) {

		Http http = new Http();
		HttpRequest req = new HttpRequest();

		String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
		String url =  salesforceHost + '/services/data/v37.0/sobjects/DataflowVersion';

		req.setMethod('POST');
		req.setEndpoint(url);
		req.setHeader('Content-type', 'application/json');
		req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
		req.setBody(jsonToPost);

		HTTPResponse res = http.send(req);
		
		String resBody = res.getBody();
		return (RestApiResponseBody)JSON.deserialize(resBody, RestApiResponseBody.class);
	}

	// This method invokes the SFDC REST API for creating a Dataflow object
	public RestApiResponseBody insertDataflow(String jsonToPost) {

		Http http = new Http();
		HttpRequest req = new HttpRequest();

		String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
		String url =  salesforceHost + '/services/data/v37.0/sobjects/Dataflow';

		req.setMethod('POST');
		req.setEndpoint(url);
		req.setHeader('Content-type', 'application/json');
		req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
		req.setBody(jsonToPost);
		
		HTTPResponse res = http.send(req);
		
		return (RestApiResponseBody)JSON.deserialize(res.getBody(), RestApiResponseBody.class);
	}

	// This method invokes the SFDC REST API for updating a Dataflow object
	public void updateDataflow(Id dataflowId, Dataflow dataflowObj) {

		Http http = new Http();
		HttpRequest req = new HttpRequest();

		String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
		String url = salesforceHost + '/services/data/v37.0/sobjects/Dataflow/' + dataflowId + '?_HttpMethod=PATCH';

		req.setMethod('POST');
		req.setEndpoint(url);
		req.setHeader('Content-type', 'application/json');
		req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());

		Dataflow dfClone = dataflowObj.clone(false);
		String jsonToPost = JSON.serialize(dfClone);
		req.setBody(jsonToPost);

		HTTPResponse res = http.send(req);
		
		System.debug('updateDataflow response: ');
		System.debug(res);
	}
	
	public String zipJSON () {
		return JSON.serialize(this.dataflowDefinitionObject);
	}

	public static Map<String, Object> dataflowContentsAsJSON (String dfId) {
		return (Map<String, Object>)JSON.deserializeUntyped(
           [SELECT DataflowDefinition FROM DataflowVersion WHERE DataflowId = : dfId ORDER BY CreatedDate DESC LIMIT 1].DataflowDefinition
       );
	}
}
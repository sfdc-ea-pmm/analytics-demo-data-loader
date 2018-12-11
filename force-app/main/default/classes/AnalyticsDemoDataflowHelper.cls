public with sharing class AnalyticsDemoDataflowHelper {
    
    private String apiVersion;

    public AnalyticsDemoDataflowHelper(String apiVersion){
        this.apiVersion = String.isBlank(apiVersion) ? 'v43.0' : apiVersion;
    }

    public void replaceSfdcDigestByEdgemarts(String dataflowID, List<WaveApplicationEdgemart> edgemartsConfigurations){
        
        Map<String, Object> dataflowDefinitionObject = AnalyticsDemoDataflowHelper.dataflowContentsAsJSON(dataflowID);
        Map<String, String> digestNodes = new Map<String, String>();
        Map<String, String> replaceNodesMap = new Map<String, String>();
        List<String> lstObjectNamesToHandle = new List<String>();

        for (WaveApplicationEdgemart wae : edgemartsConfigurations) {
            lstObjectNamesToHandle.add(wae.objectName);
        }

        // With this for loop we search which are the sfdcDigest nodes and from which object they extract
        for (String nodeName : dataflowDefinitionObject.keySet()) {
            Map<String, Object> node = (Map<String, Object>)dataflowDefinitionObject.get(nodeName);
            // If parameters exist
            if(node.containsKey('action')) {
                String action = (String)node.get('action');
                if (action.equals('sfdcDigest')) {
                    if(node.containsKey('parameters')) {
                        Map<String, Object> nodeParams = (Map<String, Object>)node.get('parameters');
                        String objName = (String)nodeParams.get('object');
                        if (lstObjectNamesToHandle.contains(objName)) {
                            if(digestNodes.containsKey(objName)){
                                throw new WaveConfiguratorException('Cannot edit dataflow because cannot replace sfdcDigest by edgemart transformation. ' + objName + ' object is being extracted more than once in the dataflow.');
                            }
                            digestNodes.put(objName, nodeName);
                        }                        
                    }
                }
            }
        }

        for (WaveApplicationEdgemart wae : edgemartsConfigurations) {
            
            // Add each edgemart node
            String nodeJson = '{"action": "edgemart","parameters": { "alias": "' + wae.edgemartDeveloperName + '" }}';
            Object o = JSON.deserializeUntyped(nodeJson);
            dataflowDefinitionObject.put(wae.edgemartNodeNameInDataflow, o);
            replaceNodesMap.put(digestNodes.get(wae.objectName), wae.edgemartNodeNameInDataflow);
        }

        // Key: Node Name
        // Value: List of node names that depend on the node named by Key 
        Map<String, List<String>> dependencyMap = new Map<String, List<String>>();
        for (String tdn : digestNodes.values()) {
            dependencyMap.put(tdn, new List<String>());
        }

        // With this for loop we search which nodes are dependent of our sfdcDigests
        for (String nodeName : dataflowDefinitionObject.keySet()) {
            Map<String, Object> node = (Map<String, Object>)dataflowDefinitionObject.get(nodeName);
            // If parameters exist
            if(node.containsKey('action')) {
                
                String action = (String)node.get('action');
                
                // We don't want root type transformations, those without source transformation/s
                if (!(action.equals('sfdcDigest') || action.equals('digest') || action.equals('edgemart'))) {
                    if(node.containsKey('parameters')) {
                        Map<String, Object> nodeParams = (Map<String, Object>)node.get('parameters');
                        switch on action {
                            when 'append' {
                                List<String> sources = (List<String>)nodeParams.get('sources');
                                for (String sourceTransf: sources) {
                                    if (digestNodes.values().contains(sourceTransf)) {
                                        dependencyMap.get(sourceTransf).add(nodeName);
                                    }
                                }
                            }
                            when 'augment', 'update' {
                                String left = (String)nodeParams.get('left');
                                String right = (String)nodeParams.get('right');
                                
                                if (digestNodes.values().contains(left)) {
                                    dependencyMap.get(left).add(nodeName);
                                }

                                if (digestNodes.values().contains(right)) {
                                    dependencyMap.get(right).add(nodeName);
                                }
                            }
                            when else {
                                String source = (String)nodeParams.get('source');
                                if (digestNodes.values().contains(source)) {
                                    dependencyMap.get(source).add(nodeName);
                                }
                            }
                        }
                    }
                }
            }
        }
        
        for (String s: dependencyMap.keySet()) {
            List<String> ls = dependencyMap.get(s);
            System.debug('Transformations that depend of: ' + s);
            System.debug(ls);
        }

        for (String nodeName : digestNodes.values()) {
            
            List<String> nodesToEdit = dependencyMap.get(nodeName);
            
            for (String nodeToEditName: nodesToEdit) {
                Map<String, Object> nodeToEdit = (Map<String, Object>)dataflowDefinitionObject.get(nodeToEditName);
                String action = (String)nodeToEdit.get('action');
                Map<String, Object> nodeParams = (Map<String, Object>)nodeToEdit.get('parameters');
                switch on action {
                    when 'append' {
                        List<String> sources = (List<String>)nodeParams.get('sources');
                        sources.remove(sources.indexOf(nodeName));
                        sources.add(replaceNodesMap.get(nodeName));
                    }
                    when 'augment', 'update' {
                        String left = (String)nodeParams.get('left');
                        String right = (String)nodeParams.get('right');
                        
                        if (left.equals(nodeName)) {
                            nodeParams.put('left', replaceNodesMap.get(nodeName));
                        }

                        if (right.equals(nodeName)) {
                            nodeParams.put('right', replaceNodesMap.get(nodeName));
                        }
                    }
                    when else {
                        String source = (String)nodeParams.get('source');
                        if (source.equals(nodeName)) {
                            nodeParams.put('source', replaceNodesMap.get(nodeName));
                        }
                    }
                }
            }
        }

        String newDataflowDefinition = JSON.serialize(dataflowDefinitionObject);
        DataflowVersion newDataflowVersion = new DataflowVersion();
        newDataflowVersion.DataflowId = dataflowID;
        newDataflowVersion.DataflowDefinition = newDataflowDefinition;
        RestApiResponseBody versionResult = insertDataflowVersion(JSON.serialize(newDataflowVersion));
        
        if(versionResult.success){
            Dataflow df = [SELECT Id, CurrentId FROM Dataflow WHERE Id = :dataflowID];
            df.CurrentId = versionResult.id;
            this.updateDataflow(dataflowID, df);
        }
    }

    public static Map<String, Object> dataflowContentsAsJSON (String dfId) {
        return (Map<String, Object>)JSON.deserializeUntyped(
           [SELECT DataflowDefinition FROM DataflowVersion WHERE DataflowId = : dfId ORDER BY CreatedDate DESC LIMIT 1].DataflowDefinition
       );
    }

    // This method invokes the SFDC REST API for updating a Dataflow object
    public void updateDataflow(Id dataflowId, Dataflow dataflowObj) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
        String url = salesforceHost + '/services/data/' + this.apiVersion + '/sobjects/Dataflow/' + dataflowId + '?_HttpMethod=PATCH';
        req.setMethod('POST');
        req.setEndpoint(url);
        req.setHeader('Content-type', 'application/json');
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        Dataflow dfClone = dataflowObj.clone(false);
        String jsonToPost = JSON.serialize(dfClone);
        req.setBody(jsonToPost);
        HTTPResponse res = http.send(req);
    }

    // This method invokes the SFDC REST API for creating a DataflowVersion object
    public RestApiResponseBody insertDataflowVersion(String jsonToPost) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
        String url =  salesforceHost + '/services/data/' + this.apiVersion + '/sobjects/DataflowVersion';
        req.setMethod('POST');
        req.setEndpoint(url);
        req.setHeader('Content-type', 'application/json');
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setBody(jsonToPost);
        HTTPResponse res = http.send(req);
        String resBody = res.getBody();
        return (RestApiResponseBody)JSON.deserialize(resBody, RestApiResponseBody.class);
    }
}

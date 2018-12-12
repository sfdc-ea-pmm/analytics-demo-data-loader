public with sharing class AnalyticsDemoDataflowHelper {
    
    private String apiVersion;

    public AnalyticsDemoDataflowHelper(String apiVersion){
        this.apiVersion = String.isBlank(apiVersion) ? 'v43.0' : apiVersion;
    }

    public void replaceSfdcDigestByEdgemarts(String dataflowID, List<WaveApplicationEdgemart> edgemartsConfigurations){
        
        Map<String, Object> dataflowDefinitionObject = AnalyticsDemoDataflowHelper.dataflowContentsAsJSON(dataflowID);
        ReplaceSfdcDigestByEdgemartsGeneric replaceStrategyObj = new ReplaceSfdcDigestByEdgemartsGeneric();
        dataflowDefinitionObject = replaceStrategyObj.doReplacement(dataflowDefinitionObject, edgemartsConfigurations);

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

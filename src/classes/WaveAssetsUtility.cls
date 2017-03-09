public with sharing class WaveAssetsUtility {
	
    public class Response {
        public Boolean success;
        public List<String> messagesList;
    }

	public WaveAssetsUtility() {
		
	}

	// Extracts all the assets and dump that data into a wave dataset 
    // @param datasetName The name of the dataset to create/overwrite
    public static Response extractAssetsAndBuildDataset(String datasetName){

        Response response = new Response();
        response.success = true;
        response.messagesList = new List<String>();

        // Validation of the dataset name
        if(datasetName.endsWithIgnoreCase('__c')) {
            response.success = false;
            response.messagesList.add('The dataset name must not end with "__c".');
        }
        else if(datasetName.length() > 80) {
            response.success = false;
            response.messagesList.add('The dataset name can be up to 80 characters length.');
        }
        else {    
            Pattern dsnPattern = Pattern.compile('[a-zA-z][_a-zA-z0-9]*');
            Matcher dsnMatcher = dsnPattern.matcher(datasetName);
            
            if(!dsnMatcher.matches()){
                response.success = false;
                response.messagesList.add('The dataset name must start with an alpha character, optionally followed by any alphanumeric characters and underscores.');
            }
            else {
                try {
                    // WaveAsset general collection
                    List<WaveAsset> waveAssets = new List<WaveAsset>();
                    
                    // Extract assets data from REST API - JSON format
                    // Folders
                    String jsonFolders = WaveRestApiUtils.getWaveAssetsJSON('folders', null);
                    WaveFoldersAssetsResponse foldersResponse = (WaveFoldersAssetsResponse)JSON.deserialize(jsonFolders, WaveFoldersAssetsResponse.class);
                    
                    while(foldersResponse != null && foldersResponse.folders != null){
                        
                        for(WaveFolderAsset folder : foldersResponse.folders){
                            waveAssets.add(folder);
                        }

                        if(foldersResponse.nextPageUrl != null){
                            jsonFolders = WaveRestApiUtils.getWaveAssetsJSON('folders', foldersResponse.nextPageUrl);
                            foldersResponse = (WaveFoldersAssetsResponse)JSON.deserialize(jsonFolders, WaveFoldersAssetsResponse.class);
                        }
                        else {
                            foldersResponse = null;
                        }
                    }

                    // Datasets
                    String jsonDatasets = WaveRestApiUtils.getWaveAssetsJSON('datasets', null);
                    WaveDatasetsResponse datasetsResponse = (WaveDatasetsResponse)JSON.deserialize(jsonDatasets, WaveDatasetsResponse.class);
                    
                    while(datasetsResponse != null && datasetsResponse.datasets != null){
                        
                        for(WaveDataset dataset : datasetsResponse.datasets){
                            waveAssets.add(dataset);
                        }

                        if(datasetsResponse.nextPageUrl != null){
                            jsonDatasets = WaveRestApiUtils.getWaveAssetsJSON('datasets', datasetsResponse.nextPageUrl);
                            datasetsResponse = (WaveDatasetsResponse)JSON.deserialize(jsonDatasets, WaveDatasetsResponse.class);
                        }
                        else {
                            datasetsResponse = null;
                        }
                    }

                    // Lenses
                    String jsonLenses = WaveRestApiUtils.getWaveAssetsJSON('lenses', null);
                    WaveLensesResponse lensesResponse = (WaveLensesResponse)JSON.deserialize(jsonLenses, WaveLensesResponse.class);
                    
                    while(lensesResponse != null && lensesResponse.lenses != null){
                        
                        for(WaveLens lens : lensesResponse.lenses){
                            waveAssets.add(lens);
                        }

                        if(lensesResponse.nextPageUrl != null){
                            jsonLenses = WaveRestApiUtils.getWaveAssetsJSON('lenses', lensesResponse.nextPageUrl);
                            lensesResponse = (WaveLensesResponse)JSON.deserialize(jsonLenses, WaveLensesResponse.class);
                        }
                        else {
                            lensesResponse = null;
                        }
                    }

                    // Dashboards
                    String jsonDashboards = WaveRestApiUtils.getWaveAssetsJSON('dashboards', null);
                    WaveDashboardsResponse dashboardsResponse = (WaveDashboardsResponse)JSON.deserialize(jsonDashboards, WaveDashboardsResponse.class);
                    
                    while(dashboardsResponse != null && dashboardsResponse.dashboards != null){
                        
                        for(WaveDashboard dashboard : dashboardsResponse.dashboards){
                            waveAssets.add(dashboard);
                        }

                        if(dashboardsResponse.nextPageUrl != null){
                            jsonDashboards = WaveRestApiUtils.getWaveAssetsJSON('dashboards', dashboardsResponse.nextPageUrl);
                            dashboardsResponse = (WaveDashboardsResponse)JSON.deserialize(jsonDashboards, WaveDashboardsResponse.class);
                        }
                        else {
                            dashboardsResponse = null;
                        }
                    }

                    // Generate header line of the CSV to upload
                    List<String> datasetLines = new String[]{'AssetType,Label,Name,CreatedDate,Id,LastModifiedDate,Url\n'};

                    // Folders
                    for(WaveAsset wAsset: waveAssets) {
                        datasetLines.add(String.format('{0},{1},{2},{3},{4},{5},{6}', new String[]{
                            wAsset.getAssetType(),
                            wAsset.label,
                            wAsset.name,
                            String.valueOf(wAsset.createdDate),
                            wAsset.id,
                            String.valueOf(wAsset.lastModifiedDate),
                            wAsset.url
                        }));
                    }

                    // Get the JSON from the Static Resource
                    StaticResource srJson = [SELECT Body FROM StaticResource WHERE Name = 'WaveAssetsSchemaJSON'];
                    System.debug('WaveAssetsSchemaJSON found.');

                    // Configure the Upload of the new Wave Dataset
                    InsightsExternalData iedObj = new InsightsExternalData();
                    iedObj.Format = 'Csv';
                    iedObj.EdgemartAlias = datasetName;
                    //iedObj.EdgemartContainer = 'SharedApp';
                    iedObj.Operation = 'Overwrite';
                    iedObj.Action = 'None';
                    iedObj.MetadataJson = EncodingUtil.base64Decode(EncodingUtil.base64Encode(srJson.Body));

                    insert iedObj;

                    // Add the Data
                    InsightsExternalDataPart dataPart = new InsightsExternalDataPart();
                    dataPart.InsightsExternalDataId = iedObj.Id;
                    dataPart.PartNumber = 1;
                    Blob csvBlob = Blob.valueof(String.join(datasetLines, '\n'));
                    Integer size = csvBlob.size();
                    dataPart.dataFile = csvBlob;
                    dataPart.DataLength = size;
                    
                    insert dataPart;

                    System.debug(String.format('Method WaveAssetsUtility.extractAssetsAndBuildDataset() finished successfully. InsightsExternalData Id: {0}, InsightsExternalDataPart Id: {1}.', new String[]{iedObj.Id, dataPart.Id}));

                    // Final Step: Manage the Upload
                    iedObj.Action = 'Process';
                    update iedObj;           
                } 
                catch(Exception e) {
                    response.success = false;
                    response.messagesList.add('Exception while executing method: ' + e.getMessage());
                    System.debug(e.getMessage());
                    System.debug(e.getStackTraceString());
                    System.debug(e.getTypeName());
                    System.debug(e.getCause());
                }
            }
        }        

        return response;
    }
}
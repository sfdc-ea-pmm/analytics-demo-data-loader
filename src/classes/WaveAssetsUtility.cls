public with sharing class WaveAssetsUtility {
	
	public WaveAssetsUtility() {
		
	}

	// Extracts all the assets and dump that data into a wave dataset 
    public static void extractAssetsAndBuildDataset(){
    	
    	// Extract assets data from REST API - JSON format
    	// Folders
    	List<WaveFolder> waveFolders = new List<WaveFolder>();
    	String jsonFolders = WaveRestApiUtils.getWaveAssetsJSON('folders', null);
    	WaveFoldersResponse foldersResponse = (WaveFoldersResponse)JSON.deserialize(jsonFolders, WaveFoldersResponse.class);
    	
    	while(foldersResponse != null && foldersResponse.folders != null){
    		
    		for(WaveFolder folder : foldersResponse.folders){
                waveFolders.add(folder);
            }

            if(foldersResponse.nextPageUrl != null){
            	jsonFolders = WaveRestApiUtils.getWaveAssetsJSON('folders', foldersResponse.nextPageUrl);
            	foldersResponse = (WaveFoldersResponse)JSON.deserialize(jsonFolders, WaveFoldersResponse.class);
            }
            else {
            	foldersResponse = null;
            }
    	}

    	// Datasets
    	List<WaveDataset> waveDatasets = new List<WaveDataset>();
    	String jsonDatasets = WaveRestApiUtils.getWaveAssetsJSON('datasets', null);
    	WaveDatasetsResponse datasetsResponse = (WaveDatasetsResponse)JSON.deserialize(jsonDatasets, WaveDatasetsResponse.class);
    	
    	while(datasetsResponse != null && datasetsResponse.datasets != null){
    		
    		for(WaveDataset dataset : datasetsResponse.datasets){
                waveDatasets.add(dataset);
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
    	List<WaveLens> waveLenses = new List<WaveLens>();
    	String jsonLenses = WaveRestApiUtils.getWaveAssetsJSON('lenses', null);
    	WaveLensesResponse lensesResponse = (WaveLensesResponse)JSON.deserialize(jsonLenses, WaveLensesResponse.class);
    	
    	while(lensesResponse != null && lensesResponse.lenses != null){
    		
    		for(WaveLens lens : lensesResponse.lenses){
                waveLenses.add(lens);
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
    	List<WaveDashboard> waveDashboards = new List<WaveDashboard>();
    	String jsonDashboards = WaveRestApiUtils.getWaveAssetsJSON('dashboards', null);
		WaveDashboardsResponse dashboardsResponse = (WaveDashboardsResponse)JSON.deserialize(jsonDashboards, WaveDashboardsResponse.class);
    	
    	while(dashboardsResponse != null && dashboardsResponse.dashboards != null){
    		
    		for(WaveDashboard dashboard : dashboardsResponse.dashboards){
                waveDashboards.add(dashboard);
            }

            if(dashboardsResponse.nextPageUrl != null){
            	jsonDashboards = WaveRestApiUtils.getWaveAssetsJSON('dashboards', dashboardsResponse.nextPageUrl);
            	dashboardsResponse = (WaveDashboardsResponse)JSON.deserialize(jsonDashboards, WaveDashboardsResponse.class);
            }
            else {
            	dashboardsResponse = null;
            }
    	}

    	// See SalesWaveQuotas to manage the upload
    }
}
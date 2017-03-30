public abstract class WaveAsset {
	public Datetime createdDate;
	public String id;
	public String label;
	public Datetime lastModifiedDate;
	public String name;
	public String url;

	public abstract String getAssetType();
}
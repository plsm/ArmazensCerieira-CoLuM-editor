package colum.db;

/**
 * Represent an entity that has a RFID tag.
 *
 * @author pedro
 * @date 22/jan/2019
 */
abstract public class Tagable
{
	public long RFID;

	protected Tagable (long RFID)
	{
		this.RFID = RFID;
	}
}

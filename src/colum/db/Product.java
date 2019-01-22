package colum.db;

/**
 * Represents a product to lubricate machine parts.
 *
 * @author pedro
 * @date 20/jan/2019
 */
public class Product
  extends Tagable
  implements Keyable
{
	public long ID;
	public String name;
	public double density;
	/**
	 * Create an instance of a product to lubricate machine parts.
	 * @param ID the primary key in the {@code produto} table.
	 * @param name the name of this product.
	 * @param density the density of this product.
	 * @param RFID the RFID tag of this product.
	 */
	Product (long ID, String name, double density, long RFID)
	{
		super (RFID);
		this.ID = ID;
		this.name = name;
		this.density = density;
	}

	@Override
	public long getKey ()
	{
		return this.ID;
	}

	@Override
	public String toString ()
	{
		return String.format ("%d %s %f %d", this.ID, this.name, this.density, this.RFID);
	}
}

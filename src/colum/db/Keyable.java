package colum.db;

/**
 * Provides a method to return the primary key of an object that represents a
 * table record.
 *
 * @author pedro
 */
public interface Keyable
{
	/**
	 * Get the primary key of an object.
	 * @return the primary key of an object.
	 */
	long getKey ();
}

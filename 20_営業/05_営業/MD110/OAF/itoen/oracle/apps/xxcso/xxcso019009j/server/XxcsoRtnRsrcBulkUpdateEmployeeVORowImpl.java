/*============================================================================
* t@C¼ : XxcsoRtnRsrcBulkUpdateEmployeeVORowImpl
* Tvà¾   : _àScÆõpr[sNX
* o[W : 1.0
*============================================================================
* C³ð
* út       Ver. SÒ       C³àe
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCSxöaî    VKì¬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * _àScÆõÌr[sNXÅ·B
 * @author  SCSxöaî
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateEmployeeVORowImpl extends OAViewRowImpl 
{







  protected static final int FULLNAME = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateEmployeeVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FullName
   */
  public String getFullName()
  {
    return (String)getAttributeInternal(FULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FullName
   */
  public void setFullName(String value)
  {
    setAttributeInternal(FULLNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case FULLNAME:
        return getFullName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case FULLNAME:
        setFullName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
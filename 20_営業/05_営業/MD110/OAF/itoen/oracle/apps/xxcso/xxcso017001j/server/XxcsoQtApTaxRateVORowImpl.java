/*============================================================================
* t@C¼ : XxcsoQtApTaxRateVOImpl
* Tvà¾   : ¼¥Å¦æ¾pr[sNX
* o[W : 1.0
*============================================================================
* C³ð
* út       Ver. SÒ       C³àe
* ---------- ---- ------------ ----------------------------------------------
* 2011-05-17 1.0  SCSË¶aK  VKì¬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * ¼¥Å¦æ¾Ìr[sNXÅ·B
 * @author  SCSË¶aK
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQtApTaxRateVORowImpl extends OAViewRowImpl 
{

  protected static final int APTAXRATE = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQtApTaxRateVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApTaxRate
   */
  public Number getApTaxRate()
  {
    return (Number)getAttributeInternal(APTAXRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApTaxRate
   */
  public void setApTaxRate(Number value)
  {
    setAttributeInternal(APTAXRATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APTAXRATE:
        return getApTaxRate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APTAXRATE:
        setApTaxRate((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
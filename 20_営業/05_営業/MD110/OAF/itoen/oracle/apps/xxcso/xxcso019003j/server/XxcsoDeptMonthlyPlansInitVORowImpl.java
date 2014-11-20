/*============================================================================
* �t�@�C���� : XxcsoDeptMonthlyPlansInitVORowImpl
* �T�v����   : �������p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS�y���  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;
/*******************************************************************************
 * �������������邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoDeptMonthlyPlansInitVORowImpl extends OAViewRowImpl 
{
  protected static final int WORKBASECODE = 0;


  protected static final int WORKBASENAME = 1;
  protected static final int CURRENTDATE = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoDeptMonthlyPlansInitVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WorkBaseCode
   */
  public String getWorkBaseCode()
  {
    return (String)getAttributeInternal(WORKBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkBaseCode
   */
  public void setWorkBaseCode(String value)
  {
    setAttributeInternal(WORKBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WorkBaseName
   */
  public String getWorkBaseName()
  {
    return (String)getAttributeInternal(WORKBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkBaseName
   */
  public void setWorkBaseName(String value)
  {
    setAttributeInternal(WORKBASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CurrentDate
   */
  public Date getCurrentDate()
  {
    return (Date)getAttributeInternal(CURRENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CurrentDate
   */
  public void setCurrentDate(Date value)
  {
    setAttributeInternal(CURRENTDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case WORKBASECODE:
        return getWorkBaseCode();
      case WORKBASENAME:
        return getWorkBaseName();
      case CURRENTDATE:
        return getCurrentDate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case WORKBASECODE:
        setWorkBaseCode((String)value);
        return;
      case WORKBASENAME:
        setWorkBaseName((String)value);
        return;
      case CURRENTDATE:
        setCurrentDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
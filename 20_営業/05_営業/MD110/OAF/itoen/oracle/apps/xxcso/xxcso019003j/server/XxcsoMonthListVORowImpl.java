/*============================================================================
* �t�@�C���� : XxcsoMonthListVORowImpl
* �T�v����   : ���X�g�i���j�p�r���[�s�N���X
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
/*******************************************************************************
 * ���X�g�i���j���쐬���邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoMonthListVORowImpl extends OAViewRowImpl 
{
  protected static final int MONTHDATE = 0;


  protected static final int MONTHNAME = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoMonthListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MonthDate
   */
  public String getMonthDate()
  {
    return (String)getAttributeInternal(MONTHDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MonthDate
   */
  public void setMonthDate(String value)
  {
    setAttributeInternal(MONTHDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MonthName
   */
  public String getMonthName()
  {
    return (String)getAttributeInternal(MONTHNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MonthName
   */
  public void setMonthName(String value)
  {
    setAttributeInternal(MONTHNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case MONTHDATE:
        return getMonthDate();
      case MONTHNAME:
        return getMonthName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case MONTHDATE:
        setMonthDate((String)value);
        return;
      case MONTHNAME:
        setMonthName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
/*============================================================================
* �t�@�C���� : XxcsoYearListVORowImpl
* �T�v����   : ���X�g�i�N�j�p�r���[�s�N���X
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
 * ���X�g�i�N�j���쐬���邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoYearListVORowImpl extends OAViewRowImpl 
{
  protected static final int YEARDATE = 0;


  protected static final int YEARNAME = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoYearListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute YearDate
   */
  public String getYearDate()
  {
    return (String)getAttributeInternal(YEARDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute YearDate
   */
  public void setYearDate(String value)
  {
    setAttributeInternal(YEARDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute YearName
   */
  public String getYearName()
  {
    return (String)getAttributeInternal(YEARNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute YearName
   */
  public void setYearName(String value)
  {
    setAttributeInternal(YEARNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case YEARDATE:
        return getYearDate();
      case YEARNAME:
        return getYearName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case YEARDATE:
        setYearDate((String)value);
        return;
      case YEARNAME:
        setYearName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
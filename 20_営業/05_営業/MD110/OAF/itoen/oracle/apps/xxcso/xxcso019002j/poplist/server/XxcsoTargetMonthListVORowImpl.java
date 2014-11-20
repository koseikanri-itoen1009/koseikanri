/*============================================================================
* �t�@�C���� : XxcsoTargetMonthListVOImpl
* �T�v����   : ����v��(�����ڋq)�@�Ώ۔N�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.poplist.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * ����v��(�����ڋq)�@�Ώ۔N�r���[�s�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTargetMonthListVORowImpl extends OAViewRowImpl 
{


  protected static final int TARGETMONTH = 0;
  protected static final int TARGETMONTHVIEW = 1;
  protected static final int TARGETMONTHINDEX = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoTargetMonthListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetMonth
   */
  public String getTargetMonth()
  {
    return (String)getAttributeInternal(TARGETMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetMonth
   */
  public void setTargetMonth(String value)
  {
    setAttributeInternal(TARGETMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetMonthView
   */
  public String getTargetMonthView()
  {
    return (String)getAttributeInternal(TARGETMONTHVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetMonthView
   */
  public void setTargetMonthView(String value)
  {
    setAttributeInternal(TARGETMONTHVIEW, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetMonthIndex
   */
  public Number getTargetMonthIndex()
  {
    return (Number)getAttributeInternal(TARGETMONTHINDEX);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetMonthIndex
   */
  public void setTargetMonthIndex(Number value)
  {
    setAttributeInternal(TARGETMONTHINDEX, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TARGETMONTH:
        return getTargetMonth();
      case TARGETMONTHVIEW:
        return getTargetMonthView();
      case TARGETMONTHINDEX:
        return getTargetMonthIndex();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TARGETMONTH:
        setTargetMonth((String)value);
        return;
      case TARGETMONTHVIEW:
        setTargetMonthView((String)value);
        return;
      case TARGETMONTHINDEX:
        setTargetMonthIndex((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
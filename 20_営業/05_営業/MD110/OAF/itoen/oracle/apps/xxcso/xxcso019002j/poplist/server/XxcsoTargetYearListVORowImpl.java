/*============================================================================
* �t�@�C���� : XxcsoTargetMonthListVOImpl
* �T�v����   : ����v��(�����ڋq)�@�Ώی��r���[�s�N���X
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
 * ����v��(�����ڋq)�@�Ώی��r���[�s�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTargetYearListVORowImpl extends OAViewRowImpl 
{


  protected static final int TARGETYEAR = 0;
  protected static final int TARGETYEARVIEW = 1;
  protected static final int TARGETYEARINDEX = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoTargetYearListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetYear
   */
  public String getTargetYear()
  {
    return (String)getAttributeInternal(TARGETYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetYear
   */
  public void setTargetYear(String value)
  {
    setAttributeInternal(TARGETYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetYearView
   */
  public String getTargetYearView()
  {
    return (String)getAttributeInternal(TARGETYEARVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetYearView
   */
  public void setTargetYearView(String value)
  {
    setAttributeInternal(TARGETYEARVIEW, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetYearIndex
   */
  public Number getTargetYearIndex()
  {
    return (Number)getAttributeInternal(TARGETYEARINDEX);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetYearIndex
   */
  public void setTargetYearIndex(Number value)
  {
    setAttributeInternal(TARGETYEARINDEX, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TARGETYEAR:
        return getTargetYear();
      case TARGETYEARVIEW:
        return getTargetYearView();
      case TARGETYEARINDEX:
        return getTargetYearIndex();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TARGETYEAR:
        setTargetYear((String)value);
        return;
      case TARGETYEARVIEW:
        setTargetYearView((String)value);
        return;
      case TARGETYEARINDEX:
        setTargetYearIndex((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
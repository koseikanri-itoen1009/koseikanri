/*============================================================================
* �t�@�C���� : XxcsoPlanMonthListVORowImpl
* �T�v����   : �K��E����v���ʁ@�v�挎�|�b�v���X�g�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.poplist.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �K��E����v���ʁ@�v�挎�|�b�v���X�g�r���[�s�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPlanMonthListVORowImpl extends OAViewRowImpl 
{


  protected static final int PLANMONTH = 0;
  protected static final int PLANMONTHVIEW = 1;
  protected static final int PLANMONTHINDEX = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPlanMonthListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PlanMonth
   */
  public String getPlanMonth()
  {
    return (String)getAttributeInternal(PLANMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PlanMonth
   */
  public void setPlanMonth(String value)
  {
    setAttributeInternal(PLANMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PlanMonthIndex
   */
  public Number getPlanMonthIndex()
  {
    return (Number)getAttributeInternal(PLANMONTHINDEX);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PlanMonthIndex
   */
  public void setPlanMonthIndex(Number value)
  {
    setAttributeInternal(PLANMONTHINDEX, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PLANMONTH:
        return getPlanMonth();
      case PLANMONTHVIEW:
        return getPlanMonthView();
      case PLANMONTHINDEX:
        return getPlanMonthIndex();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PLANMONTH:
        setPlanMonth((String)value);
        return;
      case PLANMONTHVIEW:
        setPlanMonthView((String)value);
        return;
      case PLANMONTHINDEX:
        setPlanMonthIndex((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PlanMonthView
   */
  public String getPlanMonthView()
  {
    return (String)getAttributeInternal(PLANMONTHVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PlanMonthView
   */
  public void setPlanMonthView(String value)
  {
    setAttributeInternal(PLANMONTHVIEW, value);
  }
}
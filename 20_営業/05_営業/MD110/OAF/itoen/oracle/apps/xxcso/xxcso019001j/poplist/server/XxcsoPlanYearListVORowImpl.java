/*============================================================================
* �t�@�C���� : XxcsoPlanYearListVORowImpl
* �T�v����   : �K��E����v���ʁ@�v��N�|�b�v���X�g�r���[�s�N���X
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
 * �K��E����v���ʁ@�v��N�|�b�v���X�g�r���[�s�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPlanYearListVORowImpl extends OAViewRowImpl 
{
  protected static final int PLANYEAR = 0;


  protected static final int PLANYEARVIEW = 1;
  protected static final int PLANYEARINDEX = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPlanYearListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PlanYear
   */
  public String getPlanYear()
  {
    return (String)getAttributeInternal(PLANYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PlanYear
   */
  public void setPlanYear(String value)
  {
    setAttributeInternal(PLANYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PlanYearView
   */
  public String getPlanYearView()
  {
    return (String)getAttributeInternal(PLANYEARVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PlanYearView
   */
  public void setPlanYearView(String value)
  {
    setAttributeInternal(PLANYEARVIEW, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PlanYearIndex
   */
  public Number getPlanYearIndex()
  {
    return (Number)getAttributeInternal(PLANYEARINDEX);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PlanYearIndex
   */
  public void setPlanYearIndex(Number value)
  {
    setAttributeInternal(PLANYEARINDEX, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PLANYEAR:
        return getPlanYear();
      case PLANYEARVIEW:
        return getPlanYearView();
      case PLANYEARINDEX:
        return getPlanYearIndex();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PLANYEAR:
        setPlanYear((String)value);
        return;
      case PLANYEARVIEW:
        setPlanYearView((String)value);
        return;
      case PLANYEARINDEX:
        setPlanYearIndex((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
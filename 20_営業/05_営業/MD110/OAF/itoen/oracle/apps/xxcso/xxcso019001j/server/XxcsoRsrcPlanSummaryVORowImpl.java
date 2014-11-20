/*============================================================================
* �t�@�C���� : XxcsoRsrcPlanSummaryVORowImpl
* �T�v����   : �K��E����v���ʁ@�c�ƈ��v���񃊁[�W�����r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * �K��E����v���ʁ@�c�ƈ��v���񃊁[�W�����r���[�s�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRsrcPlanSummaryVORowImpl extends OAViewRowImpl 
{


  protected static final int EMPLOYEENUMBER = 0;
  protected static final int FULLNAME = 1;
  protected static final int RSRCMONTHLYPLAN = 2;
  protected static final int RSRCACCTMONTHLYPLANSUM = 3;
  protected static final int RSRCMONTHLYDIFFER = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRsrcPlanSummaryVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
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

  /**
   * 
   * Gets the attribute value for the calculated attribute RsrcMonthlyPlan
   */
  public String getRsrcMonthlyPlan()
  {
    return (String)getAttributeInternal(RSRCMONTHLYPLAN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsrcMonthlyPlan
   */
  public void setRsrcMonthlyPlan(String value)
  {
    setAttributeInternal(RSRCMONTHLYPLAN, value);
  }




  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
      case RSRCMONTHLYPLAN:
        return getRsrcMonthlyPlan();
      case RSRCACCTMONTHLYPLANSUM:
        return getRsrcAcctMonthlyPlanSum();
      case RSRCMONTHLYDIFFER:
        return getRsrcMonthlyDiffer();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case RSRCMONTHLYPLAN:
        setRsrcMonthlyPlan((String)value);
        return;
      case RSRCACCTMONTHLYPLANSUM:
        setRsrcAcctMonthlyPlanSum((String)value);
        return;
      case RSRCMONTHLYDIFFER:
        setRsrcMonthlyDiffer((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RsrcAcctMonthlyPlanSum
   */
  public String getRsrcAcctMonthlyPlanSum()
  {
    return (String)getAttributeInternal(RSRCACCTMONTHLYPLANSUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsrcAcctMonthlyPlanSum
   */
  public void setRsrcAcctMonthlyPlanSum(String value)
  {
    setAttributeInternal(RSRCACCTMONTHLYPLANSUM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RsrcMonthlyDiffer
   */
  public String getRsrcMonthlyDiffer()
  {
    return (String)getAttributeInternal(RSRCMONTHLYDIFFER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsrcMonthlyDiffer
   */
  public void setRsrcMonthlyDiffer(String value)
  {
    setAttributeInternal(RSRCMONTHLYDIFFER, value);
  }
}
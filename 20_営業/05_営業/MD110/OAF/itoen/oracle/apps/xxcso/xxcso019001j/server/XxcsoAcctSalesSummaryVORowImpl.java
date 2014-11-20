/*============================================================================
* �t�@�C���� : XxcsoAcctSalesSummaryVORowImpl
* �T�v����   : �K��E����v���ʁ@�ڋq�������ʕ\�����[�W�����r���[�s�N���X
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
 * �K��E����v���ʁ@�ڋq�������ʕ\�����[�W�����r���[�s�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctSalesSummaryVORowImpl extends OAViewRowImpl 
{


  protected static final int ACCOUNTNUMBER = 0;
  protected static final int PARTYNAME = 1;
  protected static final int PLANYEAR = 2;
  protected static final int PLANMONTH = 3;
  protected static final int YEARMONTH = 4;
  protected static final int YEARMONTHVIEW = 5;
  protected static final int PARTYID = 6;
  protected static final int VISTTARGETDIV = 7;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctSalesSummaryVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyName
   */
  public String getPartyName()
  {
    return (String)getAttributeInternal(PARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyName
   */
  public void setPartyName(String value)
  {
    setAttributeInternal(PARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute YearMonth
   */
  public String getYearMonth()
  {
    return (String)getAttributeInternal(YEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute YearMonth
   */
  public void setYearMonth(String value)
  {
    setAttributeInternal(YEARMONTH, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case PARTYNAME:
        return getPartyName();
      case PLANYEAR:
        return getPlanYear();
      case PLANMONTH:
        return getPlanMonth();
      case YEARMONTH:
        return getYearMonth();
      case YEARMONTHVIEW:
        return getYearMonthView();
      case PARTYID:
        return getPartyId();
      case VISTTARGETDIV:
        return getVistTargetDiv();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case PLANYEAR:
        setPlanYear((String)value);
        return;
      case PLANMONTH:
        setPlanMonth((String)value);
        return;
      case YEARMONTH:
        setYearMonth((String)value);
        return;
      case YEARMONTHVIEW:
        setYearMonthView((String)value);
        return;
      case PARTYID:
        setPartyId((String)value);
        return;
      case VISTTARGETDIV:
        setVistTargetDiv((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute YearMonthView
   */
  public String getYearMonthView()
  {
    return (String)getAttributeInternal(YEARMONTHVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute YearMonthView
   */
  public void setYearMonthView(String value)
  {
    setAttributeInternal(YEARMONTHVIEW, value);
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
   * Gets the attribute value for the calculated attribute PartyId
   */
  public String getPartyId()
  {
    return (String)getAttributeInternal(PARTYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyId
   */
  public void setPartyId(String value)
  {
    setAttributeInternal(PARTYID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VistTargetDiv
   */
  public String getVistTargetDiv()
  {
    return (String)getAttributeInternal(VISTTARGETDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VistTargetDiv
   */
  public void setVistTargetDiv(String value)
  {
    setAttributeInternal(VISTTARGETDIV, value);
  }



}
/*============================================================================
* ファイル名 : XxcsoAcctSalesInitVORowImpl
* 概要説明   : 訪問・売上計画画面　顧客検索リージョンビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 訪問・売上計画画面　顧客検索リージョンビュー行クラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctSalesInitVORowImpl extends OAViewRowImpl 
{


  protected static final int ACCOUNTNUMBER = 0;
  protected static final int PARTYNAME = 1;
  protected static final int PARTYID = 2;
  protected static final int VISTTARGETDIV = 3;
  protected static final int PLANYEAR = 4;
  protected static final int RESULTRENDER = 5;
  protected static final int PLANMONTH = 6;
  protected static final int BASECODE = 7;
  protected static final int EMPLOYEENUMBER = 8;
  protected static final int FULLNAME = 9;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctSalesInitVORowImpl()
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case PARTYNAME:
        return getPartyName();
      case PARTYID:
        return getPartyId();
      case VISTTARGETDIV:
        return getVistTargetDiv();
      case PLANYEAR:
        return getPlanYear();
      case RESULTRENDER:
        return getResultRender();
      case PLANMONTH:
        return getPlanMonth();
      case BASECODE:
        return getBaseCode();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
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
      case PARTYID:
        setPartyId((String)value);
        return;
      case VISTTARGETDIV:
        setVistTargetDiv((String)value);
        return;
      case PLANYEAR:
        setPlanYear((String)value);
        return;
      case RESULTRENDER:
        setResultRender((Boolean)value);
        return;
      case PLANMONTH:
        setPlanMonth((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
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
   * Gets the attribute value for the calculated attribute ResultRender
   */
  public Boolean getResultRender()
  {
    return (Boolean)getAttributeInternal(RESULTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ResultRender
   */
  public void setResultRender(Boolean value)
  {
    setAttributeInternal(RESULTRENDER, value);
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
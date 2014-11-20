/*============================================================================
* ファイル名 : XxcsoAcctMonthlyPlanFullVOImpl
* 概要説明   : 売上計画(複数顧客)　顧客別売上計画月別リージョンビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 売上計画(複数顧客)　顧客別売上計画月別リージョンビュー行クラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctMonthlyPlanFullVORowImpl extends OAViewRowImpl 
{


  protected static final int BASECODE = 0;
  protected static final int ACCOUNTNUMBER = 1;
  protected static final int YEARMONTH = 2;
  protected static final int TARGETACCOUNTSALESPLANID = 3;
  protected static final int TARGETMONTHSALESPLANAMT = 4;
  protected static final int TARGETYEARMONTH = 5;
  protected static final int TARGETMONTHLASTUPDDATE = 6;
  protected static final int NEXTACCOUNTSALESPLANID = 7;
  protected static final int NEXTMONTHSALESPLANAMT = 8;
  protected static final int NEXTYEARMONTH = 9;
  protected static final int NEXTMONTHLASTUPDDATE = 10;
  protected static final int CREATEDBY = 11;
  protected static final int CREATIONDATE = 12;
  protected static final int LASTUPDATEDBY = 13;
  protected static final int LASTUPDATEDATE = 14;
  protected static final int LASTUPDATELOGIN = 15;
  protected static final int PARTYID = 16;
  protected static final int PARTYNAME = 17;
  protected static final int INDUSTRYDIV = 18;
  protected static final int VISTTARGETDIV = 19;
  protected static final int NEXTEMPLOYEENUMBER = 20;
  protected static final int TARGETROUTENUMBER = 21;
  protected static final int NEXTROUTENUMBER = 22;
  protected static final int SORTAMT = 23;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctMonthlyPlanFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoAcctMonthlyPlansVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoAcctMonthlyPlansVEOImpl getXxcsoAcctMonthlyPlansVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoAcctMonthlyPlansVEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for BASE_CODE using the alias name BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BASE_CODE using the alias name BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for ACCOUNT_NUMBER using the alias name AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ACCOUNT_NUMBER using the alias name AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for YEAR_MONTH using the alias name YearMonth
   */
  public String getYearMonth()
  {
    return (String)getAttributeInternal(YEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for YEAR_MONTH using the alias name YearMonth
   */
  public void setYearMonth(String value)
  {
    setAttributeInternal(YEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for TARGET_ACCOUNT_SALES_PLAN_ID using the alias name TargetAccountSalesPlanId
   */
  public Number getTargetAccountSalesPlanId()
  {
    return (Number)getAttributeInternal(TARGETACCOUNTSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TARGET_ACCOUNT_SALES_PLAN_ID using the alias name TargetAccountSalesPlanId
   */
  public void setTargetAccountSalesPlanId(Number value)
  {
    setAttributeInternal(TARGETACCOUNTSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for TARGET_MONTH_SALES_PLAN_AMT using the alias name TargetMonthSalesPlanAmt
   */
  public String getTargetMonthSalesPlanAmt()
  {
    return (String)getAttributeInternal(TARGETMONTHSALESPLANAMT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TARGET_MONTH_SALES_PLAN_AMT using the alias name TargetMonthSalesPlanAmt
   */
  public void setTargetMonthSalesPlanAmt(String value)
  {
    setAttributeInternal(TARGETMONTHSALESPLANAMT, value);
  }

  /**
   * 
   * Gets the attribute value for TARGET_YEAR_MONTH using the alias name TargetYearMonth
   */
  public String getTargetYearMonth()
  {
    return (String)getAttributeInternal(TARGETYEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TARGET_YEAR_MONTH using the alias name TargetYearMonth
   */
  public void setTargetYearMonth(String value)
  {
    setAttributeInternal(TARGETYEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for TARGET_MONTH_LAST_UPD_DATE using the alias name TargetMonthLastUpdDate
   */
  public Date getTargetMonthLastUpdDate()
  {
    return (Date)getAttributeInternal(TARGETMONTHLASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TARGET_MONTH_LAST_UPD_DATE using the alias name TargetMonthLastUpdDate
   */
  public void setTargetMonthLastUpdDate(Date value)
  {
    setAttributeInternal(TARGETMONTHLASTUPDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_ACCOUNT_SALES_PLAN_ID using the alias name NextAccountSalesPlanId
   */
  public Number getNextAccountSalesPlanId()
  {
    return (Number)getAttributeInternal(NEXTACCOUNTSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_ACCOUNT_SALES_PLAN_ID using the alias name NextAccountSalesPlanId
   */
  public void setNextAccountSalesPlanId(Number value)
  {
    setAttributeInternal(NEXTACCOUNTSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_YEAR_MONTH using the alias name NextYearMonth
   */
  public String getNextYearMonth()
  {
    return (String)getAttributeInternal(NEXTYEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_YEAR_MONTH using the alias name NextYearMonth
   */
  public void setNextYearMonth(String value)
  {
    setAttributeInternal(NEXTYEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_MONTH_SALES_PLAN_AMT using the alias name NextMonthSalesPlanAmt
   */
  public String getNextMonthSalesPlanAmt()
  {
    return (String)getAttributeInternal(NEXTMONTHSALESPLANAMT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_MONTH_SALES_PLAN_AMT using the alias name NextMonthSalesPlanAmt
   */
  public void setNextMonthSalesPlanAmt(String value)
  {
    setAttributeInternal(NEXTMONTHSALESPLANAMT, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_MONTH_LAST_UPD_DATE using the alias name NextMonthLastUpdDate
   */
  public Date getNextMonthLastUpdDate()
  {
    return (Date)getAttributeInternal(NEXTMONTHLASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_MONTH_LAST_UPD_DATE using the alias name NextMonthLastUpdDate
   */
  public void setNextMonthLastUpdDate(Date value)
  {
    setAttributeInternal(NEXTMONTHLASTUPDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for CREATED_BY using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATED_BY using the alias name CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CREATION_DATE using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATION_DATE using the alias name CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BASECODE:
        return getBaseCode();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case YEARMONTH:
        return getYearMonth();
      case TARGETACCOUNTSALESPLANID:
        return getTargetAccountSalesPlanId();
      case TARGETMONTHSALESPLANAMT:
        return getTargetMonthSalesPlanAmt();
      case TARGETYEARMONTH:
        return getTargetYearMonth();
      case TARGETMONTHLASTUPDDATE:
        return getTargetMonthLastUpdDate();
      case NEXTACCOUNTSALESPLANID:
        return getNextAccountSalesPlanId();
      case NEXTMONTHSALESPLANAMT:
        return getNextMonthSalesPlanAmt();
      case NEXTYEARMONTH:
        return getNextYearMonth();
      case NEXTMONTHLASTUPDDATE:
        return getNextMonthLastUpdDate();
      case CREATEDBY:
        return getCreatedBy();
      case CREATIONDATE:
        return getCreationDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      case PARTYID:
        return getPartyId();
      case PARTYNAME:
        return getPartyName();
      case INDUSTRYDIV:
        return getIndustryDiv();
      case VISTTARGETDIV:
        return getVistTargetDiv();
      case NEXTEMPLOYEENUMBER:
        return getNextEmployeeNumber();
      case TARGETROUTENUMBER:
        return getTargetRouteNumber();
      case NEXTROUTENUMBER:
        return getNextRouteNumber();
      case SORTAMT:
        return getSortAmt();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BASECODE:
        setBaseCode((String)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case YEARMONTH:
        setYearMonth((String)value);
        return;
      case TARGETACCOUNTSALESPLANID:
        setTargetAccountSalesPlanId((Number)value);
        return;
      case TARGETMONTHSALESPLANAMT:
        setTargetMonthSalesPlanAmt((String)value);
        return;
      case TARGETYEARMONTH:
        setTargetYearMonth((String)value);
        return;
      case TARGETMONTHLASTUPDDATE:
        setTargetMonthLastUpdDate((Date)value);
        return;
      case NEXTACCOUNTSALESPLANID:
        setNextAccountSalesPlanId((Number)value);
        return;
      case NEXTMONTHSALESPLANAMT:
        setNextMonthSalesPlanAmt((String)value);
        return;
      case NEXTYEARMONTH:
        setNextYearMonth((String)value);
        return;
      case NEXTMONTHLASTUPDDATE:
        setNextMonthLastUpdDate((Date)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((Number)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      case PARTYID:
        setPartyId((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case INDUSTRYDIV:
        setIndustryDiv((String)value);
        return;
      case VISTTARGETDIV:
        setVistTargetDiv((String)value);
        return;
      case NEXTEMPLOYEENUMBER:
        setNextEmployeeNumber((String)value);
        return;
      case TARGETROUTENUMBER:
        setTargetRouteNumber((String)value);
        return;
      case NEXTROUTENUMBER:
        setNextRouteNumber((String)value);
        return;
      case SORTAMT:
        setSortAmt((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
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
   * Gets the attribute value for the calculated attribute IndustryDiv
   */
  public String getIndustryDiv()
  {
    return (String)getAttributeInternal(INDUSTRYDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IndustryDiv
   */
  public void setIndustryDiv(String value)
  {
    setAttributeInternal(INDUSTRYDIV, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetRouteNumber
   */
  public String getTargetRouteNumber()
  {
    return (String)getAttributeInternal(TARGETROUTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetRouteNumber
   */
  public void setTargetRouteNumber(String value)
  {
    setAttributeInternal(TARGETROUTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NextRouteNumber
   */
  public String getNextRouteNumber()
  {
    return (String)getAttributeInternal(NEXTROUTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NextRouteNumber
   */
  public void setNextRouteNumber(String value)
  {
    setAttributeInternal(NEXTROUTENUMBER, value);
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

  /**
   * 
   * Gets the attribute value for the calculated attribute NextEmployeeNumber
   */
  public String getNextEmployeeNumber()
  {
    return (String)getAttributeInternal(NEXTEMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NextEmployeeNumber
   */
  public void setNextEmployeeNumber(String value)
  {
    setAttributeInternal(NEXTEMPLOYEENUMBER, value);
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
   * Gets the attribute value for the calculated attribute SortAmt
   */
  public Number getSortAmt()
  {
    return (Number)getAttributeInternal(SORTAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SortAmt
   */
  public void setSortAmt(Number value)
  {
    setAttributeInternal(SORTAMT, value);
  }





}
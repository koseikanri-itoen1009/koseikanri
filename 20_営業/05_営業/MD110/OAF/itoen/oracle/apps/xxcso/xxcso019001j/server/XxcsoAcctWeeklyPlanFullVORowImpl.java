/*============================================================================
* ファイル名 : XxcsoAcctWeeklyPlanFullVORowImpl
* 概要説明   : 訪問・売上計画画面　顧客別売上計画日別リージョンビュー行クラス
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
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 訪問・売上計画画面　顧客別売上計画日別リージョンビュー行クラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctWeeklyPlanFullVORowImpl extends OAViewRowImpl 
{


  protected static final int BASECODE = 0;
  protected static final int ACCOUNTNUMBER = 1;
  protected static final int YEARMONTH = 2;
  protected static final int WEEKINDEX = 3;
  protected static final int MONDAYCOLUMN = 4;
  protected static final int MONDAYSALESPLANID = 5;
  protected static final int MONDAYVALUE = 6;
  protected static final int TUESDAYCOLUMN = 7;
  protected static final int TUESDAYSALESPLANID = 8;
  protected static final int TUESDAYVALUE = 9;
  protected static final int WEDNESDAYCOLUMN = 10;
  protected static final int WEDNESDAYSALESPLANID = 11;
  protected static final int WEDNESDAYVALUE = 12;
  protected static final int THURSDAYCOLUMN = 13;
  protected static final int THURSDAYSALESPLANID = 14;
  protected static final int THURSDAYVALUE = 15;
  protected static final int FRIDAYCOLUMN = 16;
  protected static final int FRIDAYSALESPLANID = 17;
  protected static final int FRIDAYVALUE = 18;
  protected static final int SATURDAYCOLUMN = 19;
  protected static final int SATURDAYSALESPLANID = 20;
  protected static final int SATURDAYVALUE = 21;
  protected static final int SUNDAYCOLUMN = 22;
  protected static final int SUNDAYSALESPLANID = 23;
  protected static final int SUNDAYVALUE = 24;
  protected static final int CREATEDBY = 25;
  protected static final int CREATIONDATE = 26;
  protected static final int LASTUPDATEDBY = 27;
  protected static final int LASTUPDATEDATE = 28;
  protected static final int LASTUPDATELOGIN = 29;
  protected static final int MONDAYRENDER = 30;
  protected static final int TUESDAYRENDER = 31;
  protected static final int WEDNESDAYRENDER = 32;
  protected static final int THURSDAYRENDER = 33;
  protected static final int FRIDAYRENDER = 34;
  protected static final int SATURDAYRENDER = 35;
  protected static final int SUNDAYRENDER = 36;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctWeeklyPlanFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoAcctWeeklyPlansVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoAcctWeeklyPlansVEOImpl getXxcsoAcctWeeklyPlansVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoAcctWeeklyPlansVEOImpl)getEntity(0);
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
   * Gets the attribute value for WEEK_INDEX using the alias name WeekIndex
   */
  public Number getWeekIndex()
  {
    return (Number)getAttributeInternal(WEEKINDEX);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for WEEK_INDEX using the alias name WeekIndex
   */
  public void setWeekIndex(Number value)
  {
    setAttributeInternal(WEEKINDEX, value);
  }

  /**
   * 
   * Gets the attribute value for MONDAY_COLUMN using the alias name MondayColumn
   */
  public String getMondayColumn()
  {
    return (String)getAttributeInternal(MONDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for MONDAY_COLUMN using the alias name MondayColumn
   */
  public void setMondayColumn(String value)
  {
    setAttributeInternal(MONDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for MONDAY_SALES_PLAN_ID using the alias name MondaySalesPlanId
   */
  public Number getMondaySalesPlanId()
  {
    return (Number)getAttributeInternal(MONDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for MONDAY_SALES_PLAN_ID using the alias name MondaySalesPlanId
   */
  public void setMondaySalesPlanId(Number value)
  {
    setAttributeInternal(MONDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for MONDAY_VALUE using the alias name MondayValue
   */
  public String getMondayValue()
  {
    return (String)getAttributeInternal(MONDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for MONDAY_VALUE using the alias name MondayValue
   */
  public void setMondayValue(String value)
  {
    setAttributeInternal(MONDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for TUESDAY_COLUMN using the alias name TuesdayColumn
   */
  public String getTuesdayColumn()
  {
    return (String)getAttributeInternal(TUESDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TUESDAY_COLUMN using the alias name TuesdayColumn
   */
  public void setTuesdayColumn(String value)
  {
    setAttributeInternal(TUESDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for TUESDAY_SALES_PLAN_ID using the alias name TuesdaySalesPlanId
   */
  public Number getTuesdaySalesPlanId()
  {
    return (Number)getAttributeInternal(TUESDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TUESDAY_SALES_PLAN_ID using the alias name TuesdaySalesPlanId
   */
  public void setTuesdaySalesPlanId(Number value)
  {
    setAttributeInternal(TUESDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for TUESDAY_VALUE using the alias name TuesdayValue
   */
  public String getTuesdayValue()
  {
    return (String)getAttributeInternal(TUESDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TUESDAY_VALUE using the alias name TuesdayValue
   */
  public void setTuesdayValue(String value)
  {
    setAttributeInternal(TUESDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for WEDNESDAY_COLUMN using the alias name WednesdayColumn
   */
  public String getWednesdayColumn()
  {
    return (String)getAttributeInternal(WEDNESDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for WEDNESDAY_COLUMN using the alias name WednesdayColumn
   */
  public void setWednesdayColumn(String value)
  {
    setAttributeInternal(WEDNESDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for WEDNESDAY_SALES_PLAN_ID using the alias name WednesdaySalesPlanId
   */
  public Number getWednesdaySalesPlanId()
  {
    return (Number)getAttributeInternal(WEDNESDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for WEDNESDAY_SALES_PLAN_ID using the alias name WednesdaySalesPlanId
   */
  public void setWednesdaySalesPlanId(Number value)
  {
    setAttributeInternal(WEDNESDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for WEDNESDAY_VALUE using the alias name WednesdayValue
   */
  public String getWednesdayValue()
  {
    return (String)getAttributeInternal(WEDNESDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for WEDNESDAY_VALUE using the alias name WednesdayValue
   */
  public void setWednesdayValue(String value)
  {
    setAttributeInternal(WEDNESDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for THURSDAY_COLUMN using the alias name ThursdayColumn
   */
  public String getThursdayColumn()
  {
    return (String)getAttributeInternal(THURSDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for THURSDAY_COLUMN using the alias name ThursdayColumn
   */
  public void setThursdayColumn(String value)
  {
    setAttributeInternal(THURSDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for THURSDAY_SALES_PLAN_ID using the alias name ThursdaySalesPlanId
   */
  public Number getThursdaySalesPlanId()
  {
    return (Number)getAttributeInternal(THURSDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for THURSDAY_SALES_PLAN_ID using the alias name ThursdaySalesPlanId
   */
  public void setThursdaySalesPlanId(Number value)
  {
    setAttributeInternal(THURSDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for THURSDAY_VALUE using the alias name ThursdayValue
   */
  public String getThursdayValue()
  {
    return (String)getAttributeInternal(THURSDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for THURSDAY_VALUE using the alias name ThursdayValue
   */
  public void setThursdayValue(String value)
  {
    setAttributeInternal(THURSDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for FRIDAY_COLUMN using the alias name FridayColumn
   */
  public String getFridayColumn()
  {
    return (String)getAttributeInternal(FRIDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for FRIDAY_COLUMN using the alias name FridayColumn
   */
  public void setFridayColumn(String value)
  {
    setAttributeInternal(FRIDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for FRIDAY_SALES_PLAN_ID using the alias name FridaySalesPlanId
   */
  public Number getFridaySalesPlanId()
  {
    return (Number)getAttributeInternal(FRIDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for FRIDAY_SALES_PLAN_ID using the alias name FridaySalesPlanId
   */
  public void setFridaySalesPlanId(Number value)
  {
    setAttributeInternal(FRIDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for FRIDAY_VALUE using the alias name FridayValue
   */
  public String getFridayValue()
  {
    return (String)getAttributeInternal(FRIDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for FRIDAY_VALUE using the alias name FridayValue
   */
  public void setFridayValue(String value)
  {
    setAttributeInternal(FRIDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for SATURDAY_COLUMN using the alias name SaturdayColumn
   */
  public String getSaturdayColumn()
  {
    return (String)getAttributeInternal(SATURDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SATURDAY_COLUMN using the alias name SaturdayColumn
   */
  public void setSaturdayColumn(String value)
  {
    setAttributeInternal(SATURDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for SATURDAY_SALES_PLAN_ID using the alias name SaturdaySalesPlanId
   */
  public Number getSaturdaySalesPlanId()
  {
    return (Number)getAttributeInternal(SATURDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SATURDAY_SALES_PLAN_ID using the alias name SaturdaySalesPlanId
   */
  public void setSaturdaySalesPlanId(Number value)
  {
    setAttributeInternal(SATURDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for SATURDAY_VALUE using the alias name SaturdayValue
   */
  public String getSaturdayValue()
  {
    return (String)getAttributeInternal(SATURDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SATURDAY_VALUE using the alias name SaturdayValue
   */
  public void setSaturdayValue(String value)
  {
    setAttributeInternal(SATURDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for SUNDAY_COLUMN using the alias name SundayColumn
   */
  public String getSundayColumn()
  {
    return (String)getAttributeInternal(SUNDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SUNDAY_COLUMN using the alias name SundayColumn
   */
  public void setSundayColumn(String value)
  {
    setAttributeInternal(SUNDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for SUNDAY_SALES_PLAN_ID using the alias name SundaySalesPlanId
   */
  public Number getSundaySalesPlanId()
  {
    return (Number)getAttributeInternal(SUNDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SUNDAY_SALES_PLAN_ID using the alias name SundaySalesPlanId
   */
  public void setSundaySalesPlanId(Number value)
  {
    setAttributeInternal(SUNDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for SUNDAY_VALUE using the alias name SundayValue
   */
  public String getSundayValue()
  {
    return (String)getAttributeInternal(SUNDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SUNDAY_VALUE using the alias name SundayValue
   */
  public void setSundayValue(String value)
  {
    setAttributeInternal(SUNDAYVALUE, value);
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
      case WEEKINDEX:
        return getWeekIndex();
      case MONDAYCOLUMN:
        return getMondayColumn();
      case MONDAYSALESPLANID:
        return getMondaySalesPlanId();
      case MONDAYVALUE:
        return getMondayValue();
      case TUESDAYCOLUMN:
        return getTuesdayColumn();
      case TUESDAYSALESPLANID:
        return getTuesdaySalesPlanId();
      case TUESDAYVALUE:
        return getTuesdayValue();
      case WEDNESDAYCOLUMN:
        return getWednesdayColumn();
      case WEDNESDAYSALESPLANID:
        return getWednesdaySalesPlanId();
      case WEDNESDAYVALUE:
        return getWednesdayValue();
      case THURSDAYCOLUMN:
        return getThursdayColumn();
      case THURSDAYSALESPLANID:
        return getThursdaySalesPlanId();
      case THURSDAYVALUE:
        return getThursdayValue();
      case FRIDAYCOLUMN:
        return getFridayColumn();
      case FRIDAYSALESPLANID:
        return getFridaySalesPlanId();
      case FRIDAYVALUE:
        return getFridayValue();
      case SATURDAYCOLUMN:
        return getSaturdayColumn();
      case SATURDAYSALESPLANID:
        return getSaturdaySalesPlanId();
      case SATURDAYVALUE:
        return getSaturdayValue();
      case SUNDAYCOLUMN:
        return getSundayColumn();
      case SUNDAYSALESPLANID:
        return getSundaySalesPlanId();
      case SUNDAYVALUE:
        return getSundayValue();
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
      case MONDAYRENDER:
        return getMondayRender();
      case TUESDAYRENDER:
        return getTuesdayRender();
      case WEDNESDAYRENDER:
        return getWednesdayRender();
      case THURSDAYRENDER:
        return getThursdayRender();
      case FRIDAYRENDER:
        return getFridayRender();
      case SATURDAYRENDER:
        return getSaturdayRender();
      case SUNDAYRENDER:
        return getSundayRender();
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
      case WEEKINDEX:
        setWeekIndex((Number)value);
        return;
      case MONDAYCOLUMN:
        setMondayColumn((String)value);
        return;
      case MONDAYSALESPLANID:
        setMondaySalesPlanId((Number)value);
        return;
      case MONDAYVALUE:
        setMondayValue((String)value);
        return;
      case TUESDAYCOLUMN:
        setTuesdayColumn((String)value);
        return;
      case TUESDAYSALESPLANID:
        setTuesdaySalesPlanId((Number)value);
        return;
      case TUESDAYVALUE:
        setTuesdayValue((String)value);
        return;
      case WEDNESDAYCOLUMN:
        setWednesdayColumn((String)value);
        return;
      case WEDNESDAYSALESPLANID:
        setWednesdaySalesPlanId((Number)value);
        return;
      case WEDNESDAYVALUE:
        setWednesdayValue((String)value);
        return;
      case THURSDAYCOLUMN:
        setThursdayColumn((String)value);
        return;
      case THURSDAYSALESPLANID:
        setThursdaySalesPlanId((Number)value);
        return;
      case THURSDAYVALUE:
        setThursdayValue((String)value);
        return;
      case FRIDAYCOLUMN:
        setFridayColumn((String)value);
        return;
      case FRIDAYSALESPLANID:
        setFridaySalesPlanId((Number)value);
        return;
      case FRIDAYVALUE:
        setFridayValue((String)value);
        return;
      case SATURDAYCOLUMN:
        setSaturdayColumn((String)value);
        return;
      case SATURDAYSALESPLANID:
        setSaturdaySalesPlanId((Number)value);
        return;
      case SATURDAYVALUE:
        setSaturdayValue((String)value);
        return;
      case SUNDAYCOLUMN:
        setSundayColumn((String)value);
        return;
      case SUNDAYSALESPLANID:
        setSundaySalesPlanId((Number)value);
        return;
      case SUNDAYVALUE:
        setSundayValue((String)value);
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
      case MONDAYRENDER:
        setMondayRender((Boolean)value);
        return;
      case TUESDAYRENDER:
        setTuesdayRender((Boolean)value);
        return;
      case WEDNESDAYRENDER:
        setWednesdayRender((Boolean)value);
        return;
      case THURSDAYRENDER:
        setThursdayRender((Boolean)value);
        return;
      case FRIDAYRENDER:
        setFridayRender((Boolean)value);
        return;
      case SATURDAYRENDER:
        setSaturdayRender((Boolean)value);
        return;
      case SUNDAYRENDER:
        setSundayRender((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MondayRender
   */
  public Boolean getMondayRender()
  {
    return (Boolean)getAttributeInternal(MONDAYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MondayRender
   */
  public void setMondayRender(Boolean value)
  {
    setAttributeInternal(MONDAYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TuesdayRender
   */
  public Boolean getTuesdayRender()
  {
    return (Boolean)getAttributeInternal(TUESDAYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TuesdayRender
   */
  public void setTuesdayRender(Boolean value)
  {
    setAttributeInternal(TUESDAYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WednesdayRender
   */
  public Boolean getWednesdayRender()
  {
    return (Boolean)getAttributeInternal(WEDNESDAYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WednesdayRender
   */
  public void setWednesdayRender(Boolean value)
  {
    setAttributeInternal(WEDNESDAYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ThursdayRender
   */
  public Boolean getThursdayRender()
  {
    return (Boolean)getAttributeInternal(THURSDAYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ThursdayRender
   */
  public void setThursdayRender(Boolean value)
  {
    setAttributeInternal(THURSDAYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FridayRender
   */
  public Boolean getFridayRender()
  {
    return (Boolean)getAttributeInternal(FRIDAYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FridayRender
   */
  public void setFridayRender(Boolean value)
  {
    setAttributeInternal(FRIDAYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SaturdayRender
   */
  public Boolean getSaturdayRender()
  {
    return (Boolean)getAttributeInternal(SATURDAYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SaturdayRender
   */
  public void setSaturdayRender(Boolean value)
  {
    setAttributeInternal(SATURDAYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SundayRender
   */
  public Boolean getSundayRender()
  {
    return (Boolean)getAttributeInternal(SUNDAYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SundayRender
   */
  public void setSundayRender(Boolean value)
  {
    setAttributeInternal(SUNDAYRENDER, value);
  }
}
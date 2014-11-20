/*============================================================================
* ファイル名 : XxcsoDeptMonthlyPlansFullVORowImpl
* 概要説明   : 拠点別月別計画テーブル登録／更新用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
/*******************************************************************************
 * 拠点別月別計画テーブルを登録／更新するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoDeptMonthlyPlansFullVORowImpl extends OAViewRowImpl 
{


  protected static final int BASECODE = 0;
  protected static final int TARGETYEAR = 1;
  protected static final int TARGETMONTH = 2;
  protected static final int DEPTMONTHLYPLANID = 3;
  protected static final int SALESPLANRELDIV = 4;
  protected static final int CREATEDBY = 5;
  protected static final int CREATIONDATE = 6;
  protected static final int LASTUPDATEDBY = 7;
  protected static final int LASTUPDATEDATE = 8;
  protected static final int LASTUPDATELOGIN = 9;
  protected static final int BASENAME = 10;
  protected static final int TITLE = 11;
  protected static final int YEARATTRREADONLY = 12;
  protected static final int MONTHATTRREADONLY = 13;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoDeptMonthlyPlansFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoDeptMonthlyPlansVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoDeptMonthlyPlansVEOImpl getXxcsoDeptMonthlyPlansVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoDeptMonthlyPlansVEOImpl)getEntity(0);
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
   * Gets the attribute value for TARGET_YEAR using the alias name TargetYear
   */
  public String getTargetYear()
  {
    return (String)getAttributeInternal(TARGETYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TARGET_YEAR using the alias name TargetYear
   */
  public void setTargetYear(String value)
  {
    setAttributeInternal(TARGETYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for TARGET_MONTH using the alias name TargetMonth
   */
  public String getTargetMonth()
  {
    return (String)getAttributeInternal(TARGETMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TARGET_MONTH using the alias name TargetMonth
   */
  public void setTargetMonth(String value)
  {
    setAttributeInternal(TARGETMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for DEPT_MONTHLY_PLAN_ID using the alias name DeptMonthlyPlanId
   */
  public Number getDeptMonthlyPlanId()
  {
    return (Number)getAttributeInternal(DEPTMONTHLYPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DEPT_MONTHLY_PLAN_ID using the alias name DeptMonthlyPlanId
   */
  public void setDeptMonthlyPlanId(Number value)
  {
    setAttributeInternal(DEPTMONTHLYPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for SALES_PLAN_REL_DIV using the alias name SalesPlanRelDiv
   */
  public String getSalesPlanRelDiv()
  {
    return (String)getAttributeInternal(SALESPLANRELDIV);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_PLAN_REL_DIV using the alias name SalesPlanRelDiv
   */
  public void setSalesPlanRelDiv(String value)
  {
    setAttributeInternal(SALESPLANRELDIV, value);
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

  /**
   * 
   * Gets the attribute value for BASE_NAME using the alias name BaseName
   */
  public String getBaseName()
  {
    return (String)getAttributeInternal(BASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BASE_NAME using the alias name BaseName
   */
  public void setBaseName(String value)
  {
    setAttributeInternal(BASENAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BASECODE:
        return getBaseCode();
      case TARGETYEAR:
        return getTargetYear();
      case TARGETMONTH:
        return getTargetMonth();
      case DEPTMONTHLYPLANID:
        return getDeptMonthlyPlanId();
      case SALESPLANRELDIV:
        return getSalesPlanRelDiv();
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
      case BASENAME:
        return getBaseName();
      case TITLE:
        return getTitle();
      case YEARATTRREADONLY:
        return getYearAttrReadOnly();
      case MONTHATTRREADONLY:
        return getMonthAttrReadOnly();
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
      case TARGETYEAR:
        setTargetYear((String)value);
        return;
      case TARGETMONTH:
        setTargetMonth((String)value);
        return;
      case DEPTMONTHLYPLANID:
        setDeptMonthlyPlanId((Number)value);
        return;
      case SALESPLANRELDIV:
        setSalesPlanRelDiv((String)value);
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
      case BASENAME:
        setBaseName((String)value);
        return;
      case TITLE:
        setTitle((String)value);
        return;
      case YEARATTRREADONLY:
        setYearAttrReadOnly((Boolean)value);
        return;
      case MONTHATTRREADONLY:
        setMonthAttrReadOnly((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Title
   */
  public String getTitle()
  {
    return (String)getAttributeInternal(TITLE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Title
   */
  public void setTitle(String value)
  {
    setAttributeInternal(TITLE, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute YearAttrReadOnly
   */
  public Boolean getYearAttrReadOnly()
  {
    return (Boolean)getAttributeInternal(YEARATTRREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute YearAttrReadOnly
   */
  public void setYearAttrReadOnly(Boolean value)
  {
    setAttributeInternal(YEARATTRREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MonthAttrReadOnly
   */
  public Boolean getMonthAttrReadOnly()
  {
    return (Boolean)getAttributeInternal(MONTHATTRREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MonthAttrReadOnly
   */
  public void setMonthAttrReadOnly(Boolean value)
  {
    setAttributeInternal(MONTHATTRREADONLY, value);
  }
}
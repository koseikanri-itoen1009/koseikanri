/*============================================================================
* ファイル名 : XxcsoSalesNotifyFullVORowImpl
* 概要説明   : 商談決定情報通知者リスト登録用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.AttributeList;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso007003j.util.XxcsoSalesRegistConstants;

/*******************************************************************************
 * 商談決定情報明細通知者リストを登録するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesNotifyFullVORowImpl extends OAViewRowImpl 
{


  protected static final int SALESNOTICEID = 0;
  protected static final int HEADERHISTORYID = 1;
  protected static final int USERNAME = 2;
  protected static final int EMPLOYEENUMBER = 3;
  protected static final int FULLNAME = 4;
  protected static final int POSITIONNAME = 5;
  protected static final int POSITIONSORTCODE = 6;
  protected static final int BASECODE = 7;
  protected static final int BASENAME = 8;
  protected static final int NOTIFIEDFLAG = 9;
  protected static final int CREATEDBY = 10;
  protected static final int CREATIONDATE = 11;
  protected static final int LASTUPDATEDBY = 12;
  protected static final int LASTUPDATEDATE = 13;
  protected static final int LASTUPDATELOGIN = 14;
  protected static final int REQUESTID = 15;
  protected static final int PROGRAMAPPLICATIONID = 16;
  protected static final int PROGRAMID = 17;
  protected static final int PROGRAMUPDATEDATE = 18;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesNotifyFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoSalesNotifiesEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesNotifiesEOImpl getXxcsoSalesNotifiesEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesNotifiesEOImpl)getEntity(0);
  }


  /*****************************************************************************
   * レコード作成処理です。
   * @see oracle.apps.fnd.framework.server.OAViewRowImpl.create
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    XxcsoUtils.checkRowSize(
      this
     ,XxcsoSalesRegistConstants.TOKEN_VALUE_NOTIFY_LIST
    );
    
    super.create(list);
  }



  /**
   * 
   * Gets the attribute value for SALES_NOTICE_ID using the alias name SalesNoticeId
   */
  public Number getSalesNoticeId()
  {
    return (Number)getAttributeInternal(SALESNOTICEID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_NOTICE_ID using the alias name SalesNoticeId
   */
  public void setSalesNoticeId(Number value)
  {
    setAttributeInternal(SALESNOTICEID, value);
  }

  /**
   * 
   * Gets the attribute value for HEADER_HISTORY_ID using the alias name HeaderHistoryId
   */
  public Number getHeaderHistoryId()
  {
    return (Number)getAttributeInternal(HEADERHISTORYID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for HEADER_HISTORY_ID using the alias name HeaderHistoryId
   */
  public void setHeaderHistoryId(Number value)
  {
    setAttributeInternal(HEADERHISTORYID, value);
  }

  /**
   * 
   * Gets the attribute value for USER_NAME using the alias name UserName
   */
  public String getUserName()
  {
    return (String)getAttributeInternal(USERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for USER_NAME using the alias name UserName
   */
  public void setUserName(String value)
  {
    setAttributeInternal(USERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for EMPLOYEE_NUMBER using the alias name EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EMPLOYEE_NUMBER using the alias name EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for FULL_NAME using the alias name FullName
   */
  public String getFullName()
  {
    return (String)getAttributeInternal(FULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for FULL_NAME using the alias name FullName
   */
  public void setFullName(String value)
  {
    setAttributeInternal(FULLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for POSITION_NAME using the alias name PositionName
   */
  public String getPositionName()
  {
    return (String)getAttributeInternal(POSITIONNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for POSITION_NAME using the alias name PositionName
   */
  public void setPositionName(String value)
  {
    setAttributeInternal(POSITIONNAME, value);
  }

  /**
   * 
   * Gets the attribute value for POSITION_SORT_CODE using the alias name PositionSortCode
   */
  public String getPositionSortCode()
  {
    return (String)getAttributeInternal(POSITIONSORTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for POSITION_SORT_CODE using the alias name PositionSortCode
   */
  public void setPositionSortCode(String value)
  {
    setAttributeInternal(POSITIONSORTCODE, value);
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

  /**
   * 
   * Gets the attribute value for NOTIFIED_FLAG using the alias name NotifiedFlag
   */
  public String getNotifiedFlag()
  {
    return (String)getAttributeInternal(NOTIFIEDFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NOTIFIED_FLAG using the alias name NotifiedFlag
   */
  public void setNotifiedFlag(String value)
  {
    setAttributeInternal(NOTIFIEDFLAG, value);
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
   * Gets the attribute value for REQUEST_ID using the alias name RequestId
   */
  public Number getRequestId()
  {
    return (Number)getAttributeInternal(REQUESTID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for REQUEST_ID using the alias name RequestId
   */
  public void setRequestId(Number value)
  {
    setAttributeInternal(REQUESTID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_APPLICATION_ID using the alias name ProgramApplicationId
   */
  public Number getProgramApplicationId()
  {
    return (Number)getAttributeInternal(PROGRAMAPPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_APPLICATION_ID using the alias name ProgramApplicationId
   */
  public void setProgramApplicationId(Number value)
  {
    setAttributeInternal(PROGRAMAPPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_ID using the alias name ProgramId
   */
  public Number getProgramId()
  {
    return (Number)getAttributeInternal(PROGRAMID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_ID using the alias name ProgramId
   */
  public void setProgramId(Number value)
  {
    setAttributeInternal(PROGRAMID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_UPDATE_DATE using the alias name ProgramUpdateDate
   */
  public Date getProgramUpdateDate()
  {
    return (Date)getAttributeInternal(PROGRAMUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_UPDATE_DATE using the alias name ProgramUpdateDate
   */
  public void setProgramUpdateDate(Date value)
  {
    setAttributeInternal(PROGRAMUPDATEDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SALESNOTICEID:
        return getSalesNoticeId();
      case HEADERHISTORYID:
        return getHeaderHistoryId();
      case USERNAME:
        return getUserName();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
      case POSITIONNAME:
        return getPositionName();
      case POSITIONSORTCODE:
        return getPositionSortCode();
      case BASECODE:
        return getBaseCode();
      case BASENAME:
        return getBaseName();
      case NOTIFIEDFLAG:
        return getNotifiedFlag();
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
      case REQUESTID:
        return getRequestId();
      case PROGRAMAPPLICATIONID:
        return getProgramApplicationId();
      case PROGRAMID:
        return getProgramId();
      case PROGRAMUPDATEDATE:
        return getProgramUpdateDate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SALESNOTICEID:
        setSalesNoticeId((Number)value);
        return;
      case HEADERHISTORYID:
        setHeaderHistoryId((Number)value);
        return;
      case USERNAME:
        setUserName((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case POSITIONNAME:
        setPositionName((String)value);
        return;
      case POSITIONSORTCODE:
        setPositionSortCode((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case BASENAME:
        setBaseName((String)value);
        return;
      case NOTIFIEDFLAG:
        setNotifiedFlag((String)value);
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
      case REQUESTID:
        setRequestId((Number)value);
        return;
      case PROGRAMAPPLICATIONID:
        setProgramApplicationId((Number)value);
        return;
      case PROGRAMID:
        setProgramId((Number)value);
        return;
      case PROGRAMUPDATEDATE:
        setProgramUpdateDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
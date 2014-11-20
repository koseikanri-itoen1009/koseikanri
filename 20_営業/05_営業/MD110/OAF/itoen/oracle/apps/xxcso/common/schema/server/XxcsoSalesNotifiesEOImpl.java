/*============================================================================
* ファイル名 : XxcsoSalesNotifiesEOImpl
* 概要説明   : 商談決定情報通知者リストエンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;

import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
import oracle.jbo.AttributeList;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import com.sun.java.util.collections.Iterator;

/*******************************************************************************
 * 商談決定情報通知者リストのエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesNotifiesEOImpl extends OAPlsqlEntityImpl 
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
  protected static final int XXCSOSALESREQUESTEO = 19;




  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesNotifiesEOImpl()
  {
  }

  /**
   * 
   * Retrieves the definition object for this instance class.
   */
  public static synchronized EntityDefImpl getDefinitionObject()
  {
    if (mDefinitionObject == null)
    {
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesNotifiesEO");
    }
    return mDefinitionObject;
  }






  /*****************************************************************************
   * エンティティの作成処理です。
   * @param list 属性リスト
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.create
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    super.create(list);
    
    // 仮の値を設定します。
    EntityDefImpl notifyDef = XxcsoSalesNotifiesEOImpl.getDefinitionObject();
    Iterator notifyIt = notifyDef.getAllEntityInstancesIterator(txn);

    int minValue = 0;
    
    while( notifyIt.hasNext() )
    {
      XxcsoSalesNotifiesEOImpl notifyEo
        = (XxcsoSalesNotifiesEOImpl)notifyIt.next();

      int salesNotifyId = notifyEo.getSalesNoticeId().intValue();

      if ( minValue > salesNotifyId )
      {
        minValue = salesNotifyId;
      }
    }

    minValue--;

    XxcsoUtils.debug(txn, "new id:" + minValue);

    setSalesNoticeId(new Number(minValue));
    setNotifiedFlag("Y");

    XxcsoUtils.debug(txn, "[END]");
  }



  /*****************************************************************************
   * レコードロック処理です。
   * 空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }
  

  /*****************************************************************************
   * レコード作成処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    EntityDefImpl requestDef = XxcsoSalesRequestEOImpl.getDefinitionObject();
    Iterator requestIt = requestDef.getAllEntityInstancesIterator(txn);

    String operationMode   = null;
    Number headerHistoryId = null;
    
    while ( requestIt.hasNext() )
    {
      XxcsoSalesRequestEOImpl requestEo
        = (XxcsoSalesRequestEOImpl)requestIt.next();

      if ( requestEo.getEntityState() == STATUS_NEW )
      {
        operationMode   = requestEo.getOperationMode();
        headerHistoryId = requestEo.getHeaderHistoryId();
        break;
      }
    }

    if ( XxcsoConstants.OPERATION_MODE_REQUEST.equals(operationMode) )
    {
      // 通知フラグが設定されているレコードのみINSERT
      if (  "Y".equals(getNotifiedFlag()) )
      {
        // 商談決定情報履歴ヘッダIDを設定します。
        setHeaderHistoryId(headerHistoryId);
      
        // 登録する直前でシーケンス値を払い出します。
        Number salesNotifyId = txn.getSequenceValue("XXCSO_SALES_NOTIFIES_S01");

        setSalesNoticeId(salesNotifyId);

        super.insertRow();
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード更新処理です。
   * 空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.updateRow
   *****************************************************************************
   */
  public void updateRow()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード削除処理です。
   * 空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.deleteRow
   *****************************************************************************
   */
  public void deleteRow()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }


  /**
   * 
   * Gets the attribute value for SalesNoticeId, using the alias name SalesNoticeId
   */
  public Number getSalesNoticeId()
  {
    return (Number)getAttributeInternal(SALESNOTICEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesNoticeId
   */
  public void setSalesNoticeId(Number value)
  {
    setAttributeInternal(SALESNOTICEID, value);
  }

  /**
   * 
   * Gets the attribute value for HeaderHistoryId, using the alias name HeaderHistoryId
   */
  public Number getHeaderHistoryId()
  {
    return (Number)getAttributeInternal(HEADERHISTORYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for HeaderHistoryId
   */
  public void setHeaderHistoryId(Number value)
  {
    setAttributeInternal(HEADERHISTORYID, value);
  }

  /**
   * 
   * Gets the attribute value for UserName, using the alias name UserName
   */
  public String getUserName()
  {
    return (String)getAttributeInternal(USERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for UserName
   */
  public void setUserName(String value)
  {
    setAttributeInternal(USERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for EmployeeNumber, using the alias name EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for FullName, using the alias name FullName
   */
  public String getFullName()
  {
    return (String)getAttributeInternal(FULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for FullName
   */
  public void setFullName(String value)
  {
    setAttributeInternal(FULLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for PositionName, using the alias name PositionName
   */
  public String getPositionName()
  {
    return (String)getAttributeInternal(POSITIONNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PositionName
   */
  public void setPositionName(String value)
  {
    setAttributeInternal(POSITIONNAME, value);
  }

  /**
   * 
   * Gets the attribute value for PositionSortCode, using the alias name PositionSortCode
   */
  public String getPositionSortCode()
  {
    return (String)getAttributeInternal(POSITIONSORTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PositionSortCode
   */
  public void setPositionSortCode(String value)
  {
    setAttributeInternal(POSITIONSORTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for BaseCode, using the alias name BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for BaseName, using the alias name BaseName
   */
  public String getBaseName()
  {
    return (String)getAttributeInternal(BASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BaseName
   */
  public void setBaseName(String value)
  {
    setAttributeInternal(BASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for NotifiedFlag, using the alias name NotifiedFlag
   */
  public String getNotifiedFlag()
  {
    return (String)getAttributeInternal(NOTIFIEDFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NotifiedFlag
   */
  public void setNotifiedFlag(String value)
  {
    setAttributeInternal(NOTIFIEDFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for CreatedBy, using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CreationDate, using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateDate, using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateLogin, using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for RequestId, using the alias name RequestId
   */
  public Number getRequestId()
  {
    return (Number)getAttributeInternal(REQUESTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RequestId
   */
  public void setRequestId(Number value)
  {
    setAttributeInternal(REQUESTID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramApplicationId, using the alias name ProgramApplicationId
   */
  public Number getProgramApplicationId()
  {
    return (Number)getAttributeInternal(PROGRAMAPPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramApplicationId
   */
  public void setProgramApplicationId(Number value)
  {
    setAttributeInternal(PROGRAMAPPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramId, using the alias name ProgramId
   */
  public Number getProgramId()
  {
    return (Number)getAttributeInternal(PROGRAMID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramId
   */
  public void setProgramId(Number value)
  {
    setAttributeInternal(PROGRAMID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramUpdateDate, using the alias name ProgramUpdateDate
   */
  public Date getProgramUpdateDate()
  {
    return (Date)getAttributeInternal(PROGRAMUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramUpdateDate
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
      case XXCSOSALESREQUESTEO:
        return getXxcsoSalesRequestEO();
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


  /**
   * 
   * Gets the associated entity XxcsoSalesRequestEOImpl
   */
  public XxcsoSalesRequestEOImpl getXxcsoSalesRequestEO()
  {
    return (XxcsoSalesRequestEOImpl)getAttributeInternal(XXCSOSALESREQUESTEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoSalesRequestEOImpl
   */
  public void setXxcsoSalesRequestEO(XxcsoSalesRequestEOImpl value)
  {
    setAttributeInternal(XXCSOSALESREQUESTEO, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number salesNoticeId)
  {
    return new Key(new Object[] {salesNoticeId});
  }




}
/*============================================================================
* ファイル名 : XxcsoContractCustomersEOImpl
* 概要説明   : 契約先テーブルエンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-22 1.0  SCS小川浩  新規作成
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
import oracle.jbo.AlreadyLockedException;
import oracle.jbo.RowNotFoundException;
import oracle.jbo.RowInconsistentException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

/*******************************************************************************
 * 契約先テーブルのエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractCustomersEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int CONTRACTCUSTOMERID = 0;
  protected static final int CONTRACTNUMBER = 1;
  protected static final int CONTRACTNAME = 2;
  protected static final int CONTRACTNAMEKANA = 3;
  protected static final int DELEGATENAME = 4;
  protected static final int POSTCODE = 5;
  protected static final int PREFECTURES = 6;
  protected static final int CITYWARD = 7;
  protected static final int ADDRESS1 = 8;
  protected static final int ADDRESS2 = 9;
  protected static final int PHONENUMBER = 10;
  protected static final int CREATEDBY = 11;
  protected static final int CREATIONDATE = 12;
  protected static final int LASTUPDATEDBY = 13;
  protected static final int LASTUPDATEDATE = 14;
  protected static final int LASTUPDATELOGIN = 15;
  protected static final int REQUESTID = 16;
  protected static final int PROGRAMAPPLICATIONID = 17;
  protected static final int PROGRAMID = 18;
  protected static final int PROGRAMUPDATEDATE = 19;

  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractCustomersEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoContractCustomersEO");
    }
    return mDefinitionObject;
  }





  /*****************************************************************************
   * エンティティの作成処理です。
   * 呼ばれないはずなので空振りします。
   * @param list 属性リスト
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.create
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }




  /*****************************************************************************
   * レコードロック処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    String contractNumber = getContractNumber();
    
    try
    {
      super.lockRow();
    }
    catch ( AlreadyLockedException ale )
    {
      throw XxcsoMessage.createTransactionLockError(
        XxcsoConstants.TOKEN_VALUE_CONTRACTOR_INFO
          + contractNumber
      );
    }
    catch ( RowInconsistentException rie )
    {
      throw XxcsoMessage.createTransactionInconsistentError(
        XxcsoConstants.TOKEN_VALUE_CONTRACTOR_INFO
          + contractNumber
      );      
    }
    catch ( RowNotFoundException rnfe )
    {
      throw XxcsoMessage.createRecordNotFoundError(
        XxcsoConstants.TOKEN_VALUE_CONTRACTOR_INFO
          + contractNumber
      );      
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード作成処理です。
   * 呼ばれないはずなので空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * レコード更新処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.updateRow
   *****************************************************************************
   */
  public void updateRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    super.updateRow();

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード削除処理です。
   * 呼ばれないはずなので空振りします。
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
   * Gets the attribute value for ContractCustomerId, using the alias name ContractCustomerId
   */
  public Number getContractCustomerId()
  {
    return (Number)getAttributeInternal(CONTRACTCUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractCustomerId
   */
  public void setContractCustomerId(Number value)
  {
    setAttributeInternal(CONTRACTCUSTOMERID, value);
  }

  /**
   * 
   * Gets the attribute value for ContractNumber, using the alias name ContractNumber
   */
  public String getContractNumber()
  {
    return (String)getAttributeInternal(CONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractNumber
   */
  public void setContractNumber(String value)
  {
    setAttributeInternal(CONTRACTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ContractName, using the alias name ContractName
   */
  public String getContractName()
  {
    return (String)getAttributeInternal(CONTRACTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractName
   */
  public void setContractName(String value)
  {
    setAttributeInternal(CONTRACTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for ContractNameKana, using the alias name ContractNameKana
   */
  public String getContractNameKana()
  {
    return (String)getAttributeInternal(CONTRACTNAMEKANA);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractNameKana
   */
  public void setContractNameKana(String value)
  {
    setAttributeInternal(CONTRACTNAMEKANA, value);
  }

  /**
   * 
   * Gets the attribute value for DelegateName, using the alias name DelegateName
   */
  public String getDelegateName()
  {
    return (String)getAttributeInternal(DELEGATENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for DelegateName
   */
  public void setDelegateName(String value)
  {
    setAttributeInternal(DELEGATENAME, value);
  }

  /**
   * 
   * Gets the attribute value for PostCode, using the alias name PostCode
   */
  public String getPostCode()
  {
    return (String)getAttributeInternal(POSTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PostCode
   */
  public void setPostCode(String value)
  {
    setAttributeInternal(POSTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for Prefectures, using the alias name Prefectures
   */
  public String getPrefectures()
  {
    return (String)getAttributeInternal(PREFECTURES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Prefectures
   */
  public void setPrefectures(String value)
  {
    setAttributeInternal(PREFECTURES, value);
  }

  /**
   * 
   * Gets the attribute value for CityWard, using the alias name CityWard
   */
  public String getCityWard()
  {
    return (String)getAttributeInternal(CITYWARD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CityWard
   */
  public void setCityWard(String value)
  {
    setAttributeInternal(CITYWARD, value);
  }

  /**
   * 
   * Gets the attribute value for Address1, using the alias name Address1
   */
  public String getAddress1()
  {
    return (String)getAttributeInternal(ADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Address1
   */
  public void setAddress1(String value)
  {
    setAttributeInternal(ADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for Address2, using the alias name Address2
   */
  public String getAddress2()
  {
    return (String)getAttributeInternal(ADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Address2
   */
  public void setAddress2(String value)
  {
    setAttributeInternal(ADDRESS2, value);
  }

  /**
   * 
   * Gets the attribute value for PhoneNumber, using the alias name PhoneNumber
   */
  public String getPhoneNumber()
  {
    return (String)getAttributeInternal(PHONENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PhoneNumber
   */
  public void setPhoneNumber(String value)
  {
    setAttributeInternal(PHONENUMBER, value);
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
      case CONTRACTCUSTOMERID:
        return getContractCustomerId();
      case CONTRACTNUMBER:
        return getContractNumber();
      case CONTRACTNAME:
        return getContractName();
      case CONTRACTNAMEKANA:
        return getContractNameKana();
      case DELEGATENAME:
        return getDelegateName();
      case POSTCODE:
        return getPostCode();
      case PREFECTURES:
        return getPrefectures();
      case CITYWARD:
        return getCityWard();
      case ADDRESS1:
        return getAddress1();
      case ADDRESS2:
        return getAddress2();
      case PHONENUMBER:
        return getPhoneNumber();
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
      case CONTRACTCUSTOMERID:
        setContractCustomerId((Number)value);
        return;
      case CONTRACTNUMBER:
        setContractNumber((String)value);
        return;
      case CONTRACTNAME:
        setContractName((String)value);
        return;
      case CONTRACTNAMEKANA:
        setContractNameKana((String)value);
        return;
      case DELEGATENAME:
        setDelegateName((String)value);
        return;
      case POSTCODE:
        setPostCode((String)value);
        return;
      case PREFECTURES:
        setPrefectures((String)value);
        return;
      case CITYWARD:
        setCityWard((String)value);
        return;
      case ADDRESS1:
        setAddress1((String)value);
        return;
      case ADDRESS2:
        setAddress2((String)value);
        return;
      case PHONENUMBER:
        setPhoneNumber((String)value);
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
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number contractCustomerId)
  {
    return new Key(new Object[] {contractCustomerId});
  }


}
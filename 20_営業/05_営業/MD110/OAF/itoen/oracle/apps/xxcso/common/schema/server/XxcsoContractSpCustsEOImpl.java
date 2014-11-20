/*============================================================================
* ファイル名 : XxcsoContractSpCustsEOImpl
* 概要説明   : SP専決顧客テーブル（契約管理からの更新用）エンティティクラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-22 1.0  SCS小川浩    新規作成
* 2010-02-05 1.1  SCS阿部大輔  [E_本稼動_01537]SP専決顧客テーブル更新対応
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
 * SP専決顧客テーブル（契約管理からの更新用）のエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractSpCustsEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int SPDECISIONCUSTOMERID = 0;
  protected static final int SPDECISIONHEADERID = 1;
  protected static final int SPDECISIONCUSTOMERCLASS = 2;
  protected static final int PARTYNAME = 3;
  protected static final int PARTYNAMEALT = 4;
  protected static final int POSTALCODEFIRST = 5;
  protected static final int POSTALCODESECOND = 6;
  protected static final int POSTALCODE = 7;
  protected static final int STATE = 8;
  protected static final int CITY = 9;
  protected static final int ADDRESS1 = 10;
  protected static final int ADDRESS2 = 11;
  protected static final int ADDRESSLINESPHONETIC = 12;
  protected static final int INSTALLNAME = 13;
  protected static final int BUSINESSCONDITIONTYPE = 14;
  protected static final int BUSINESSTYPE = 15;
  protected static final int INSTALLLOCATION = 16;
  protected static final int EXTERNALREFERENCEOPCLTYPE = 17;
  protected static final int EMPLOYEENUMBER = 18;
  protected static final int PUBLISHBASECODE = 19;
  protected static final int REPRESENTATIVENAME = 20;
  protected static final int TRANSFERCOMMISSIONTYPE = 21;
  protected static final int BMPAYMENTTYPE = 22;
  protected static final int INQUIRYBASECODE = 23;
  protected static final int NEWCUSTOMERFLAG = 24;
  protected static final int CUSTOMERID = 25;
  protected static final int SAMEINSTALLACCOUNTFLAG = 26;
  protected static final int CREATEDBY = 27;
  protected static final int CREATIONDATE = 28;
  protected static final int LASTUPDATEDBY = 29;
  protected static final int LASTUPDATEDATE = 30;
  protected static final int LASTUPDATELOGIN = 31;
  protected static final int REQUESTID = 32;
  protected static final int PROGRAMAPPLICATIONID = 33;
  protected static final int PROGRAMID = 34;
  protected static final int PROGRAMUPDATEDATE = 35;




  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractSpCustsEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoContractSpCustsEO");
    }
    return mDefinitionObject;
  }








  /*****************************************************************************
   * エンティティエキスパートインスタンスの取得処理です。
   * @param txn OADBTransactionインスタンス
   *****************************************************************************
   */
  public static XxcsoCommonEntityExpert getXxcsoCommonEntityExpert(
    OADBTransaction txn
  )
  {
    return
      (XxcsoCommonEntityExpert)
        txn.getExpert(XxcsoContractSpCustsEOImpl.getDefinitionObject());
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

    XxcsoCommonEntityExpert expert = getXxcsoCommonEntityExpert(txn);
    if ( expert == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCommonEntityExpert");
    }

    // SP専決書番号を取得します。
    Number spDecisionHeaderId = getSpDecisionHeaderId();
    String spDecisionNumber = expert.getSpDecisionNumber(spDecisionHeaderId);
    
    try
    {
      super.lockRow();
    }
    catch ( AlreadyLockedException ale )
    {
      throw XxcsoMessage.createTransactionLockError(
        XxcsoConstants.TOKEN_VALUE_SP_DECISION_NUM
        + spDecisionNumber
        + XxcsoConstants.TOKEN_VALUE_DELIMITER1
        + XxcsoConstants.TOKEN_VALUE_VENDOR_INFO
      );
    }
    catch ( RowInconsistentException rie )
    {
      throw XxcsoMessage.createTransactionInconsistentError(
        XxcsoConstants.TOKEN_VALUE_SP_DECISION_NUM
        + spDecisionNumber
        + XxcsoConstants.TOKEN_VALUE_DELIMITER1
        + XxcsoConstants.TOKEN_VALUE_VENDOR_INFO
      );      
    }
    catch ( RowNotFoundException rnfe )
    {
      throw XxcsoMessage.createRecordNotFoundError(
        XxcsoConstants.TOKEN_VALUE_SP_DECISION_NUM
        + spDecisionNumber
        + XxcsoConstants.TOKEN_VALUE_DELIMITER1
        + XxcsoConstants.TOKEN_VALUE_VENDOR_INFO
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
// 2010-02-05 [E_本稼動_01537] Add Start
//    super.updateRow();
// 2010-02-05 [E_本稼動_01537] Add End

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
   * Gets the attribute value for SpDecisionCustomerId, using the alias name SpDecisionCustomerId
   */
  public Number getSpDecisionCustomerId()
  {
    return (Number)getAttributeInternal(SPDECISIONCUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpDecisionCustomerId
   */
  public void setSpDecisionCustomerId(Number value)
  {
    setAttributeInternal(SPDECISIONCUSTOMERID, value);
  }

  /**
   * 
   * Gets the attribute value for SpDecisionHeaderId, using the alias name SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for SpDecisionCustomerClass, using the alias name SpDecisionCustomerClass
   */
  public String getSpDecisionCustomerClass()
  {
    return (String)getAttributeInternal(SPDECISIONCUSTOMERCLASS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpDecisionCustomerClass
   */
  public void setSpDecisionCustomerClass(String value)
  {
    setAttributeInternal(SPDECISIONCUSTOMERCLASS, value);
  }

  /**
   * 
   * Gets the attribute value for PartyName, using the alias name PartyName
   */
  public String getPartyName()
  {
    return (String)getAttributeInternal(PARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PartyName
   */
  public void setPartyName(String value)
  {
    setAttributeInternal(PARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for PartyNameAlt, using the alias name PartyNameAlt
   */
  public String getPartyNameAlt()
  {
    return (String)getAttributeInternal(PARTYNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PartyNameAlt
   */
  public void setPartyNameAlt(String value)
  {
    setAttributeInternal(PARTYNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for PostalCodeFirst, using the alias name PostalCodeFirst
   */
  public String getPostalCodeFirst()
  {
    return (String)getAttributeInternal(POSTALCODEFIRST);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PostalCodeFirst
   */
  public void setPostalCodeFirst(String value)
  {
    setAttributeInternal(POSTALCODEFIRST, value);
  }

  /**
   * 
   * Gets the attribute value for PostalCodeSecond, using the alias name PostalCodeSecond
   */
  public String getPostalCodeSecond()
  {
    return (String)getAttributeInternal(POSTALCODESECOND);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PostalCodeSecond
   */
  public void setPostalCodeSecond(String value)
  {
    setAttributeInternal(POSTALCODESECOND, value);
  }

  /**
   * 
   * Gets the attribute value for PostalCode, using the alias name PostalCode
   */
  public String getPostalCode()
  {
    return (String)getAttributeInternal(POSTALCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PostalCode
   */
  public void setPostalCode(String value)
  {
    setAttributeInternal(POSTALCODE, value);
  }

  /**
   * 
   * Gets the attribute value for State, using the alias name State
   */
  public String getState()
  {
    return (String)getAttributeInternal(STATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for State
   */
  public void setState(String value)
  {
    setAttributeInternal(STATE, value);
  }

  /**
   * 
   * Gets the attribute value for City, using the alias name City
   */
  public String getCity()
  {
    return (String)getAttributeInternal(CITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for City
   */
  public void setCity(String value)
  {
    setAttributeInternal(CITY, value);
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
   * Gets the attribute value for AddressLinesPhonetic, using the alias name AddressLinesPhonetic
   */
  public String getAddressLinesPhonetic()
  {
    return (String)getAttributeInternal(ADDRESSLINESPHONETIC);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AddressLinesPhonetic
   */
  public void setAddressLinesPhonetic(String value)
  {
    setAttributeInternal(ADDRESSLINESPHONETIC, value);
  }

  /**
   * 
   * Gets the attribute value for InstallName, using the alias name InstallName
   */
  public String getInstallName()
  {
    return (String)getAttributeInternal(INSTALLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallName
   */
  public void setInstallName(String value)
  {
    setAttributeInternal(INSTALLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for BusinessConditionType, using the alias name BusinessConditionType
   */
  public String getBusinessConditionType()
  {
    return (String)getAttributeInternal(BUSINESSCONDITIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BusinessConditionType
   */
  public void setBusinessConditionType(String value)
  {
    setAttributeInternal(BUSINESSCONDITIONTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for BusinessType, using the alias name BusinessType
   */
  public String getBusinessType()
  {
    return (String)getAttributeInternal(BUSINESSTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BusinessType
   */
  public void setBusinessType(String value)
  {
    setAttributeInternal(BUSINESSTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for InstallLocation, using the alias name InstallLocation
   */
  public String getInstallLocation()
  {
    return (String)getAttributeInternal(INSTALLLOCATION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallLocation
   */
  public void setInstallLocation(String value)
  {
    setAttributeInternal(INSTALLLOCATION, value);
  }

  /**
   * 
   * Gets the attribute value for ExternalReferenceOpclType, using the alias name ExternalReferenceOpclType
   */
  public String getExternalReferenceOpclType()
  {
    return (String)getAttributeInternal(EXTERNALREFERENCEOPCLTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ExternalReferenceOpclType
   */
  public void setExternalReferenceOpclType(String value)
  {
    setAttributeInternal(EXTERNALREFERENCEOPCLTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for EmployeeNumber, using the alias name EmployeeNumber
   */
  public Number getEmployeeNumber()
  {
    return (Number)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for EmployeeNumber
   */
  public void setEmployeeNumber(Number value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for PublishBaseCode, using the alias name PublishBaseCode
   */
  public String getPublishBaseCode()
  {
    return (String)getAttributeInternal(PUBLISHBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PublishBaseCode
   */
  public void setPublishBaseCode(String value)
  {
    setAttributeInternal(PUBLISHBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for RepresentativeName, using the alias name RepresentativeName
   */
  public String getRepresentativeName()
  {
    return (String)getAttributeInternal(REPRESENTATIVENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RepresentativeName
   */
  public void setRepresentativeName(String value)
  {
    setAttributeInternal(REPRESENTATIVENAME, value);
  }

  /**
   * 
   * Gets the attribute value for TransferCommissionType, using the alias name TransferCommissionType
   */
  public String getTransferCommissionType()
  {
    return (String)getAttributeInternal(TRANSFERCOMMISSIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TransferCommissionType
   */
  public void setTransferCommissionType(String value)
  {
    setAttributeInternal(TRANSFERCOMMISSIONTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for BmPaymentType, using the alias name BmPaymentType
   */
  public String getBmPaymentType()
  {
    return (String)getAttributeInternal(BMPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BmPaymentType
   */
  public void setBmPaymentType(String value)
  {
    setAttributeInternal(BMPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for InquiryBaseCode, using the alias name InquiryBaseCode
   */
  public String getInquiryBaseCode()
  {
    return (String)getAttributeInternal(INQUIRYBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InquiryBaseCode
   */
  public void setInquiryBaseCode(String value)
  {
    setAttributeInternal(INQUIRYBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for NewCustomerFlag, using the alias name NewCustomerFlag
   */
  public String getNewCustomerFlag()
  {
    return (String)getAttributeInternal(NEWCUSTOMERFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NewCustomerFlag
   */
  public void setNewCustomerFlag(String value)
  {
    setAttributeInternal(NEWCUSTOMERFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for CustomerId, using the alias name CustomerId
   */
  public Number getCustomerId()
  {
    return (Number)getAttributeInternal(CUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CustomerId
   */
  public void setCustomerId(Number value)
  {
    setAttributeInternal(CUSTOMERID, value);
  }

  /**
   * 
   * Gets the attribute value for SameInstallAccountFlag, using the alias name SameInstallAccountFlag
   */
  public String getSameInstallAccountFlag()
  {
    return (String)getAttributeInternal(SAMEINSTALLACCOUNTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SameInstallAccountFlag
   */
  public void setSameInstallAccountFlag(String value)
  {
    setAttributeInternal(SAMEINSTALLACCOUNTFLAG, value);
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
      case SPDECISIONCUSTOMERID:
        return getSpDecisionCustomerId();
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case SPDECISIONCUSTOMERCLASS:
        return getSpDecisionCustomerClass();
      case PARTYNAME:
        return getPartyName();
      case PARTYNAMEALT:
        return getPartyNameAlt();
      case POSTALCODEFIRST:
        return getPostalCodeFirst();
      case POSTALCODESECOND:
        return getPostalCodeSecond();
      case POSTALCODE:
        return getPostalCode();
      case STATE:
        return getState();
      case CITY:
        return getCity();
      case ADDRESS1:
        return getAddress1();
      case ADDRESS2:
        return getAddress2();
      case ADDRESSLINESPHONETIC:
        return getAddressLinesPhonetic();
      case INSTALLNAME:
        return getInstallName();
      case BUSINESSCONDITIONTYPE:
        return getBusinessConditionType();
      case BUSINESSTYPE:
        return getBusinessType();
      case INSTALLLOCATION:
        return getInstallLocation();
      case EXTERNALREFERENCEOPCLTYPE:
        return getExternalReferenceOpclType();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case PUBLISHBASECODE:
        return getPublishBaseCode();
      case REPRESENTATIVENAME:
        return getRepresentativeName();
      case TRANSFERCOMMISSIONTYPE:
        return getTransferCommissionType();
      case BMPAYMENTTYPE:
        return getBmPaymentType();
      case INQUIRYBASECODE:
        return getInquiryBaseCode();
      case NEWCUSTOMERFLAG:
        return getNewCustomerFlag();
      case CUSTOMERID:
        return getCustomerId();
      case SAMEINSTALLACCOUNTFLAG:
        return getSameInstallAccountFlag();
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
      case SPDECISIONCUSTOMERID:
        setSpDecisionCustomerId((Number)value);
        return;
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case SPDECISIONCUSTOMERCLASS:
        setSpDecisionCustomerClass((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case PARTYNAMEALT:
        setPartyNameAlt((String)value);
        return;
      case POSTALCODEFIRST:
        setPostalCodeFirst((String)value);
        return;
      case POSTALCODESECOND:
        setPostalCodeSecond((String)value);
        return;
      case POSTALCODE:
        setPostalCode((String)value);
        return;
      case STATE:
        setState((String)value);
        return;
      case CITY:
        setCity((String)value);
        return;
      case ADDRESS1:
        setAddress1((String)value);
        return;
      case ADDRESS2:
        setAddress2((String)value);
        return;
      case ADDRESSLINESPHONETIC:
        setAddressLinesPhonetic((String)value);
        return;
      case INSTALLNAME:
        setInstallName((String)value);
        return;
      case BUSINESSCONDITIONTYPE:
        setBusinessConditionType((String)value);
        return;
      case BUSINESSTYPE:
        setBusinessType((String)value);
        return;
      case INSTALLLOCATION:
        setInstallLocation((String)value);
        return;
      case EXTERNALREFERENCEOPCLTYPE:
        setExternalReferenceOpclType((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((Number)value);
        return;
      case PUBLISHBASECODE:
        setPublishBaseCode((String)value);
        return;
      case REPRESENTATIVENAME:
        setRepresentativeName((String)value);
        return;
      case TRANSFERCOMMISSIONTYPE:
        setTransferCommissionType((String)value);
        return;
      case BMPAYMENTTYPE:
        setBmPaymentType((String)value);
        return;
      case INQUIRYBASECODE:
        setInquiryBaseCode((String)value);
        return;
      case NEWCUSTOMERFLAG:
        setNewCustomerFlag((String)value);
        return;
      case CUSTOMERID:
        setCustomerId((Number)value);
        return;
      case SAMEINSTALLACCOUNTFLAG:
        setSameInstallAccountFlag((String)value);
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
  public static Key createPrimaryKey(Number spDecisionCustomerId)
  {
    return new Key(new Object[] {spDecisionCustomerId});
  }





}
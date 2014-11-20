/*============================================================================
* ファイル名 : XxcsoSpDecisionInstCustFullVORowImpl
* 概要説明   : 設置先登録／更新用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 設置先を登録／更新するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionInstCustFullVORowImpl extends OAViewRowImpl 
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
  protected static final int INSTALLACCOUNTNUMBER = 36;
  protected static final int PUBLISHBASENAME = 37;
  protected static final int CUSTOMERSTATUS = 38;
  protected static final int PUBLISHBASECODEVIEW = 39;
  protected static final int PUBLISHBASENAMEVIEW = 40;
  protected static final int UPDATECUSTENABLE = 41;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionInstCustFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoSpDecisionCustsVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionCustsVEOImpl getXxcsoSpDecisionCustsVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionCustsVEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_CUSTOMER_ID using the alias name SpDecisionCustomerId
   */
  public Number getSpDecisionCustomerId()
  {
    return (Number)getAttributeInternal(SPDECISIONCUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_CUSTOMER_ID using the alias name SpDecisionCustomerId
   */
  public void setSpDecisionCustomerId(Number value)
  {
    setAttributeInternal(SPDECISIONCUSTOMERID, value);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_HEADER_ID using the alias name SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_HEADER_ID using the alias name SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_CUSTOMER_CLASS using the alias name SpDecisionCustomerClass
   */
  public String getSpDecisionCustomerClass()
  {
    return (String)getAttributeInternal(SPDECISIONCUSTOMERCLASS);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_CUSTOMER_CLASS using the alias name SpDecisionCustomerClass
   */
  public void setSpDecisionCustomerClass(String value)
  {
    setAttributeInternal(SPDECISIONCUSTOMERCLASS, value);
  }

  /**
   * 
   * Gets the attribute value for PARTY_NAME using the alias name PartyName
   */
  public String getPartyName()
  {
    return (String)getAttributeInternal(PARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PARTY_NAME using the alias name PartyName
   */
  public void setPartyName(String value)
  {
    setAttributeInternal(PARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for PARTY_NAME_ALT using the alias name PartyNameAlt
   */
  public String getPartyNameAlt()
  {
    return (String)getAttributeInternal(PARTYNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PARTY_NAME_ALT using the alias name PartyNameAlt
   */
  public void setPartyNameAlt(String value)
  {
    setAttributeInternal(PARTYNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for POSTAL_CODE using the alias name PostalCode
   */
  public String getPostalCode()
  {
    return (String)getAttributeInternal(POSTALCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for POSTAL_CODE using the alias name PostalCode
   */
  public void setPostalCode(String value)
  {
    setAttributeInternal(POSTALCODE, value);
  }

  /**
   * 
   * Gets the attribute value for STATE using the alias name State
   */
  public String getState()
  {
    return (String)getAttributeInternal(STATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for STATE using the alias name State
   */
  public void setState(String value)
  {
    setAttributeInternal(STATE, value);
  }

  /**
   * 
   * Gets the attribute value for CITY using the alias name City
   */
  public String getCity()
  {
    return (String)getAttributeInternal(CITY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CITY using the alias name City
   */
  public void setCity(String value)
  {
    setAttributeInternal(CITY, value);
  }

  /**
   * 
   * Gets the attribute value for ADDRESS1 using the alias name Address1
   */
  public String getAddress1()
  {
    return (String)getAttributeInternal(ADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ADDRESS1 using the alias name Address1
   */
  public void setAddress1(String value)
  {
    setAttributeInternal(ADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for ADDRESS2 using the alias name Address2
   */
  public String getAddress2()
  {
    return (String)getAttributeInternal(ADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ADDRESS2 using the alias name Address2
   */
  public void setAddress2(String value)
  {
    setAttributeInternal(ADDRESS2, value);
  }

  /**
   * 
   * Gets the attribute value for ADDRESS_LINES_PHONETIC using the alias name AddressLinesPhonetic
   */
  public String getAddressLinesPhonetic()
  {
    return (String)getAttributeInternal(ADDRESSLINESPHONETIC);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ADDRESS_LINES_PHONETIC using the alias name AddressLinesPhonetic
   */
  public void setAddressLinesPhonetic(String value)
  {
    setAttributeInternal(ADDRESSLINESPHONETIC, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_NAME using the alias name InstallName
   */
  public String getInstallName()
  {
    return (String)getAttributeInternal(INSTALLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_NAME using the alias name InstallName
   */
  public void setInstallName(String value)
  {
    setAttributeInternal(INSTALLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for BUSINESS_CONDITION_TYPE using the alias name BusinessConditionType
   */
  public String getBusinessConditionType()
  {
    return (String)getAttributeInternal(BUSINESSCONDITIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BUSINESS_CONDITION_TYPE using the alias name BusinessConditionType
   */
  public void setBusinessConditionType(String value)
  {
    setAttributeInternal(BUSINESSCONDITIONTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for BUSINESS_TYPE using the alias name BusinessType
   */
  public String getBusinessType()
  {
    return (String)getAttributeInternal(BUSINESSTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BUSINESS_TYPE using the alias name BusinessType
   */
  public void setBusinessType(String value)
  {
    setAttributeInternal(BUSINESSTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_LOCATION using the alias name InstallLocation
   */
  public String getInstallLocation()
  {
    return (String)getAttributeInternal(INSTALLLOCATION);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_LOCATION using the alias name InstallLocation
   */
  public void setInstallLocation(String value)
  {
    setAttributeInternal(INSTALLLOCATION, value);
  }

  /**
   * 
   * Gets the attribute value for EXTERNAL_REFERENCE_OPCL_TYPE using the alias name ExternalReferenceOpclType
   */
  public String getExternalReferenceOpclType()
  {
    return (String)getAttributeInternal(EXTERNALREFERENCEOPCLTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EXTERNAL_REFERENCE_OPCL_TYPE using the alias name ExternalReferenceOpclType
   */
  public void setExternalReferenceOpclType(String value)
  {
    setAttributeInternal(EXTERNALREFERENCEOPCLTYPE, value);
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
   * Gets the attribute value for PUBLISH_BASE_CODE using the alias name PublishBaseCode
   */
  public String getPublishBaseCode()
  {
    return (String)getAttributeInternal(PUBLISHBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PUBLISH_BASE_CODE using the alias name PublishBaseCode
   */
  public void setPublishBaseCode(String value)
  {
    setAttributeInternal(PUBLISHBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for REPRESENTATIVE_NAME using the alias name RepresentativeName
   */
  public String getRepresentativeName()
  {
    return (String)getAttributeInternal(REPRESENTATIVENAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for REPRESENTATIVE_NAME using the alias name RepresentativeName
   */
  public void setRepresentativeName(String value)
  {
    setAttributeInternal(REPRESENTATIVENAME, value);
  }

  /**
   * 
   * Gets the attribute value for TRANSFER_COMMISSION_TYPE using the alias name TransferCommissionType
   */
  public String getTransferCommissionType()
  {
    return (String)getAttributeInternal(TRANSFERCOMMISSIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRANSFER_COMMISSION_TYPE using the alias name TransferCommissionType
   */
  public void setTransferCommissionType(String value)
  {
    setAttributeInternal(TRANSFERCOMMISSIONTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for BM_PAYMENT_TYPE using the alias name BmPaymentType
   */
  public String getBmPaymentType()
  {
    return (String)getAttributeInternal(BMPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM_PAYMENT_TYPE using the alias name BmPaymentType
   */
  public void setBmPaymentType(String value)
  {
    setAttributeInternal(BMPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for INQUIRY_BASE_CODE using the alias name InquiryBaseCode
   */
  public String getInquiryBaseCode()
  {
    return (String)getAttributeInternal(INQUIRYBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INQUIRY_BASE_CODE using the alias name InquiryBaseCode
   */
  public void setInquiryBaseCode(String value)
  {
    setAttributeInternal(INQUIRYBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for NEW_CUSTOMER_FLAG using the alias name NewCustomerFlag
   */
  public String getNewCustomerFlag()
  {
    return (String)getAttributeInternal(NEWCUSTOMERFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEW_CUSTOMER_FLAG using the alias name NewCustomerFlag
   */
  public void setNewCustomerFlag(String value)
  {
    setAttributeInternal(NEWCUSTOMERFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for CUSTOMER_ID using the alias name CustomerId
   */
  public Number getCustomerId()
  {
    return (Number)getAttributeInternal(CUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CUSTOMER_ID using the alias name CustomerId
   */
  public void setCustomerId(Number value)
  {
    setAttributeInternal(CUSTOMERID, value);
  }

  /**
   * 
   * Gets the attribute value for SAME_INSTALL_ACCOUNT_FLAG using the alias name SameInstallAccountFlag
   */
  public String getSameInstallAccountFlag()
  {
    return (String)getAttributeInternal(SAMEINSTALLACCOUNTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SAME_INSTALL_ACCOUNT_FLAG using the alias name SameInstallAccountFlag
   */
  public void setSameInstallAccountFlag(String value)
  {
    setAttributeInternal(SAMEINSTALLACCOUNTFLAG, value);
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
      case INSTALLACCOUNTNUMBER:
        return getInstallAccountNumber();
      case PUBLISHBASENAME:
        return getPublishBaseName();
      case CUSTOMERSTATUS:
        return getCustomerStatus();
      case PUBLISHBASECODEVIEW:
        return getPublishBaseCodeView();
      case PUBLISHBASENAMEVIEW:
        return getPublishBaseNameView();
      case UPDATECUSTENABLE:
        return getUpdateCustEnable();
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
        setEmployeeNumber((String)value);
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
      case INSTALLACCOUNTNUMBER:
        setInstallAccountNumber((String)value);
        return;
      case PUBLISHBASENAME:
        setPublishBaseName((String)value);
        return;
      case CUSTOMERSTATUS:
        setCustomerStatus((String)value);
        return;
      case PUBLISHBASECODEVIEW:
        setPublishBaseCodeView((String)value);
        return;
      case PUBLISHBASENAMEVIEW:
        setPublishBaseNameView((String)value);
        return;
      case UPDATECUSTENABLE:
        setUpdateCustEnable((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAccountNumber
   */
  public String getInstallAccountNumber()
  {
    return (String)getAttributeInternal(INSTALLACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAccountNumber
   */
  public void setInstallAccountNumber(String value)
  {
    setAttributeInternal(INSTALLACCOUNTNUMBER, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute PublishBaseName
   */
  public String getPublishBaseName()
  {
    return (String)getAttributeInternal(PUBLISHBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PublishBaseName
   */
  public void setPublishBaseName(String value)
  {
    setAttributeInternal(PUBLISHBASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PostalCodeFirst
   */
  public String getPostalCodeFirst()
  {
    return (String)getAttributeInternal(POSTALCODEFIRST);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostalCodeFirst
   */
  public void setPostalCodeFirst(String value)
  {
    setAttributeInternal(POSTALCODEFIRST, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PostalCodeSecond
   */
  public String getPostalCodeSecond()
  {
    return (String)getAttributeInternal(POSTALCODESECOND);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostalCodeSecond
   */
  public void setPostalCodeSecond(String value)
  {
    setAttributeInternal(POSTALCODESECOND, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustomerStatus
   */
  public String getCustomerStatus()
  {
    return (String)getAttributeInternal(CUSTOMERSTATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomerStatus
   */
  public void setCustomerStatus(String value)
  {
    setAttributeInternal(CUSTOMERSTATUS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PublishBaseCodeView
   */
  public String getPublishBaseCodeView()
  {
    return (String)getAttributeInternal(PUBLISHBASECODEVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PublishBaseCodeView
   */
  public void setPublishBaseCodeView(String value)
  {
    setAttributeInternal(PUBLISHBASECODEVIEW, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PublishBaseNameView
   */
  public String getPublishBaseNameView()
  {
    return (String)getAttributeInternal(PUBLISHBASENAMEVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PublishBaseNameView
   */
  public void setPublishBaseNameView(String value)
  {
    setAttributeInternal(PUBLISHBASENAMEVIEW, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UpdateCustEnable
   */
  public String getUpdateCustEnable()
  {
    return (String)getAttributeInternal(UPDATECUSTENABLE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UpdateCustEnable
   */
  public void setUpdateCustEnable(String value)
  {
    setAttributeInternal(UPDATECUSTENABLE, value);
  }
}
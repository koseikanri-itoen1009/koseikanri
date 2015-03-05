/*============================================================================
* ファイル名 : XxcsoContractManagementFullVORowImpl
* 概要説明   : 契約管理テーブル情報ビュー行オブジェクトクラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
* 2015-02-02 1.1  SCSK山下翔太 [E_本稼動_12565]SP専決・契約書画面改修
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 契約管理テーブル情報ビュー行オブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractManagementFullVORowImpl extends OAViewRowImpl 
{


  protected static final int CONTRACTMANAGEMENTID = 0;
  protected static final int CONTRACTNUMBER = 1;
  protected static final int CONTRACTFORMAT = 2;
  protected static final int STATUS = 3;
  protected static final int EMPLOYEENUMBER = 4;
  protected static final int SPDECISIONHEADERID = 5;
  protected static final int CONTRACTEFFECTDATE = 6;
  protected static final int TRANSFERMONTHCODE = 7;
  protected static final int TRANSFERDAYCODE = 8;
  protected static final int CLOSEDAYCODE = 9;
  protected static final int CONTRACTPERIOD = 10;
  protected static final int CANCELLATIONOFFERCODE = 11;
  protected static final int CONTRACTCUSTOMERID = 12;
  protected static final int INSTALLACCOUNTID = 13;
  protected static final int INSTALLACCOUNTNUMBER = 14;
  protected static final int INSTALLPARTYNAME = 15;
  protected static final int INSTALLPOSTALCODE = 16;
  protected static final int INSTALLSTATE = 17;
  protected static final int INSTALLCITY = 18;
  protected static final int INSTALLADDRESS1 = 19;
  protected static final int INSTALLADDRESS2 = 20;
  protected static final int INSTALLDATE = 21;
  protected static final int INSTALLLOCATION = 22;
  protected static final int PUBLISHDEPTCODE = 23;
  protected static final int INSTALLCODE = 24;
  protected static final int COOPERATEFLAG = 25;
  protected static final int BATCHPROCSTATUS = 26;
  protected static final int CREATEDBY = 27;
  protected static final int CREATIONDATE = 28;
  protected static final int LASTUPDATEDBY = 29;
  protected static final int LASTUPDATEDATE = 30;
  protected static final int LASTUPDATELOGIN = 31;
  protected static final int REQUESTID = 32;
  protected static final int PROGRAMAPPLICATIONID = 33;
  protected static final int PROGRAMID = 34;
  protected static final int PROGRAMUPDATEDATE = 35;
  protected static final int FULLNAME = 36;
  protected static final int BASECODE = 37;
  protected static final int BASENAME = 38;
  protected static final int PUBLISHDEPTNAME = 39;
  protected static final int LOCATIONADDRESS = 40;
  protected static final int BASELEADERNAME = 41;
  protected static final int SPDECISIONNUMBER = 42;
  protected static final int CONTRACTYEARDATE = 43;
  protected static final int BASELEADERPOSITIONNAME = 44;
  protected static final int INSTANCEID = 45;
  protected static final int LATESTCONTRACTNUMBER = 46;
  protected static final int CONTRACTOTHERCUSTSID = 47;
  protected static final int XXCSOBM1DESTINATIONFULLVO = 48;
  protected static final int XXCSOBM2DESTINATIONFULLVO = 49;
  protected static final int XXCSOBM3DESTINATIONFULLVO = 50;
  protected static final int XXCSOBM1DESTINATIONFULLVO1 = 37;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractManagementFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoContractManagementsEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoContractManagementsEOImpl getXxcsoContractManagementsEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoContractManagementsEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_MANAGEMENT_ID using the alias name ContractManagementId
   */
  public Number getContractManagementId()
  {
    return (Number)getAttributeInternal(CONTRACTMANAGEMENTID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_MANAGEMENT_ID using the alias name ContractManagementId
   */
  public void setContractManagementId(Number value)
  {
    setAttributeInternal(CONTRACTMANAGEMENTID, value);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_NUMBER using the alias name ContractNumber
   */
  public String getContractNumber()
  {
    return (String)getAttributeInternal(CONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_NUMBER using the alias name ContractNumber
   */
  public void setContractNumber(String value)
  {
    setAttributeInternal(CONTRACTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_FORMAT using the alias name ContractFormat
   */
  public String getContractFormat()
  {
    return (String)getAttributeInternal(CONTRACTFORMAT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_FORMAT using the alias name ContractFormat
   */
  public void setContractFormat(String value)
  {
    setAttributeInternal(CONTRACTFORMAT, value);
  }

  /**
   * 
   * Gets the attribute value for STATUS using the alias name Status
   */
  public String getStatus()
  {
    return (String)getAttributeInternal(STATUS);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for STATUS using the alias name Status
   */
  public void setStatus(String value)
  {
    setAttributeInternal(STATUS, value);
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
   * Gets the attribute value for CONTRACT_EFFECT_DATE using the alias name ContractEffectDate
   */
  public Date getContractEffectDate()
  {
    return (Date)getAttributeInternal(CONTRACTEFFECTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_EFFECT_DATE using the alias name ContractEffectDate
   */
  public void setContractEffectDate(Date value)
  {
    setAttributeInternal(CONTRACTEFFECTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for TRANSFER_MONTH_CODE using the alias name TransferMonthCode
   */
  public String getTransferMonthCode()
  {
    return (String)getAttributeInternal(TRANSFERMONTHCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRANSFER_MONTH_CODE using the alias name TransferMonthCode
   */
  public void setTransferMonthCode(String value)
  {
    setAttributeInternal(TRANSFERMONTHCODE, value);
  }

  /**
   * 
   * Gets the attribute value for TRANSFER_DAY_CODE using the alias name TransferDayCode
   */
  public String getTransferDayCode()
  {
    return (String)getAttributeInternal(TRANSFERDAYCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRANSFER_DAY_CODE using the alias name TransferDayCode
   */
  public void setTransferDayCode(String value)
  {
    setAttributeInternal(TRANSFERDAYCODE, value);
  }

  /**
   * 
   * Gets the attribute value for CLOSE_DAY_CODE using the alias name CloseDayCode
   */
  public String getCloseDayCode()
  {
    return (String)getAttributeInternal(CLOSEDAYCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CLOSE_DAY_CODE using the alias name CloseDayCode
   */
  public void setCloseDayCode(String value)
  {
    setAttributeInternal(CLOSEDAYCODE, value);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_PERIOD using the alias name ContractPeriod
   */
  public Number getContractPeriod()
  {
    return (Number)getAttributeInternal(CONTRACTPERIOD);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_PERIOD using the alias name ContractPeriod
   */
  public void setContractPeriod(Number value)
  {
    setAttributeInternal(CONTRACTPERIOD, value);
  }

  /**
   * 
   * Gets the attribute value for CANCELLATION_OFFER_CODE using the alias name CancellationOfferCode
   */
  public String getCancellationOfferCode()
  {
    return (String)getAttributeInternal(CANCELLATIONOFFERCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CANCELLATION_OFFER_CODE using the alias name CancellationOfferCode
   */
  public void setCancellationOfferCode(String value)
  {
    setAttributeInternal(CANCELLATIONOFFERCODE, value);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_CUSTOMER_ID using the alias name ContractCustomerId
   */
  public Number getContractCustomerId()
  {
    return (Number)getAttributeInternal(CONTRACTCUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_CUSTOMER_ID using the alias name ContractCustomerId
   */
  public void setContractCustomerId(Number value)
  {
    setAttributeInternal(CONTRACTCUSTOMERID, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_ACCOUNT_ID using the alias name InstallAccountId
   */
  public Number getInstallAccountId()
  {
    return (Number)getAttributeInternal(INSTALLACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_ACCOUNT_ID using the alias name InstallAccountId
   */
  public void setInstallAccountId(Number value)
  {
    setAttributeInternal(INSTALLACCOUNTID, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_ACCOUNT_NUMBER using the alias name InstallAccountNumber
   */
  public String getInstallAccountNumber()
  {
    return (String)getAttributeInternal(INSTALLACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_ACCOUNT_NUMBER using the alias name InstallAccountNumber
   */
  public void setInstallAccountNumber(String value)
  {
    setAttributeInternal(INSTALLACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_PARTY_NAME using the alias name InstallPartyName
   */
  public String getInstallPartyName()
  {
    return (String)getAttributeInternal(INSTALLPARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_PARTY_NAME using the alias name InstallPartyName
   */
  public void setInstallPartyName(String value)
  {
    setAttributeInternal(INSTALLPARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_POSTAL_CODE using the alias name InstallPostalCode
   */
  public String getInstallPostalCode()
  {
    return (String)getAttributeInternal(INSTALLPOSTALCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_POSTAL_CODE using the alias name InstallPostalCode
   */
  public void setInstallPostalCode(String value)
  {
    setAttributeInternal(INSTALLPOSTALCODE, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_STATE using the alias name InstallState
   */
  public String getInstallState()
  {
    return (String)getAttributeInternal(INSTALLSTATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_STATE using the alias name InstallState
   */
  public void setInstallState(String value)
  {
    setAttributeInternal(INSTALLSTATE, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_CITY using the alias name InstallCity
   */
  public String getInstallCity()
  {
    return (String)getAttributeInternal(INSTALLCITY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_CITY using the alias name InstallCity
   */
  public void setInstallCity(String value)
  {
    setAttributeInternal(INSTALLCITY, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_ADDRESS1 using the alias name InstallAddress1
   */
  public String getInstallAddress1()
  {
    return (String)getAttributeInternal(INSTALLADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_ADDRESS1 using the alias name InstallAddress1
   */
  public void setInstallAddress1(String value)
  {
    setAttributeInternal(INSTALLADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_ADDRESS2 using the alias name InstallAddress2
   */
  public String getInstallAddress2()
  {
    return (String)getAttributeInternal(INSTALLADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_ADDRESS2 using the alias name InstallAddress2
   */
  public void setInstallAddress2(String value)
  {
    setAttributeInternal(INSTALLADDRESS2, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_DATE using the alias name InstallDate
   */
  public Date getInstallDate()
  {
    return (Date)getAttributeInternal(INSTALLDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_DATE using the alias name InstallDate
   */
  public void setInstallDate(Date value)
  {
    setAttributeInternal(INSTALLDATE, value);
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
   * Gets the attribute value for PUBLISH_DEPT_CODE using the alias name PublishDeptCode
   */
  public String getPublishDeptCode()
  {
    return (String)getAttributeInternal(PUBLISHDEPTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PUBLISH_DEPT_CODE using the alias name PublishDeptCode
   */
  public void setPublishDeptCode(String value)
  {
    setAttributeInternal(PUBLISHDEPTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_CODE using the alias name InstallCode
   */
  public String getInstallCode()
  {
    return (String)getAttributeInternal(INSTALLCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_CODE using the alias name InstallCode
   */
  public void setInstallCode(String value)
  {
    setAttributeInternal(INSTALLCODE, value);
  }

  /**
   * 
   * Gets the attribute value for COOPERATE_FLAG using the alias name CooperateFlag
   */
  public String getCooperateFlag()
  {
    return (String)getAttributeInternal(COOPERATEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for COOPERATE_FLAG using the alias name CooperateFlag
   */
  public void setCooperateFlag(String value)
  {
    setAttributeInternal(COOPERATEFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for BATCH_PROC_STATUS using the alias name BatchProcStatus
   */
  public String getBatchProcStatus()
  {
    return (String)getAttributeInternal(BATCHPROCSTATUS);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BATCH_PROC_STATUS using the alias name BatchProcStatus
   */
  public void setBatchProcStatus(String value)
  {
    setAttributeInternal(BATCHPROCSTATUS, value);
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

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoBm1DestinationFullVO
   */
  public oracle.jbo.RowIterator getXxcsoBm1DestinationFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOBM1DESTINATIONFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoBm1DestinationFullVO1
   */
  public oracle.jbo.RowIterator getXxcsoBm1DestinationFullVO1()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOBM1DESTINATIONFULLVO1);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoBm3DestinationFullVO
   */
  public oracle.jbo.RowIterator getXxcsoBm3DestinationFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOBM3DESTINATIONFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoBm2DestinationFullVO
   */
  public oracle.jbo.RowIterator getXxcsoBm2DestinationFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOBM2DESTINATIONFULLVO);
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
   * Gets the attribute value for the calculated attribute BaseName
   */
  public String getBaseName()
  {
    return (String)getAttributeInternal(BASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseName
   */
  public void setBaseName(String value)
  {
    setAttributeInternal(BASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PublishDeptName
   */
  public String getPublishDeptName()
  {
    return (String)getAttributeInternal(PUBLISHDEPTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PublishDeptName
   */
  public void setPublishDeptName(String value)
  {
    setAttributeInternal(PUBLISHDEPTNAME, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute BaseLeaderName
   */
  public String getBaseLeaderName()
  {
    return (String)getAttributeInternal(BASELEADERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseLeaderName
   */
  public void setBaseLeaderName(String value)
  {
    setAttributeInternal(BASELEADERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LocationAddress
   */
  public String getLocationAddress()
  {
    return (String)getAttributeInternal(LOCATIONADDRESS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LocationAddress
   */
  public void setLocationAddress(String value)
  {
    setAttributeInternal(LOCATIONADDRESS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionNumber
   */
  public String getSpDecisionNumber()
  {
    return (String)getAttributeInternal(SPDECISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionNumber
   */
  public void setSpDecisionNumber(String value)
  {
    setAttributeInternal(SPDECISIONNUMBER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute ContractYearDate
   */
  public Number getContractYearDate()
  {
    return (Number)getAttributeInternal(CONTRACTYEARDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractYearDate
   */
  public void setContractYearDate(Number value)
  {
    setAttributeInternal(CONTRACTYEARDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseLeaderPositionName
   */
  public String getBaseLeaderPositionName()
  {
    return (String)getAttributeInternal(BASELEADERPOSITIONNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseLeaderPositionName
   */
  public void setBaseLeaderPositionName(String value)
  {
    setAttributeInternal(BASELEADERPOSITIONNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstanceId
   */
  public Number getInstanceId()
  {
    return (Number)getAttributeInternal(INSTANCEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstanceId
   */
  public void setInstanceId(Number value)
  {
    setAttributeInternal(INSTANCEID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LatestContractNumber
   */
  public String getLatestContractNumber()
  {
    return (String)getAttributeInternal(LATESTCONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LatestContractNumber
   */
  public void setLatestContractNumber(String value)
  {
    setAttributeInternal(LATESTCONTRACTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractOtherCustsId
   */
  public Number getContractOtherCustsId()
  {
    return (Number)getAttributeInternal(CONTRACTOTHERCUSTSID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractOtherCustsId
   */
  public void setContractOtherCustsId(Number value)
  {
    setAttributeInternal(CONTRACTOTHERCUSTSID, value);
  }

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CONTRACTMANAGEMENTID:
        return getContractManagementId();
      case CONTRACTNUMBER:
        return getContractNumber();
      case CONTRACTFORMAT:
        return getContractFormat();
      case STATUS:
        return getStatus();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case CONTRACTEFFECTDATE:
        return getContractEffectDate();
      case TRANSFERMONTHCODE:
        return getTransferMonthCode();
      case TRANSFERDAYCODE:
        return getTransferDayCode();
      case CLOSEDAYCODE:
        return getCloseDayCode();
      case CONTRACTPERIOD:
        return getContractPeriod();
      case CANCELLATIONOFFERCODE:
        return getCancellationOfferCode();
      case CONTRACTCUSTOMERID:
        return getContractCustomerId();
      case INSTALLACCOUNTID:
        return getInstallAccountId();
      case INSTALLACCOUNTNUMBER:
        return getInstallAccountNumber();
      case INSTALLPARTYNAME:
        return getInstallPartyName();
      case INSTALLPOSTALCODE:
        return getInstallPostalCode();
      case INSTALLSTATE:
        return getInstallState();
      case INSTALLCITY:
        return getInstallCity();
      case INSTALLADDRESS1:
        return getInstallAddress1();
      case INSTALLADDRESS2:
        return getInstallAddress2();
      case INSTALLDATE:
        return getInstallDate();
      case INSTALLLOCATION:
        return getInstallLocation();
      case PUBLISHDEPTCODE:
        return getPublishDeptCode();
      case INSTALLCODE:
        return getInstallCode();
      case COOPERATEFLAG:
        return getCooperateFlag();
      case BATCHPROCSTATUS:
        return getBatchProcStatus();
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
      case FULLNAME:
        return getFullName();
      case BASECODE:
        return getBaseCode();
      case BASENAME:
        return getBaseName();
      case PUBLISHDEPTNAME:
        return getPublishDeptName();
      case LOCATIONADDRESS:
        return getLocationAddress();
      case BASELEADERNAME:
        return getBaseLeaderName();
      case SPDECISIONNUMBER:
        return getSpDecisionNumber();
      case CONTRACTYEARDATE:
        return getContractYearDate();
      case BASELEADERPOSITIONNAME:
        return getBaseLeaderPositionName();
      case INSTANCEID:
        return getInstanceId();
      case LATESTCONTRACTNUMBER:
        return getLatestContractNumber();
      case CONTRACTOTHERCUSTSID:
        return getContractOtherCustsId();
      case XXCSOBM1DESTINATIONFULLVO:
        return getXxcsoBm1DestinationFullVO();
      case XXCSOBM2DESTINATIONFULLVO:
        return getXxcsoBm2DestinationFullVO();
      case XXCSOBM3DESTINATIONFULLVO:
        return getXxcsoBm3DestinationFullVO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CONTRACTMANAGEMENTID:
        setContractManagementId((Number)value);
        return;
      case CONTRACTNUMBER:
        setContractNumber((String)value);
        return;
      case CONTRACTFORMAT:
        setContractFormat((String)value);
        return;
      case STATUS:
        setStatus((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case CONTRACTEFFECTDATE:
        setContractEffectDate((Date)value);
        return;
      case TRANSFERMONTHCODE:
        setTransferMonthCode((String)value);
        return;
      case TRANSFERDAYCODE:
        setTransferDayCode((String)value);
        return;
      case CLOSEDAYCODE:
        setCloseDayCode((String)value);
        return;
      case CONTRACTPERIOD:
        setContractPeriod((Number)value);
        return;
      case CANCELLATIONOFFERCODE:
        setCancellationOfferCode((String)value);
        return;
      case CONTRACTCUSTOMERID:
        setContractCustomerId((Number)value);
        return;
      case INSTALLACCOUNTID:
        setInstallAccountId((Number)value);
        return;
      case INSTALLACCOUNTNUMBER:
        setInstallAccountNumber((String)value);
        return;
      case INSTALLPARTYNAME:
        setInstallPartyName((String)value);
        return;
      case INSTALLPOSTALCODE:
        setInstallPostalCode((String)value);
        return;
      case INSTALLSTATE:
        setInstallState((String)value);
        return;
      case INSTALLCITY:
        setInstallCity((String)value);
        return;
      case INSTALLADDRESS1:
        setInstallAddress1((String)value);
        return;
      case INSTALLADDRESS2:
        setInstallAddress2((String)value);
        return;
      case INSTALLDATE:
        setInstallDate((Date)value);
        return;
      case INSTALLLOCATION:
        setInstallLocation((String)value);
        return;
      case PUBLISHDEPTCODE:
        setPublishDeptCode((String)value);
        return;
      case INSTALLCODE:
        setInstallCode((String)value);
        return;
      case COOPERATEFLAG:
        setCooperateFlag((String)value);
        return;
      case BATCHPROCSTATUS:
        setBatchProcStatus((String)value);
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
      case FULLNAME:
        setFullName((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case BASENAME:
        setBaseName((String)value);
        return;
      case PUBLISHDEPTNAME:
        setPublishDeptName((String)value);
        return;
      case LOCATIONADDRESS:
        setLocationAddress((String)value);
        return;
      case BASELEADERNAME:
        setBaseLeaderName((String)value);
        return;
      case SPDECISIONNUMBER:
        setSpDecisionNumber((String)value);
        return;
      case CONTRACTYEARDATE:
        setContractYearDate((Number)value);
        return;
      case BASELEADERPOSITIONNAME:
        setBaseLeaderPositionName((String)value);
        return;
      case INSTANCEID:
        setInstanceId((Number)value);
        return;
      case LATESTCONTRACTNUMBER:
        setLatestContractNumber((String)value);
        return;
      case CONTRACTOTHERCUSTSID:
        setContractOtherCustsId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

}
/*============================================================================
* ファイル名 : XxcsoContractOtherCustFullVORowImpl
* 概要説明   : 契約先以外情報取得ビュー行オブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2015-02-02 1.0  SCSK山下翔太 新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 契約先以外情報取得ビュー行オブジェクトクラス
 * @author  SCSK山下翔太
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractOtherCustFullVORowImpl extends OAViewRowImpl 
{
  protected static final int CONTRACTOTHERCUSTSID = 0;
  protected static final int INSTALLSUPPBKCHGBEARER = 1;
  protected static final int INSTALLSUPPBKNUMBER = 2;
  protected static final int INSTALLSUPPBRANCHNUMBER = 3;
  protected static final int INSTSUPPBANKNAME = 4;
  protected static final int INSTSUPPBANKBRANCHNAME = 5;
  protected static final int INSTALLSUPPBKACCTTYPE = 6;
  protected static final int INSTALLSUPPBKACCTNUMBER = 7;
  protected static final int INSTALLSUPPBKACCTNAMEALT = 8;
  protected static final int INSTALLSUPPBKACCTNAME = 9;
  protected static final int INTROCHGBKCHGBEARER = 10;
  protected static final int INTROCHGBKNUMBER = 11;
  protected static final int INTROCHGBRANCHNUMBER = 12;
  protected static final int INTROCHGBANKNAME = 13;
  protected static final int INTROCHGBANKBRANCHNAME = 14;
  protected static final int INTROCHGBKACCTTYPE = 15;
  protected static final int INTROCHGBKACCTNUMBER = 16;
  protected static final int INTROCHGBKACCTNAMEALT = 17;
  protected static final int INTROCHGBKACCTNAME = 18;
  protected static final int ELECTRICBKCHGBEARER = 19;
  protected static final int ELECTRICBKNUMBER = 20;
  protected static final int ELECTRICBRANCHNUMBER = 21;
  protected static final int ELECTRICBANKNAME = 22;
  protected static final int ELECTRICBANKBRANCHNAME = 23;
  protected static final int ELECTRICBKACCTTYPE = 24;
  protected static final int ELECTRICBKACCTNUMBER = 25;
  protected static final int ELECTRICBKACCTNAMEALT = 26;
  protected static final int ELECTRICBKACCTNAME = 27;
  protected static final int CREATEDBY = 28;
  protected static final int CREATIONDATE = 29;
  protected static final int LASTUPDATEDBY = 30;
  protected static final int LASTUPDATEDATE = 31;
  protected static final int LASTUPDATELOGIN = 32;
  protected static final int REQUESTID = 33;
  protected static final int PROGRAMAPPLICATIONID = 34;
  protected static final int PROGRAMID = 35;
  protected static final int PROGRAMUPDATEDATE = 36;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractOtherCustFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoContractOtherCustsEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoContractOtherCustsEOImpl getXxcsoContractOtherCustsEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoContractOtherCustsEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_OTHER_CUSTS_ID using the alias name ContractOtherCustsId
   */
  public Number getContractOtherCustsId()
  {
    return (Number)getAttributeInternal(CONTRACTOTHERCUSTSID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_OTHER_CUSTS_ID using the alias name ContractOtherCustsId
   */
  public void setContractOtherCustsId(Number value)
  {
    setAttributeInternal(CONTRACTOTHERCUSTSID, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPP_BK_CHG_BEARER using the alias name InstallSuppBkChgBearer
   */
  public String getInstallSuppBkChgBearer()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKCHGBEARER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPP_BK_CHG_BEARER using the alias name InstallSuppBkChgBearer
   */
  public void setInstallSuppBkChgBearer(String value)
  {
    setAttributeInternal(INSTALLSUPPBKCHGBEARER, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPP_BK_NUMBER using the alias name InstallSuppBkNumber
   */
  public String getInstallSuppBkNumber()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPP_BK_NUMBER using the alias name InstallSuppBkNumber
   */
  public void setInstallSuppBkNumber(String value)
  {
    setAttributeInternal(INSTALLSUPPBKNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPP_BRANCH_NUMBER using the alias name InstallSuppBranchNumber
   */
  public String getInstallSuppBranchNumber()
  {
    return (String)getAttributeInternal(INSTALLSUPPBRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPP_BRANCH_NUMBER using the alias name InstallSuppBranchNumber
   */
  public void setInstallSuppBranchNumber(String value)
  {
    setAttributeInternal(INSTALLSUPPBRANCHNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPP_BK_ACCT_TYPE using the alias name InstallSuppBkAcctType
   */
  public String getInstallSuppBkAcctType()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKACCTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPP_BK_ACCT_TYPE using the alias name InstallSuppBkAcctType
   */
  public void setInstallSuppBkAcctType(String value)
  {
    setAttributeInternal(INSTALLSUPPBKACCTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPP_BK_ACCT_NUMBER using the alias name InstallSuppBkAcctNumber
   */
  public String getInstallSuppBkAcctNumber()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKACCTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPP_BK_ACCT_NUMBER using the alias name InstallSuppBkAcctNumber
   */
  public void setInstallSuppBkAcctNumber(String value)
  {
    setAttributeInternal(INSTALLSUPPBKACCTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPP_BK_ACCT_NAME_ALT using the alias name InstallSuppBkAcctNameAlt
   */
  public String getInstallSuppBkAcctNameAlt()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKACCTNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPP_BK_ACCT_NAME_ALT using the alias name InstallSuppBkAcctNameAlt
   */
  public void setInstallSuppBkAcctNameAlt(String value)
  {
    setAttributeInternal(INSTALLSUPPBKACCTNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPP_BK_ACCT_NAME using the alias name InstallSuppBkAcctName
   */
  public String getInstallSuppBkAcctName()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKACCTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPP_BK_ACCT_NAME using the alias name InstallSuppBkAcctName
   */
  public void setInstallSuppBkAcctName(String value)
  {
    setAttributeInternal(INSTALLSUPPBKACCTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_BK_CHG_BEARER using the alias name IntroChgBkChgBearer
   */
  public String getIntroChgBkChgBearer()
  {
    return (String)getAttributeInternal(INTROCHGBKCHGBEARER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_BK_CHG_BEARER using the alias name IntroChgBkChgBearer
   */
  public void setIntroChgBkChgBearer(String value)
  {
    setAttributeInternal(INTROCHGBKCHGBEARER, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_BK_NUMBER using the alias name IntroChgBkNumber
   */
  public String getIntroChgBkNumber()
  {
    return (String)getAttributeInternal(INTROCHGBKNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_BK_NUMBER using the alias name IntroChgBkNumber
   */
  public void setIntroChgBkNumber(String value)
  {
    setAttributeInternal(INTROCHGBKNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_BRANCH_NUMBER using the alias name IntroChgBranchNumber
   */
  public String getIntroChgBranchNumber()
  {
    return (String)getAttributeInternal(INTROCHGBRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_BRANCH_NUMBER using the alias name IntroChgBranchNumber
   */
  public void setIntroChgBranchNumber(String value)
  {
    setAttributeInternal(INTROCHGBRANCHNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_BK_ACCT_TYPE using the alias name IntroChgBkAcctType
   */
  public String getIntroChgBkAcctType()
  {
    return (String)getAttributeInternal(INTROCHGBKACCTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_BK_ACCT_TYPE using the alias name IntroChgBkAcctType
   */
  public void setIntroChgBkAcctType(String value)
  {
    setAttributeInternal(INTROCHGBKACCTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_BK_ACCT_NUMBER using the alias name IntroChgBkAcctNumber
   */
  public String getIntroChgBkAcctNumber()
  {
    return (String)getAttributeInternal(INTROCHGBKACCTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_BK_ACCT_NUMBER using the alias name IntroChgBkAcctNumber
   */
  public void setIntroChgBkAcctNumber(String value)
  {
    setAttributeInternal(INTROCHGBKACCTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_BK_ACCT_NAME_ALT using the alias name IntroChgBkAcctNameAlt
   */
  public String getIntroChgBkAcctNameAlt()
  {
    return (String)getAttributeInternal(INTROCHGBKACCTNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_BK_ACCT_NAME_ALT using the alias name IntroChgBkAcctNameAlt
   */
  public void setIntroChgBkAcctNameAlt(String value)
  {
    setAttributeInternal(INTROCHGBKACCTNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_BK_ACCT_NAME using the alias name IntroChgBkAcctName
   */
  public String getIntroChgBkAcctName()
  {
    return (String)getAttributeInternal(INTROCHGBKACCTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_BK_ACCT_NAME using the alias name IntroChgBkAcctName
   */
  public void setIntroChgBkAcctName(String value)
  {
    setAttributeInternal(INTROCHGBKACCTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRIC_BK_CHG_BEARER using the alias name ElectricBkChgBearer
   */
  public String getElectricBkChgBearer()
  {
    return (String)getAttributeInternal(ELECTRICBKCHGBEARER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRIC_BK_CHG_BEARER using the alias name ElectricBkChgBearer
   */
  public void setElectricBkChgBearer(String value)
  {
    setAttributeInternal(ELECTRICBKCHGBEARER, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRIC_BK_NUMBER using the alias name ElectricBkNumber
   */
  public String getElectricBkNumber()
  {
    return (String)getAttributeInternal(ELECTRICBKNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRIC_BK_NUMBER using the alias name ElectricBkNumber
   */
  public void setElectricBkNumber(String value)
  {
    setAttributeInternal(ELECTRICBKNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRIC_BRANCH_NUMBER using the alias name ElectricBranchNumber
   */
  public String getElectricBranchNumber()
  {
    return (String)getAttributeInternal(ELECTRICBRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRIC_BRANCH_NUMBER using the alias name ElectricBranchNumber
   */
  public void setElectricBranchNumber(String value)
  {
    setAttributeInternal(ELECTRICBRANCHNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRIC_BK_ACCT_TYPE using the alias name ElectricBkAcctType
   */
  public String getElectricBkAcctType()
  {
    return (String)getAttributeInternal(ELECTRICBKACCTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRIC_BK_ACCT_TYPE using the alias name ElectricBkAcctType
   */
  public void setElectricBkAcctType(String value)
  {
    setAttributeInternal(ELECTRICBKACCTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRIC_BK_ACCT_NUMBER using the alias name ElectricBkAcctNumber
   */
  public String getElectricBkAcctNumber()
  {
    return (String)getAttributeInternal(ELECTRICBKACCTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRIC_BK_ACCT_NUMBER using the alias name ElectricBkAcctNumber
   */
  public void setElectricBkAcctNumber(String value)
  {
    setAttributeInternal(ELECTRICBKACCTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRIC_BK_ACCT_NAME_ALT using the alias name ElectricBkAcctNameAlt
   */
  public String getElectricBkAcctNameAlt()
  {
    return (String)getAttributeInternal(ELECTRICBKACCTNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRIC_BK_ACCT_NAME_ALT using the alias name ElectricBkAcctNameAlt
   */
  public void setElectricBkAcctNameAlt(String value)
  {
    setAttributeInternal(ELECTRICBKACCTNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRIC_BK_ACCT_NAME using the alias name ElectricBkAcctName
   */
  public String getElectricBkAcctName()
  {
    return (String)getAttributeInternal(ELECTRICBKACCTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRIC_BK_ACCT_NAME using the alias name ElectricBkAcctName
   */
  public void setElectricBkAcctName(String value)
  {
    setAttributeInternal(ELECTRICBKACCTNAME, value);
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
      case CONTRACTOTHERCUSTSID:
        return getContractOtherCustsId();
      case INSTALLSUPPBKCHGBEARER:
        return getInstallSuppBkChgBearer();
      case INSTALLSUPPBKNUMBER:
        return getInstallSuppBkNumber();
      case INSTALLSUPPBRANCHNUMBER:
        return getInstallSuppBranchNumber();
      case INSTSUPPBANKNAME:
        return getInstSuppBankName();
      case INSTSUPPBANKBRANCHNAME:
        return getInstSuppBankBranchName();
      case INSTALLSUPPBKACCTTYPE:
        return getInstallSuppBkAcctType();
      case INSTALLSUPPBKACCTNUMBER:
        return getInstallSuppBkAcctNumber();
      case INSTALLSUPPBKACCTNAMEALT:
        return getInstallSuppBkAcctNameAlt();
      case INSTALLSUPPBKACCTNAME:
        return getInstallSuppBkAcctName();
      case INTROCHGBKCHGBEARER:
        return getIntroChgBkChgBearer();
      case INTROCHGBKNUMBER:
        return getIntroChgBkNumber();
      case INTROCHGBRANCHNUMBER:
        return getIntroChgBranchNumber();
      case INTROCHGBANKNAME:
        return getIntroChgBankName();
      case INTROCHGBANKBRANCHNAME:
        return getIntroChgBankBranchName();
      case INTROCHGBKACCTTYPE:
        return getIntroChgBkAcctType();
      case INTROCHGBKACCTNUMBER:
        return getIntroChgBkAcctNumber();
      case INTROCHGBKACCTNAMEALT:
        return getIntroChgBkAcctNameAlt();
      case INTROCHGBKACCTNAME:
        return getIntroChgBkAcctName();
      case ELECTRICBKCHGBEARER:
        return getElectricBkChgBearer();
      case ELECTRICBKNUMBER:
        return getElectricBkNumber();
      case ELECTRICBRANCHNUMBER:
        return getElectricBranchNumber();
      case ELECTRICBANKNAME:
        return getElectricBankName();
      case ELECTRICBANKBRANCHNAME:
        return getElectricBankBranchName();
      case ELECTRICBKACCTTYPE:
        return getElectricBkAcctType();
      case ELECTRICBKACCTNUMBER:
        return getElectricBkAcctNumber();
      case ELECTRICBKACCTNAMEALT:
        return getElectricBkAcctNameAlt();
      case ELECTRICBKACCTNAME:
        return getElectricBkAcctName();
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
      case CONTRACTOTHERCUSTSID:
        setContractOtherCustsId((Number)value);
        return;
      case INSTALLSUPPBKCHGBEARER:
        setInstallSuppBkChgBearer((String)value);
        return;
      case INSTALLSUPPBKNUMBER:
        setInstallSuppBkNumber((String)value);
        return;
      case INSTALLSUPPBRANCHNUMBER:
        setInstallSuppBranchNumber((String)value);
        return;
      case INSTSUPPBANKNAME:
        setInstSuppBankName((String)value);
        return;
      case INSTSUPPBANKBRANCHNAME:
        setInstSuppBankBranchName((String)value);
        return;
      case INSTALLSUPPBKACCTTYPE:
        setInstallSuppBkAcctType((String)value);
        return;
      case INSTALLSUPPBKACCTNUMBER:
        setInstallSuppBkAcctNumber((String)value);
        return;
      case INSTALLSUPPBKACCTNAMEALT:
        setInstallSuppBkAcctNameAlt((String)value);
        return;
      case INSTALLSUPPBKACCTNAME:
        setInstallSuppBkAcctName((String)value);
        return;
      case INTROCHGBKCHGBEARER:
        setIntroChgBkChgBearer((String)value);
        return;
      case INTROCHGBKNUMBER:
        setIntroChgBkNumber((String)value);
        return;
      case INTROCHGBRANCHNUMBER:
        setIntroChgBranchNumber((String)value);
        return;
      case INTROCHGBANKNAME:
        setIntroChgBankName((String)value);
        return;
      case INTROCHGBANKBRANCHNAME:
        setIntroChgBankBranchName((String)value);
        return;
      case INTROCHGBKACCTTYPE:
        setIntroChgBkAcctType((String)value);
        return;
      case INTROCHGBKACCTNUMBER:
        setIntroChgBkAcctNumber((String)value);
        return;
      case INTROCHGBKACCTNAMEALT:
        setIntroChgBkAcctNameAlt((String)value);
        return;
      case INTROCHGBKACCTNAME:
        setIntroChgBkAcctName((String)value);
        return;
      case ELECTRICBKCHGBEARER:
        setElectricBkChgBearer((String)value);
        return;
      case ELECTRICBKNUMBER:
        setElectricBkNumber((String)value);
        return;
      case ELECTRICBRANCHNUMBER:
        setElectricBranchNumber((String)value);
        return;
      case ELECTRICBANKNAME:
        setElectricBankName((String)value);
        return;
      case ELECTRICBANKBRANCHNAME:
        setElectricBankBranchName((String)value);
        return;
      case ELECTRICBKACCTTYPE:
        setElectricBkAcctType((String)value);
        return;
      case ELECTRICBKACCTNUMBER:
        setElectricBkAcctNumber((String)value);
        return;
      case ELECTRICBKACCTNAMEALT:
        setElectricBkAcctNameAlt((String)value);
        return;
      case ELECTRICBKACCTNAME:
        setElectricBkAcctName((String)value);
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
   * Gets the attribute value for the calculated attribute InstSuppBankName
   */
  public String getInstSuppBankName()
  {
    return (String)getAttributeInternal(INSTSUPPBANKNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstSuppBankName
   */
  public void setInstSuppBankName(String value)
  {
    setAttributeInternal(INSTSUPPBANKNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstSuppBankBranchName
   */
  public String getInstSuppBankBranchName()
  {
    return (String)getAttributeInternal(INSTSUPPBANKBRANCHNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstSuppBankBranchName
   */
  public void setInstSuppBankBranchName(String value)
  {
    setAttributeInternal(INSTSUPPBANKBRANCHNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgBankName
   */
  public String getIntroChgBankName()
  {
    return (String)getAttributeInternal(INTROCHGBANKNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgBankName
   */
  public void setIntroChgBankName(String value)
  {
    setAttributeInternal(INTROCHGBANKNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgBankBranchName
   */
  public String getIntroChgBankBranchName()
  {
    return (String)getAttributeInternal(INTROCHGBANKBRANCHNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgBankBranchName
   */
  public void setIntroChgBankBranchName(String value)
  {
    setAttributeInternal(INTROCHGBANKBRANCHNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricBankName
   */
  public String getElectricBankName()
  {
    return (String)getAttributeInternal(ELECTRICBANKNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricBankName
   */
  public void setElectricBankName(String value)
  {
    setAttributeInternal(ELECTRICBANKNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricBankBranchName
   */
  public String getElectricBankBranchName()
  {
    return (String)getAttributeInternal(ELECTRICBANKBRANCHNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricBankBranchName
   */
  public void setElectricBankBranchName(String value)
  {
    setAttributeInternal(ELECTRICBANKBRANCHNAME, value);
  }







}
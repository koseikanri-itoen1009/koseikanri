/*============================================================================
* ファイル名 : XxcsoBm3BankAccountFullVORowImpl
* 概要説明   : BM3銀行口座アドオンテーブル情報ビュー行オブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * BM3銀行口座アドオンテーブル情報を取得するためのビュー行クラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoBm3BankAccountFullVORowImpl extends OAViewRowImpl 
{


  protected static final int BANKACCOUNTID = 0;
  protected static final int BANKNUMBER = 1;
  protected static final int BANKNAME = 2;
  protected static final int BRANCHNUMBER = 3;
  protected static final int BRANCHNAME = 4;
  protected static final int BANKACCOUNTTYPE = 5;
  protected static final int BANKACCOUNTNUMBER = 6;
  protected static final int BANKACCOUNTNAMEKANA = 7;
  protected static final int BANKACCOUNTNAMEKANJI = 8;
  protected static final int BANKACCOUNTDUMMYFLAG = 9;
  protected static final int CREATEDBY = 10;
  protected static final int CREATIONDATE = 11;
  protected static final int LASTUPDATEDBY = 12;
  protected static final int LASTUPDATEDATE = 13;
  protected static final int LASTUPDATELOGIN = 14;
  protected static final int REQUESTID = 15;
  protected static final int PROGRAMAPPLICATIONID = 16;
  protected static final int PROGRAMID = 17;
  protected static final int PROGRAMUPDATEDATE = 18;
  protected static final int DELIVERYID = 19;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoBm3BankAccountFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoBankAccountsEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoBankAccountsEOImpl getXxcsoBankAccountsEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoBankAccountsEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for BANK_ACCOUNT_ID using the alias name BankAccountId
   */
  public Number getBankAccountId()
  {
    return (Number)getAttributeInternal(BANKACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BANK_ACCOUNT_ID using the alias name BankAccountId
   */
  public void setBankAccountId(Number value)
  {
    setAttributeInternal(BANKACCOUNTID, value);
  }

  /**
   * 
   * Gets the attribute value for BANK_NUMBER using the alias name BankNumber
   */
  public String getBankNumber()
  {
    return (String)getAttributeInternal(BANKNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BANK_NUMBER using the alias name BankNumber
   */
  public void setBankNumber(String value)
  {
    setAttributeInternal(BANKNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for BANK_NAME using the alias name BankName
   */
  public String getBankName()
  {
    return (String)getAttributeInternal(BANKNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BANK_NAME using the alias name BankName
   */
  public void setBankName(String value)
  {
    setAttributeInternal(BANKNAME, value);
  }

  /**
   * 
   * Gets the attribute value for BRANCH_NUMBER using the alias name BranchNumber
   */
  public String getBranchNumber()
  {
    return (String)getAttributeInternal(BRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BRANCH_NUMBER using the alias name BranchNumber
   */
  public void setBranchNumber(String value)
  {
    setAttributeInternal(BRANCHNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for BRANCH_NAME using the alias name BranchName
   */
  public String getBranchName()
  {
    return (String)getAttributeInternal(BRANCHNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BRANCH_NAME using the alias name BranchName
   */
  public void setBranchName(String value)
  {
    setAttributeInternal(BRANCHNAME, value);
  }

  /**
   * 
   * Gets the attribute value for BANK_ACCOUNT_TYPE using the alias name BankAccountType
   */
  public String getBankAccountType()
  {
    return (String)getAttributeInternal(BANKACCOUNTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BANK_ACCOUNT_TYPE using the alias name BankAccountType
   */
  public void setBankAccountType(String value)
  {
    setAttributeInternal(BANKACCOUNTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for BANK_ACCOUNT_NUMBER using the alias name BankAccountNumber
   */
  public String getBankAccountNumber()
  {
    return (String)getAttributeInternal(BANKACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BANK_ACCOUNT_NUMBER using the alias name BankAccountNumber
   */
  public void setBankAccountNumber(String value)
  {
    setAttributeInternal(BANKACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for BANK_ACCOUNT_NAME_KANA using the alias name BankAccountNameKana
   */
  public String getBankAccountNameKana()
  {
    return (String)getAttributeInternal(BANKACCOUNTNAMEKANA);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BANK_ACCOUNT_NAME_KANA using the alias name BankAccountNameKana
   */
  public void setBankAccountNameKana(String value)
  {
    setAttributeInternal(BANKACCOUNTNAMEKANA, value);
  }

  /**
   * 
   * Gets the attribute value for BANK_ACCOUNT_NAME_KANJI using the alias name BankAccountNameKanji
   */
  public String getBankAccountNameKanji()
  {
    return (String)getAttributeInternal(BANKACCOUNTNAMEKANJI);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BANK_ACCOUNT_NAME_KANJI using the alias name BankAccountNameKanji
   */
  public void setBankAccountNameKanji(String value)
  {
    setAttributeInternal(BANKACCOUNTNAMEKANJI, value);
  }

  /**
   * 
   * Gets the attribute value for BANK_ACCOUNT_DUMMY_FLAG using the alias name BankAccountDummyFlag
   */
  public String getBankAccountDummyFlag()
  {
    return (String)getAttributeInternal(BANKACCOUNTDUMMYFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BANK_ACCOUNT_DUMMY_FLAG using the alias name BankAccountDummyFlag
   */
  public void setBankAccountDummyFlag(String value)
  {
    setAttributeInternal(BANKACCOUNTDUMMYFLAG, value);
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

  /**
   * 
   * Gets the attribute value for DELIVERY_ID using the alias name DeliveryId
   */
  public Number getDeliveryId()
  {
    return (Number)getAttributeInternal(DELIVERYID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DELIVERY_ID using the alias name DeliveryId
   */
  public void setDeliveryId(Number value)
  {
    setAttributeInternal(DELIVERYID, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BANKACCOUNTID:
        return getBankAccountId();
      case BANKNUMBER:
        return getBankNumber();
      case BANKNAME:
        return getBankName();
      case BRANCHNUMBER:
        return getBranchNumber();
      case BRANCHNAME:
        return getBranchName();
      case BANKACCOUNTTYPE:
        return getBankAccountType();
      case BANKACCOUNTNUMBER:
        return getBankAccountNumber();
      case BANKACCOUNTNAMEKANA:
        return getBankAccountNameKana();
      case BANKACCOUNTNAMEKANJI:
        return getBankAccountNameKanji();
      case BANKACCOUNTDUMMYFLAG:
        return getBankAccountDummyFlag();
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
      case DELIVERYID:
        return getDeliveryId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BANKACCOUNTID:
        setBankAccountId((Number)value);
        return;
      case BANKNUMBER:
        setBankNumber((String)value);
        return;
      case BANKNAME:
        setBankName((String)value);
        return;
      case BRANCHNUMBER:
        setBranchNumber((String)value);
        return;
      case BRANCHNAME:
        setBranchName((String)value);
        return;
      case BANKACCOUNTTYPE:
        setBankAccountType((String)value);
        return;
      case BANKACCOUNTNUMBER:
        setBankAccountNumber((String)value);
        return;
      case BANKACCOUNTNAMEKANA:
        setBankAccountNameKana((String)value);
        return;
      case BANKACCOUNTNAMEKANJI:
        setBankAccountNameKanji((String)value);
        return;
      case BANKACCOUNTDUMMYFLAG:
        setBankAccountDummyFlag((String)value);
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
      case DELIVERYID:
        setDeliveryId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
/*============================================================================
* ファイル名 : XxcsoBankAccountsEOImpl
* 概要説明   : 銀行口座アドオンテーブルエンティティクラス
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
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import com.sun.java.util.collections.Iterator;

/*******************************************************************************
 * 銀行口座アドオンテーブルのエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoBankAccountsEOImpl extends OAPlsqlEntityImpl 
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
  protected static final int XXCSODESTINATIONSEO = 20;








  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoBankAccountsEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoBankAccountsEO");
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
    EntityDefImpl bankDef = XxcsoBankAccountsEOImpl.getDefinitionObject();
    Iterator bankIt = bankDef.getAllEntityInstancesIterator(txn);

    int minValue = 0;
    
    while( bankIt.hasNext() )
    {
      XxcsoBankAccountsEOImpl bankEo = (XxcsoBankAccountsEOImpl)bankIt.next();
      int bankAccountId = bankEo.getBankAccountId().intValue();

      if ( minValue > bankAccountId )
      {
        minValue = bankAccountId;
      }
    }

    minValue--;

    XxcsoUtils.debug(txn, "new id:" + minValue);
    
    setBankAccountId(new Number(minValue));

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコードロック処理です。
   * 子テーブルなので空振りします。
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

    // 登録する直前でシーケンス値を払い出します。
    Number bankAccountId
      = getOADBTransaction().getSequenceValue("XXCSO_BANK_ACCOUNTS_S01");

    setBankAccountId(bankAccountId);

    String bankAccountNumber = getBankAccountNumber();
    if ( bankAccountNumber == null || "".equals(bankAccountNumber) )
    {
      setBankAccountDummyFlag("1");
    }
    else
    {
      setBankAccountDummyFlag("0");
    }
    
    super.insertRow();

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

    String bankAccountNumber = getBankAccountNumber();
    if ( bankAccountNumber == null || "".equals(bankAccountNumber) )
    {
      setBankAccountDummyFlag("1");
    }
    else
    {
      setBankAccountDummyFlag("0");
    }
    
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
   * Gets the attribute value for BankAccountId, using the alias name BankAccountId
   */
  public Number getBankAccountId()
  {
    return (Number)getAttributeInternal(BANKACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BankAccountId
   */
  public void setBankAccountId(Number value)
  {
    setAttributeInternal(BANKACCOUNTID, value);
  }



  /**
   * 
   * Gets the attribute value for BankNumber, using the alias name BankNumber
   */
  public String getBankNumber()
  {
    return (String)getAttributeInternal(BANKNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BankNumber
   */
  public void setBankNumber(String value)
  {
    setAttributeInternal(BANKNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for BankName, using the alias name BankName
   */
  public String getBankName()
  {
    return (String)getAttributeInternal(BANKNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BankName
   */
  public void setBankName(String value)
  {
    setAttributeInternal(BANKNAME, value);
  }

  /**
   * 
   * Gets the attribute value for BranchNumber, using the alias name BranchNumber
   */
  public String getBranchNumber()
  {
    return (String)getAttributeInternal(BRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BranchNumber
   */
  public void setBranchNumber(String value)
  {
    setAttributeInternal(BRANCHNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for BranchName, using the alias name BranchName
   */
  public String getBranchName()
  {
    return (String)getAttributeInternal(BRANCHNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BranchName
   */
  public void setBranchName(String value)
  {
    setAttributeInternal(BRANCHNAME, value);
  }

  /**
   * 
   * Gets the attribute value for BankAccountType, using the alias name BankAccountType
   */
  public String getBankAccountType()
  {
    return (String)getAttributeInternal(BANKACCOUNTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BankAccountType
   */
  public void setBankAccountType(String value)
  {
    setAttributeInternal(BANKACCOUNTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for BankAccountNumber, using the alias name BankAccountNumber
   */
  public String getBankAccountNumber()
  {
    return (String)getAttributeInternal(BANKACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BankAccountNumber
   */
  public void setBankAccountNumber(String value)
  {
    setAttributeInternal(BANKACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for BankAccountNameKana, using the alias name BankAccountNameKana
   */
  public String getBankAccountNameKana()
  {
    return (String)getAttributeInternal(BANKACCOUNTNAMEKANA);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BankAccountNameKana
   */
  public void setBankAccountNameKana(String value)
  {
    setAttributeInternal(BANKACCOUNTNAMEKANA, value);
  }

  /**
   * 
   * Gets the attribute value for BankAccountNameKanji, using the alias name BankAccountNameKanji
   */
  public String getBankAccountNameKanji()
  {
    return (String)getAttributeInternal(BANKACCOUNTNAMEKANJI);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BankAccountNameKanji
   */
  public void setBankAccountNameKanji(String value)
  {
    setAttributeInternal(BANKACCOUNTNAMEKANJI, value);
  }

  /**
   * 
   * Gets the attribute value for BankAccountDummyFlag, using the alias name BankAccountDummyFlag
   */
  public String getBankAccountDummyFlag()
  {
    return (String)getAttributeInternal(BANKACCOUNTDUMMYFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BankAccountDummyFlag
   */
  public void setBankAccountDummyFlag(String value)
  {
    setAttributeInternal(BANKACCOUNTDUMMYFLAG, value);
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
      case XXCSODESTINATIONSEO:
        return getXxcsoDestinationsEO();
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


  /**
   * 
   * Gets the attribute value for DeliveryId, using the alias name DeliveryId
   */
  public Number getDeliveryId()
  {
    return (Number)getAttributeInternal(DELIVERYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for DeliveryId
   */
  public void setDeliveryId(Number value)
  {
    setAttributeInternal(DELIVERYID, value);
  }


  /**
   * 
   * Gets the associated entity XxcsoDestinationsEOImpl
   */
  public XxcsoDestinationsEOImpl getXxcsoDestinationsEO()
  {
    return (XxcsoDestinationsEOImpl)getAttributeInternal(XXCSODESTINATIONSEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoDestinationsEOImpl
   */
  public void setXxcsoDestinationsEO(XxcsoDestinationsEOImpl value)
  {
    setAttributeInternal(XXCSODESTINATIONSEO, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number bankAccountId)
  {
    return new Key(new Object[] {bankAccountId});
  }










}
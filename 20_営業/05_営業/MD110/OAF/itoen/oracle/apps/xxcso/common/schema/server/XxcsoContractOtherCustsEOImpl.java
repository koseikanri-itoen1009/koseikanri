/*============================================================================
* ファイル名 : XxcsoContractOtherCustsEOImpl
* 概要説明   : 契約先以外テーブルエンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者        修正内容
* ---------- ---- ------------- ---------------------------------------------
* 2015-02-02 1.0  SCSK山下翔太  新規作成
*=============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import com.sun.java.util.collections.Iterator;

import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;

import oracle.jbo.AttributeList;
import oracle.jbo.Key;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.server.EntityDefImpl;

/*******************************************************************************
 * 契約先以外テーブルのエンティティクラスです。
 * @author  SCSK山下翔太
 * @version 1.0
 *******************************************************************************
*/
public class XxcsoContractOtherCustsEOImpl extends OAPlsqlEntityImpl
{
  protected static final int CONTRACTOTHERCUSTSID = 0;
  protected static final int INSTALLSUPPBKCHGBEARER = 1;
  protected static final int INSTALLSUPPBKNUMBER = 2;
  protected static final int INSTALLSUPPBRANCHNUMBER = 3;
  protected static final int INSTALLSUPPBKACCTTYPE = 4;
  protected static final int INSTALLSUPPBKACCTNUMBER = 5;
  protected static final int INSTALLSUPPBKACCTNAMEALT = 6;
  protected static final int INSTALLSUPPBKACCTNAME = 7;
  protected static final int INTROCHGBKCHGBEARER = 8;
  protected static final int INTROCHGBKNUMBER = 9;
  protected static final int INTROCHGBRANCHNUMBER = 10;
  protected static final int INTROCHGBKACCTTYPE = 11;
  protected static final int INTROCHGBKACCTNUMBER = 12;
  protected static final int INTROCHGBKACCTNAMEALT = 13;
  protected static final int INTROCHGBKACCTNAME = 14;
  protected static final int ELECTRICBKCHGBEARER = 15;
  protected static final int ELECTRICBKNUMBER = 16;
  protected static final int ELECTRICBRANCHNUMBER = 17;
  protected static final int ELECTRICBKACCTTYPE = 18;
  protected static final int ELECTRICBKACCTNUMBER = 19;
  protected static final int ELECTRICBKACCTNAMEALT = 20;
  protected static final int ELECTRICBKACCTNAME = 21;
  protected static final int CREATEDBY = 22;
  protected static final int CREATIONDATE = 23;
  protected static final int LASTUPDATEDBY = 24;
  protected static final int LASTUPDATEDATE = 25;
  protected static final int LASTUPDATELOGIN = 26;
  protected static final int REQUESTID = 27;
  protected static final int PROGRAMAPPLICATIONID = 28;
  protected static final int PROGRAMID = 29;
  protected static final int PROGRAMUPDATEDATE = 30;
  protected static final int CONTRACTOTHERCUSTSIDXXCSOCONTRACTMANAGEMENTSEO = 31;

  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractOtherCustsEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoContractOtherCustsEO");
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
        txn.getExpert(XxcsoContractManagementsEOImpl.getDefinitionObject());
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
    setContractOtherCustsId(new Number(-1));

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

    XxcsoCommonEntityExpert expert = getXxcsoCommonEntityExpert(txn);
    if ( expert == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCommonEntityExpert");
    }

    // 登録する直前でシーケンス値を払い出します。
    Number ContractOtherCustsId
      = getOADBTransaction().getSequenceValue("XXCSO_CONTRACT_OTHER_CUSTS_S01");
    
    // //////////////////////////////
    // 契約先以外IDの設定
    // //////////////////////////////
    EntityDefImpl contractMngDef = XxcsoContractManagementsEOImpl.getDefinitionObject();
    Iterator contractMngIt = contractMngDef.getAllEntityInstancesIterator(txn);
    
    Number dummyId = getContractOtherCustsId();

    // 契約先以外テーブル
    setContractOtherCustsId(ContractOtherCustsId);
    
    while ( contractMngIt.hasNext() )
    {
      XxcsoContractManagementsEOImpl contractMngEo
        = (XxcsoContractManagementsEOImpl)contractMngIt.next();
      if ( contractMngEo.getContractOtherCustsId() == null)
      {
        // 契約管理テーブル
        contractMngEo.setContractOtherCustsId(ContractOtherCustsId);
        break;
      }
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
   * Gets the attribute value for ContractOtherCustsId, using the alias name ContractOtherCustsId
   */
  public Number getContractOtherCustsId()
  {
    return (Number)getAttributeInternal(CONTRACTOTHERCUSTSID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractOtherCustsId
   */
  public void setContractOtherCustsId(Number value)
  {
    setAttributeInternal(CONTRACTOTHERCUSTSID, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppBkChgBearer, using the alias name InstallSuppBkChgBearer
   */
  public String getInstallSuppBkChgBearer()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKCHGBEARER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppBkChgBearer
   */
  public void setInstallSuppBkChgBearer(String value)
  {
    setAttributeInternal(INSTALLSUPPBKCHGBEARER, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppBkNumber, using the alias name InstallSuppBkNumber
   */
  public String getInstallSuppBkNumber()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppBkNumber
   */
  public void setInstallSuppBkNumber(String value)
  {
    setAttributeInternal(INSTALLSUPPBKNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppBranchNumber, using the alias name InstallSuppBranchNumber
   */
  public String getInstallSuppBranchNumber()
  {
    return (String)getAttributeInternal(INSTALLSUPPBRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppBranchNumber
   */
  public void setInstallSuppBranchNumber(String value)
  {
    setAttributeInternal(INSTALLSUPPBRANCHNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppBkAcctType, using the alias name InstallSuppBkAcctType
   */
  public String getInstallSuppBkAcctType()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKACCTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppBkAcctType
   */
  public void setInstallSuppBkAcctType(String value)
  {
    setAttributeInternal(INSTALLSUPPBKACCTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppBkAcctNumber, using the alias name InstallSuppBkAcctNumber
   */
  public String getInstallSuppBkAcctNumber()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKACCTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppBkAcctNumber
   */
  public void setInstallSuppBkAcctNumber(String value)
  {
    setAttributeInternal(INSTALLSUPPBKACCTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppBkAcctNameAlt, using the alias name InstallSuppBkAcctNameAlt
   */
  public String getInstallSuppBkAcctNameAlt()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKACCTNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppBkAcctNameAlt
   */
  public void setInstallSuppBkAcctNameAlt(String value)
  {
    setAttributeInternal(INSTALLSUPPBKACCTNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppBkAcctName, using the alias name InstallSuppBkAcctName
   */
  public String getInstallSuppBkAcctName()
  {
    return (String)getAttributeInternal(INSTALLSUPPBKACCTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppBkAcctName
   */
  public void setInstallSuppBkAcctName(String value)
  {
    setAttributeInternal(INSTALLSUPPBKACCTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgBkChgBearer, using the alias name IntroChgBkChgBearer
   */
  public String getIntroChgBkChgBearer()
  {
    return (String)getAttributeInternal(INTROCHGBKCHGBEARER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgBkChgBearer
   */
  public void setIntroChgBkChgBearer(String value)
  {
    setAttributeInternal(INTROCHGBKCHGBEARER, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgBkNumber, using the alias name IntroChgBkNumber
   */
  public String getIntroChgBkNumber()
  {
    return (String)getAttributeInternal(INTROCHGBKNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgBkNumber
   */
  public void setIntroChgBkNumber(String value)
  {
    setAttributeInternal(INTROCHGBKNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgBranchNumber, using the alias name IntroChgBranchNumber
   */
  public String getIntroChgBranchNumber()
  {
    return (String)getAttributeInternal(INTROCHGBRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgBranchNumber
   */
  public void setIntroChgBranchNumber(String value)
  {
    setAttributeInternal(INTROCHGBRANCHNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgBkAcctType, using the alias name IntroChgBkAcctType
   */
  public String getIntroChgBkAcctType()
  {
    return (String)getAttributeInternal(INTROCHGBKACCTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgBkAcctType
   */
  public void setIntroChgBkAcctType(String value)
  {
    setAttributeInternal(INTROCHGBKACCTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgBkAcctNumber, using the alias name IntroChgBkAcctNumber
   */
  public String getIntroChgBkAcctNumber()
  {
    return (String)getAttributeInternal(INTROCHGBKACCTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgBkAcctNumber
   */
  public void setIntroChgBkAcctNumber(String value)
  {
    setAttributeInternal(INTROCHGBKACCTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgBkAcctNameAlt, using the alias name IntroChgBkAcctNameAlt
   */
  public String getIntroChgBkAcctNameAlt()
  {
    return (String)getAttributeInternal(INTROCHGBKACCTNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgBkAcctNameAlt
   */
  public void setIntroChgBkAcctNameAlt(String value)
  {
    setAttributeInternal(INTROCHGBKACCTNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgBkAcctName, using the alias name IntroChgBkAcctName
   */
  public String getIntroChgBkAcctName()
  {
    return (String)getAttributeInternal(INTROCHGBKACCTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgBkAcctName
   */
  public void setIntroChgBkAcctName(String value)
  {
    setAttributeInternal(INTROCHGBKACCTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricBkChgBearer, using the alias name ElectricBkChgBearer
   */
  public String getElectricBkChgBearer()
  {
    return (String)getAttributeInternal(ELECTRICBKCHGBEARER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricBkChgBearer
   */
  public void setElectricBkChgBearer(String value)
  {
    setAttributeInternal(ELECTRICBKCHGBEARER, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricBkNumber, using the alias name ElectricBkNumber
   */
  public String getElectricBkNumber()
  {
    return (String)getAttributeInternal(ELECTRICBKNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricBkNumber
   */
  public void setElectricBkNumber(String value)
  {
    setAttributeInternal(ELECTRICBKNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricBranchNumber, using the alias name ElectricBranchNumber
   */
  public String getElectricBranchNumber()
  {
    return (String)getAttributeInternal(ELECTRICBRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricBranchNumber
   */
  public void setElectricBranchNumber(String value)
  {
    setAttributeInternal(ELECTRICBRANCHNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricBkAcctType, using the alias name ElectricBkAcctType
   */
  public String getElectricBkAcctType()
  {
    return (String)getAttributeInternal(ELECTRICBKACCTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricBkAcctType
   */
  public void setElectricBkAcctType(String value)
  {
    setAttributeInternal(ELECTRICBKACCTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricBkAcctNumber, using the alias name ElectricBkAcctNumber
   */
  public String getElectricBkAcctNumber()
  {
    return (String)getAttributeInternal(ELECTRICBKACCTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricBkAcctNumber
   */
  public void setElectricBkAcctNumber(String value)
  {
    setAttributeInternal(ELECTRICBKACCTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricBkAcctNameAlt, using the alias name ElectricBkAcctNameAlt
   */
  public String getElectricBkAcctNameAlt()
  {
    return (String)getAttributeInternal(ELECTRICBKACCTNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricBkAcctNameAlt
   */
  public void setElectricBkAcctNameAlt(String value)
  {
    setAttributeInternal(ELECTRICBKACCTNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricBkAcctName, using the alias name ElectricBkAcctName
   */
  public String getElectricBkAcctName()
  {
    return (String)getAttributeInternal(ELECTRICBKACCTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricBkAcctName
   */
  public void setElectricBkAcctName(String value)
  {
    setAttributeInternal(ELECTRICBKACCTNAME, value);
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
      case CONTRACTOTHERCUSTSID:
        return getContractOtherCustsId();
      case INSTALLSUPPBKCHGBEARER:
        return getInstallSuppBkChgBearer();
      case INSTALLSUPPBKNUMBER:
        return getInstallSuppBkNumber();
      case INSTALLSUPPBRANCHNUMBER:
        return getInstallSuppBranchNumber();
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
      case CONTRACTOTHERCUSTSIDXXCSOCONTRACTMANAGEMENTSEO:
        return getContractOtherCustsIdXxcsoContractManagementsEO();
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
   * Gets the associated entity XxcsoContractManagementsEOImpl
   */
  public XxcsoContractManagementsEOImpl getContractOtherCustsIdXxcsoContractManagementsEO()
  {
    return (XxcsoContractManagementsEOImpl)getAttributeInternal(CONTRACTOTHERCUSTSIDXXCSOCONTRACTMANAGEMENTSEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoContractManagementsEOImpl
   */
  public void setContractOtherCustsIdXxcsoContractManagementsEO(XxcsoContractManagementsEOImpl value)
  {
    setAttributeInternal(CONTRACTOTHERCUSTSIDXXCSOCONTRACTMANAGEMENTSEO, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number contractOtherCustsId)
  {
    return new Key(new Object[] {contractOtherCustsId});
  }






















































}
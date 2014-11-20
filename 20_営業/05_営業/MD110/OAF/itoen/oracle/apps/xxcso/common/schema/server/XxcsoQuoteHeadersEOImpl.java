/*============================================================================
* ファイル名 : XxcsoQuoteHeadersEOImpl
* 概要説明   : 見積ヘッダーエンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
import oracle.jbo.RowIterator;

import oracle.jbo.AttributeList;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import oracle.jbo.AlreadyLockedException;
import oracle.jbo.RowNotFoundException;
import oracle.jbo.RowInconsistentException;

/*******************************************************************************
 * 見積ヘッダーのエンティティクラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteHeadersEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int QUOTEHEADERID = 0;
  protected static final int QUOTETYPE = 1;
  protected static final int QUOTENUMBER = 2;
  protected static final int QUOTEREVISIONNUMBER = 3;
  protected static final int REFERENCEQUOTENUMBER = 4;
  protected static final int REFERENCEQUOTEHEADERID = 5;
  protected static final int PUBLISHDATE = 6;
  protected static final int ACCOUNTNUMBER = 7;
  protected static final int EMPLOYEENUMBER = 8;
  protected static final int BASECODE = 9;
  protected static final int DELIVPLACE = 10;
  protected static final int PAYMENTCONDITION = 11;
  protected static final int QUOTESUBMITNAME = 12;
  protected static final int STATUS = 13;
  protected static final int DELIVPRICETAXTYPE = 14;
  protected static final int STOREPRICETAXTYPE = 15;
  protected static final int UNITTYPE = 16;
  protected static final int SPECIALNOTE = 17;
  protected static final int QUOTEINFOSTARTDATE = 18;
  protected static final int QUOTEINFOENDDATE = 19;
  protected static final int CREATEDBY = 20;
  protected static final int CREATIONDATE = 21;
  protected static final int LASTUPDATEDBY = 22;
  protected static final int LASTUPDATEDATE = 23;
  protected static final int LASTUPDATELOGIN = 24;
  protected static final int REQUESTID = 25;
  protected static final int PROGRAMAPPLICATIONID = 26;
  protected static final int PROGRAMID = 27;
  protected static final int PROGRAMUPDATEDATE = 28;
  protected static final int XXCSOQUOTELINESSALESVEO = 29;
  protected static final int XXCSOQUOTELINESSTOREVEO = 30;








































  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteHeadersEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoQuoteHeadersEO");
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
        txn.getExpert(XxcsoQuoteHeadersEOImpl.getDefinitionObject());
  }

  /*****************************************************************************
   * エンティティの作成処理です。
   * @param list 属性リスト
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    super.create(list);
    // 仮の値を設定します。
    setQuoteHeaderId(new Number(-1));

    //初期値の設定
    setQuoteRevisionNumber(new Number(1));

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * レコード作成処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    try
    {
      super.lockRow();
    }
    catch ( AlreadyLockedException ale )
    {
      throw XxcsoMessage.createTransactionLockError(
        XxcsoConstants.TOKEN_VALUE_QUOTE_NUMBER
          + getQuoteNumber()
      );
    }
    catch ( RowInconsistentException rie )
    {
      throw XxcsoMessage.createTransactionInconsistentError(
        XxcsoConstants.TOKEN_VALUE_QUOTE_NUMBER
          + getQuoteNumber()
      );      
    }
    catch ( RowNotFoundException rnfe )
    {
      throw XxcsoMessage.createRecordNotFoundError(
        XxcsoConstants.TOKEN_VALUE_QUOTE_NUMBER
          + getQuoteNumber()
      );      
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * レコード作成処理です。
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoCommonEntityExpert expert = getXxcsoCommonEntityExpert(txn);
    Date currentDate = expert.getOnlineSysdate();
    String quoteNumber
      = expert.getAutoAssignedCode(
          "1"
         ,getBaseCode()
         ,currentDate
        );
    XxcsoUtils.debug(txn, "システム日付" + currentDate);

    Date QuoteStartInfoDate = currentDate;
    Date QuoteInfoDate      = new Date(expert.getOnlineSysdate());
    Date QuoteEndInfoDate   = (Date)QuoteInfoDate.addMonths(12);

    XxcsoUtils.debug(txn, "システム日付" + currentDate);
    // 登録する直前でシーケンス値を払い出します。
    Number quoteHeaderId
      = getOADBTransaction().getSequenceValue("XXCSO_QUOTE_HEADERS_S01");

    setQuoteHeaderId(quoteHeaderId);
    //見積番号が画面に表示されていない場合取得
    if ( getQuoteNumber() == null )
    {
      setQuoteNumber(quoteNumber);
    }

    setQuoteInfoStartDate(QuoteStartInfoDate);
    setQuoteInfoEndDate(QuoteEndInfoDate);

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

    super.deleteRow();

    XxcsoUtils.debug(txn, "[END]");
  }




  /**
   * 
   * Gets the attribute value for QuoteHeaderId, using the alias name QuoteHeaderId
   */
  public Number getQuoteHeaderId()
  {
    return (Number)getAttributeInternal(QUOTEHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteHeaderId
   */
  public void setQuoteHeaderId(Number value)
  {
    setAttributeInternal(QUOTEHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteType, using the alias name QuoteType
   */
  public String getQuoteType()
  {
    return (String)getAttributeInternal(QUOTETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteType
   */
  public void setQuoteType(String value)
  {
    setAttributeInternal(QUOTETYPE, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteNumber, using the alias name QuoteNumber
   */
  public String getQuoteNumber()
  {
    return (String)getAttributeInternal(QUOTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteNumber
   */
  public void setQuoteNumber(String value)
  {
    setAttributeInternal(QUOTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteRevisionNumber, using the alias name QuoteRevisionNumber
   */
  public Number getQuoteRevisionNumber()
  {
    return (Number)getAttributeInternal(QUOTEREVISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteRevisionNumber
   */
  public void setQuoteRevisionNumber(Number value)
  {
    setAttributeInternal(QUOTEREVISIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ReferenceQuoteNumber, using the alias name ReferenceQuoteNumber
   */
  public String getReferenceQuoteNumber()
  {
    return (String)getAttributeInternal(REFERENCEQUOTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ReferenceQuoteNumber
   */
  public void setReferenceQuoteNumber(String value)
  {
    setAttributeInternal(REFERENCEQUOTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ReferenceQuoteHeaderId, using the alias name ReferenceQuoteHeaderId
   */
  public Number getReferenceQuoteHeaderId()
  {
    return (Number)getAttributeInternal(REFERENCEQUOTEHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ReferenceQuoteHeaderId
   */
  public void setReferenceQuoteHeaderId(Number value)
  {
    setAttributeInternal(REFERENCEQUOTEHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for PublishDate, using the alias name PublishDate
   */
  public Date getPublishDate()
  {
    return (Date)getAttributeInternal(PUBLISHDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PublishDate
   */
  public void setPublishDate(Date value)
  {
    setAttributeInternal(PUBLISHDATE, value);
  }

  /**
   * 
   * Gets the attribute value for AccountNumber, using the alias name AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
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
   * Gets the attribute value for DelivPlace, using the alias name DelivPlace
   */
  public String getDelivPlace()
  {
    return (String)getAttributeInternal(DELIVPLACE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for DelivPlace
   */
  public void setDelivPlace(String value)
  {
    setAttributeInternal(DELIVPLACE, value);
  }

  /**
   * 
   * Gets the attribute value for PaymentCondition, using the alias name PaymentCondition
   */
  public String getPaymentCondition()
  {
    return (String)getAttributeInternal(PAYMENTCONDITION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PaymentCondition
   */
  public void setPaymentCondition(String value)
  {
    setAttributeInternal(PAYMENTCONDITION, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteSubmitName, using the alias name QuoteSubmitName
   */
  public String getQuoteSubmitName()
  {
    return (String)getAttributeInternal(QUOTESUBMITNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteSubmitName
   */
  public void setQuoteSubmitName(String value)
  {
    setAttributeInternal(QUOTESUBMITNAME, value);
  }

  /**
   * 
   * Gets the attribute value for Status, using the alias name Status
   */
  public String getStatus()
  {
    return (String)getAttributeInternal(STATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Status
   */
  public void setStatus(String value)
  {
    setAttributeInternal(STATUS, value);
  }

  /**
   * 
   * Gets the attribute value for DelivPriceTaxType, using the alias name DelivPriceTaxType
   */
  public String getDelivPriceTaxType()
  {
    return (String)getAttributeInternal(DELIVPRICETAXTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for DelivPriceTaxType
   */
  public void setDelivPriceTaxType(String value)
  {
    setAttributeInternal(DELIVPRICETAXTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for StorePriceTaxType, using the alias name StorePriceTaxType
   */
  public String getStorePriceTaxType()
  {
    return (String)getAttributeInternal(STOREPRICETAXTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for StorePriceTaxType
   */
  public void setStorePriceTaxType(String value)
  {
    setAttributeInternal(STOREPRICETAXTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for UnitType, using the alias name UnitType
   */
  public String getUnitType()
  {
    return (String)getAttributeInternal(UNITTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for UnitType
   */
  public void setUnitType(String value)
  {
    setAttributeInternal(UNITTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for SpecialNote, using the alias name SpecialNote
   */
  public String getSpecialNote()
  {
    return (String)getAttributeInternal(SPECIALNOTE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpecialNote
   */
  public void setSpecialNote(String value)
  {
    setAttributeInternal(SPECIALNOTE, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteInfoStartDate, using the alias name QuoteInfoStartDate
   */
  public Date getQuoteInfoStartDate()
  {
    return (Date)getAttributeInternal(QUOTEINFOSTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteInfoStartDate
   */
  public void setQuoteInfoStartDate(Date value)
  {
    setAttributeInternal(QUOTEINFOSTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteInfoEndDate, using the alias name QuoteInfoEndDate
   */
  public Date getQuoteInfoEndDate()
  {
    return (Date)getAttributeInternal(QUOTEINFOENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteInfoEndDate
   */
  public void setQuoteInfoEndDate(Date value)
  {
    setAttributeInternal(QUOTEINFOENDDATE, value);
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
      case QUOTEHEADERID:
        return getQuoteHeaderId();
      case QUOTETYPE:
        return getQuoteType();
      case QUOTENUMBER:
        return getQuoteNumber();
      case QUOTEREVISIONNUMBER:
        return getQuoteRevisionNumber();
      case REFERENCEQUOTENUMBER:
        return getReferenceQuoteNumber();
      case REFERENCEQUOTEHEADERID:
        return getReferenceQuoteHeaderId();
      case PUBLISHDATE:
        return getPublishDate();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case BASECODE:
        return getBaseCode();
      case DELIVPLACE:
        return getDelivPlace();
      case PAYMENTCONDITION:
        return getPaymentCondition();
      case QUOTESUBMITNAME:
        return getQuoteSubmitName();
      case STATUS:
        return getStatus();
      case DELIVPRICETAXTYPE:
        return getDelivPriceTaxType();
      case STOREPRICETAXTYPE:
        return getStorePriceTaxType();
      case UNITTYPE:
        return getUnitType();
      case SPECIALNOTE:
        return getSpecialNote();
      case QUOTEINFOSTARTDATE:
        return getQuoteInfoStartDate();
      case QUOTEINFOENDDATE:
        return getQuoteInfoEndDate();
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
      case XXCSOQUOTELINESSALESVEO:
        return getXxcsoQuoteLinesSalesVEO();
      case XXCSOQUOTELINESSTOREVEO:
        return getXxcsoQuoteLinesStoreVEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTEHEADERID:
        setQuoteHeaderId((Number)value);
        return;
      case QUOTETYPE:
        setQuoteType((String)value);
        return;
      case QUOTENUMBER:
        setQuoteNumber((String)value);
        return;
      case QUOTEREVISIONNUMBER:
        setQuoteRevisionNumber((Number)value);
        return;
      case REFERENCEQUOTENUMBER:
        setReferenceQuoteNumber((String)value);
        return;
      case REFERENCEQUOTEHEADERID:
        setReferenceQuoteHeaderId((Number)value);
        return;
      case PUBLISHDATE:
        setPublishDate((Date)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case DELIVPLACE:
        setDelivPlace((String)value);
        return;
      case PAYMENTCONDITION:
        setPaymentCondition((String)value);
        return;
      case QUOTESUBMITNAME:
        setQuoteSubmitName((String)value);
        return;
      case STATUS:
        setStatus((String)value);
        return;
      case DELIVPRICETAXTYPE:
        setDelivPriceTaxType((String)value);
        return;
      case STOREPRICETAXTYPE:
        setStorePriceTaxType((String)value);
        return;
      case UNITTYPE:
        setUnitType((String)value);
        return;
      case SPECIALNOTE:
        setSpecialNote((String)value);
        return;
      case QUOTEINFOSTARTDATE:
        setQuoteInfoStartDate((Date)value);
        return;
      case QUOTEINFOENDDATE:
        setQuoteInfoEndDate((Date)value);
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
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoQuoteLinesSalesVEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOQUOTELINESSALESVEO);
  }


  /**
   * 
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoQuoteLinesStoreVEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOQUOTELINESSTOREVEO);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number quoteHeaderId)
  {
    return new Key(new Object[] {quoteHeaderId});
  }















































}
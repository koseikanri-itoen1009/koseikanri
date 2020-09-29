/*============================================================================
* ファイル名 : XxcsoDestinationsEOImpl
* 概要説明   : 送付先テーブルエンティティクラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-22 1.0  SCS小川浩    新規作成
* 2020-08-21 1.1  SCSK佐々木大和[E_本稼動_15904]税抜きでの自販機BM計算について
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
 * 送付先テーブルのエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoDestinationsEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int DELIVERYID = 0;
  protected static final int CONTRACTMANAGEMENTID = 1;
  protected static final int SUPPLIERID = 2;
  protected static final int DELIVERYDIV = 3;
  protected static final int PAYMENTNAME = 4;
  protected static final int PAYMENTNAMEALT = 5;
  protected static final int BANKTRANSFERFEECHARGEDIV = 6;
  protected static final int BELLINGDETAILSDIV = 7;
  protected static final int INQUERYCHARGEHUBCD = 8;
  protected static final int POSTCODE = 9;
  protected static final int PREFECTURES = 10;
  protected static final int CITYWARD = 11;
  protected static final int ADDRESS1 = 12;
  protected static final int ADDRESS2 = 13;
  protected static final int ADDRESSLINESPHONETIC = 14;
  protected static final int CREATEDBY = 15;
  protected static final int CREATIONDATE = 16;
  protected static final int LASTUPDATEDBY = 17;
  protected static final int LASTUPDATEDATE = 18;
  protected static final int LASTUPDATELOGIN = 19;
  protected static final int REQUESTID = 20;
  protected static final int PROGRAMAPPLICATIONID = 21;
  protected static final int PROGRAMID = 22;
  protected static final int PROGRAMUPDATEDATE = 23;
  protected static final int BMTAXKBN = 24;
  protected static final int XXCSOCONTRACTMANAGEMENTSEO = 25;
  protected static final int XXCSOBANKACCOUNTSEO = 26;























  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoDestinationsEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoDestinationsEO");
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
    EntityDefImpl destDef = XxcsoDestinationsEOImpl.getDefinitionObject();
    Iterator destIt = destDef.getAllEntityInstancesIterator(txn);

    int minValue = 0;
    
    while( destIt.hasNext() )
    {
      XxcsoDestinationsEOImpl destEo = (XxcsoDestinationsEOImpl)destIt.next();
      int deliveryId = destEo.getDeliveryId().intValue();

      if ( minValue > deliveryId )
      {
        minValue = deliveryId;
      }
    }

    minValue--;

    XxcsoUtils.debug(txn, "new id:" + minValue);
    
    setDeliveryId(new Number(minValue));

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

    // //////////////////////////////
    // 契約管理テーブルよりキー値の取得・設定
    // //////////////////////////////
    EntityDefImpl headerEntityDef
      = XxcsoContractManagementsEOImpl.getDefinitionObject();

    // 全契約管理テーブル行を取得します。
    Iterator headerEoIt = headerEntityDef.getAllEntityInstancesIterator(txn);

    Number contractManagementId = null;
    
    while ( headerEoIt.hasNext() )
    {
      XxcsoContractManagementsEOImpl headerEo
        = (XxcsoContractManagementsEOImpl) headerEoIt.next();

      if ( headerEo.getEntityState() == OAPlsqlEntityImpl.STATUS_NEW )
      {
        // 新規作成の場合のみ自動販売機設置契約書IDを設定します。
        contractManagementId = headerEo.getContractManagementId();
        setContractManagementId(contractManagementId);
        break;
      }
    }

    // //////////////////////////////
    // 銀行口座アドオンへのキー値設定
    // //////////////////////////////
    // 登録する直前でシーケンス値を払い出します。
    Number deliveryId
      = getOADBTransaction().getSequenceValue("XXCSO_DESTINATIONS_S01");

    EntityDefImpl bankDef = XxcsoBankAccountsEOImpl.getDefinitionObject();
    Iterator bankIt = bankDef.getAllEntityInstancesIterator(txn);

    Number dummyDeliveryId = getDeliveryId();
    
    setDeliveryId(deliveryId);

    while ( bankIt.hasNext() )
    {
      XxcsoBankAccountsEOImpl bankEo
        = (XxcsoBankAccountsEOImpl)bankIt.next();

      if ( dummyDeliveryId.equals(bankEo.getDeliveryId()) )
      {
        bankEo.setDeliveryId(deliveryId);
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
   * Gets the attribute value for ContractManagementId, using the alias name ContractManagementId
   */
  public Number getContractManagementId()
  {
    return (Number)getAttributeInternal(CONTRACTMANAGEMENTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractManagementId
   */
  public void setContractManagementId(Number value)
  {
    setAttributeInternal(CONTRACTMANAGEMENTID, value);
  }

  /**
   * 
   * Gets the attribute value for SupplierId, using the alias name SupplierId
   */
  public Number getSupplierId()
  {
    return (Number)getAttributeInternal(SUPPLIERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SupplierId
   */
  public void setSupplierId(Number value)
  {
    setAttributeInternal(SUPPLIERID, value);
  }

  /**
   * 
   * Gets the attribute value for DeliveryDiv, using the alias name DeliveryDiv
   */
  public String getDeliveryDiv()
  {
    return (String)getAttributeInternal(DELIVERYDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for DeliveryDiv
   */
  public void setDeliveryDiv(String value)
  {
    setAttributeInternal(DELIVERYDIV, value);
  }

  /**
   * 
   * Gets the attribute value for PaymentName, using the alias name PaymentName
   */
  public String getPaymentName()
  {
    return (String)getAttributeInternal(PAYMENTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PaymentName
   */
  public void setPaymentName(String value)
  {
    setAttributeInternal(PAYMENTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for PaymentNameAlt, using the alias name PaymentNameAlt
   */
  public String getPaymentNameAlt()
  {
    return (String)getAttributeInternal(PAYMENTNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PaymentNameAlt
   */
  public void setPaymentNameAlt(String value)
  {
    setAttributeInternal(PAYMENTNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for BankTransferFeeChargeDiv, using the alias name BankTransferFeeChargeDiv
   */
  public String getBankTransferFeeChargeDiv()
  {
    return (String)getAttributeInternal(BANKTRANSFERFEECHARGEDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BankTransferFeeChargeDiv
   */
  public void setBankTransferFeeChargeDiv(String value)
  {
    setAttributeInternal(BANKTRANSFERFEECHARGEDIV, value);
  }

  /**
   * 
   * Gets the attribute value for BellingDetailsDiv, using the alias name BellingDetailsDiv
   */
  public String getBellingDetailsDiv()
  {
    return (String)getAttributeInternal(BELLINGDETAILSDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BellingDetailsDiv
   */
  public void setBellingDetailsDiv(String value)
  {
    setAttributeInternal(BELLINGDETAILSDIV, value);
  }

  /**
   * 
   * Gets the attribute value for InqueryChargeHubCd, using the alias name InqueryChargeHubCd
   */
  public String getInqueryChargeHubCd()
  {
    return (String)getAttributeInternal(INQUERYCHARGEHUBCD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InqueryChargeHubCd
   */
  public void setInqueryChargeHubCd(String value)
  {
    setAttributeInternal(INQUERYCHARGEHUBCD, value);
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
      case DELIVERYID:
        return getDeliveryId();
      case CONTRACTMANAGEMENTID:
        return getContractManagementId();
      case SUPPLIERID:
        return getSupplierId();
      case DELIVERYDIV:
        return getDeliveryDiv();
      case PAYMENTNAME:
        return getPaymentName();
      case PAYMENTNAMEALT:
        return getPaymentNameAlt();
      case BANKTRANSFERFEECHARGEDIV:
        return getBankTransferFeeChargeDiv();
      case BELLINGDETAILSDIV:
        return getBellingDetailsDiv();
      case INQUERYCHARGEHUBCD:
        return getInqueryChargeHubCd();
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
      case ADDRESSLINESPHONETIC:
        return getAddressLinesPhonetic();
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
      case BMTAXKBN:
        return getBmTaxKbn();
      case XXCSOBANKACCOUNTSEO:
        return getXxcsoBankAccountsEO();
      case XXCSOCONTRACTMANAGEMENTSEO:
        return getXxcsoContractManagementsEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DELIVERYID:
        setDeliveryId((Number)value);
        return;
      case CONTRACTMANAGEMENTID:
        setContractManagementId((Number)value);
        return;
      case SUPPLIERID:
        setSupplierId((Number)value);
        return;
      case DELIVERYDIV:
        setDeliveryDiv((String)value);
        return;
      case PAYMENTNAME:
        setPaymentName((String)value);
        return;
      case PAYMENTNAMEALT:
        setPaymentNameAlt((String)value);
        return;
      case BANKTRANSFERFEECHARGEDIV:
        setBankTransferFeeChargeDiv((String)value);
        return;
      case BELLINGDETAILSDIV:
        setBellingDetailsDiv((String)value);
        return;
      case INQUERYCHARGEHUBCD:
        setInqueryChargeHubCd((String)value);
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
      case ADDRESSLINESPHONETIC:
        setAddressLinesPhonetic((String)value);
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
      case BMTAXKBN:
        setBmTaxKbn((String)value);
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
  public XxcsoContractManagementsEOImpl getXxcsoContractManagementsEO()
  {
    return (XxcsoContractManagementsEOImpl)getAttributeInternal(XXCSOCONTRACTMANAGEMENTSEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoContractManagementsEOImpl
   */
  public void setXxcsoContractManagementsEO(XxcsoContractManagementsEOImpl value)
  {
    setAttributeInternal(XXCSOCONTRACTMANAGEMENTSEO, value);
  }


  /**
   * 
   * Gets the associated entity XxcsoBankAccountsEOImpl
   */
  public XxcsoBankAccountsEOImpl getXxcsoBankAccountsEO()
  {
    return (XxcsoBankAccountsEOImpl)getAttributeInternal(XXCSOBANKACCOUNTSEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoBankAccountsEOImpl
   */
  public void setXxcsoBankAccountsEO(XxcsoBankAccountsEOImpl value)
  {
    setAttributeInternal(XXCSOBANKACCOUNTSEO, value);
  }


  /**
   * 
   * Gets the attribute value for BmTaxKbn, using the alias name BmTaxKbn
   */
  public String getBmTaxKbn()
  {
    return (String)getAttributeInternal(BMTAXKBN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BmTaxKbn
   */
  public void setBmTaxKbn(String value)
  {
    setAttributeInternal(BMTAXKBN, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number deliveryId)
  {
    return new Key(new Object[] {deliveryId});
  }























}
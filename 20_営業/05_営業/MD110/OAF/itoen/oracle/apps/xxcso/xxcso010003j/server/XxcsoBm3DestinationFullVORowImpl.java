/*============================================================================
* ファイル名 : XxcsoBm3DestinationFullVORowImpl
* 概要説明   : BM3送付先テーブル情報ビュー行オブジェクトクラス
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
* 2020-08-21 1.1  SCSK佐々木大和[E_本稼動_15904]税抜きでの自販機BM計算について
* 2020-12-14 1.2  SCSK佐々木大和[E_本稼動_16642]送付先コードに紐付くメールアドレスについて
* 2023-06-08 1.3  SCSK赤地学    [E_本稼動_19179]インボイス対応（BM関連）
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * BM3送付先テーブル情報ビュー行オブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoBm3DestinationFullVORowImpl extends OAViewRowImpl 
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
  protected static final int SITEEMAILADDRESS = 15;
  protected static final int CREATEDBY = 16;
  protected static final int CREATIONDATE = 17;
  protected static final int LASTUPDATEDBY = 18;
  protected static final int LASTUPDATEDATE = 19;
  protected static final int LASTUPDATELOGIN = 20;
  protected static final int REQUESTID = 21;
  protected static final int PROGRAMAPPLICATIONID = 22;
  protected static final int PROGRAMID = 23;
  protected static final int PROGRAMUPDATEDATE = 24;
  protected static final int INQUERYCHARGEHUBNAME = 25;
  protected static final int VENDORFLAG = 26;
  protected static final int VENDORCODE = 27;
  protected static final int BMTAXKBN = 28;
  protected static final int BMTAXKBNNM = 29;
  protected static final int INVOICETFLAG = 30;
  protected static final int INVOICETNO = 31;
  protected static final int INVOICETAXDIVBM = 32;
  protected static final int XXCSOBM3BANKACCOUNTFULLVO = 33;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoBm3DestinationFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoDestinationsEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoDestinationsEOImpl getXxcsoDestinationsEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoDestinationsEOImpl)getEntity(0);
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
   * Gets the attribute value for SUPPLIER_ID using the alias name SupplierId
   */
  public Number getSupplierId()
  {
    return (Number)getAttributeInternal(SUPPLIERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SUPPLIER_ID using the alias name SupplierId
   */
  public void setSupplierId(Number value)
  {
    setAttributeInternal(SUPPLIERID, value);
  }

  /**
   * 
   * Gets the attribute value for DELIVERY_DIV using the alias name DeliveryDiv
   */
  public String getDeliveryDiv()
  {
    return (String)getAttributeInternal(DELIVERYDIV);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DELIVERY_DIV using the alias name DeliveryDiv
   */
  public void setDeliveryDiv(String value)
  {
    setAttributeInternal(DELIVERYDIV, value);
  }

  /**
   * 
   * Gets the attribute value for PAYMENT_NAME using the alias name PaymentName
   */
  public String getPaymentName()
  {
    return (String)getAttributeInternal(PAYMENTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PAYMENT_NAME using the alias name PaymentName
   */
  public void setPaymentName(String value)
  {
    setAttributeInternal(PAYMENTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for PAYMENT_NAME_ALT using the alias name PaymentNameAlt
   */
  public String getPaymentNameAlt()
  {
    return (String)getAttributeInternal(PAYMENTNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PAYMENT_NAME_ALT using the alias name PaymentNameAlt
   */
  public void setPaymentNameAlt(String value)
  {
    setAttributeInternal(PAYMENTNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for BANK_TRANSFER_FEE_CHARGE_DIV using the alias name BankTransferFeeChargeDiv
   */
  public String getBankTransferFeeChargeDiv()
  {
    return (String)getAttributeInternal(BANKTRANSFERFEECHARGEDIV);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BANK_TRANSFER_FEE_CHARGE_DIV using the alias name BankTransferFeeChargeDiv
   */
  public void setBankTransferFeeChargeDiv(String value)
  {
    setAttributeInternal(BANKTRANSFERFEECHARGEDIV, value);
  }

  /**
   * 
   * Gets the attribute value for BELLING_DETAILS_DIV using the alias name BellingDetailsDiv
   */
  public String getBellingDetailsDiv()
  {
    return (String)getAttributeInternal(BELLINGDETAILSDIV);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BELLING_DETAILS_DIV using the alias name BellingDetailsDiv
   */
  public void setBellingDetailsDiv(String value)
  {
    setAttributeInternal(BELLINGDETAILSDIV, value);
  }

  /**
   * 
   * Gets the attribute value for INQUERY_CHARGE_HUB_CD using the alias name InqueryChargeHubCd
   */
  public String getInqueryChargeHubCd()
  {
    return (String)getAttributeInternal(INQUERYCHARGEHUBCD);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INQUERY_CHARGE_HUB_CD using the alias name InqueryChargeHubCd
   */
  public void setInqueryChargeHubCd(String value)
  {
    setAttributeInternal(INQUERYCHARGEHUBCD, value);
  }

  /**
   * 
   * Gets the attribute value for POST_CODE using the alias name PostCode
   */
  public String getPostCode()
  {
    return (String)getAttributeInternal(POSTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for POST_CODE using the alias name PostCode
   */
  public void setPostCode(String value)
  {
    setAttributeInternal(POSTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for PREFECTURES using the alias name Prefectures
   */
  public String getPrefectures()
  {
    return (String)getAttributeInternal(PREFECTURES);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PREFECTURES using the alias name Prefectures
   */
  public void setPrefectures(String value)
  {
    setAttributeInternal(PREFECTURES, value);
  }

  /**
   * 
   * Gets the attribute value for CITY_WARD using the alias name CityWard
   */
  public String getCityWard()
  {
    return (String)getAttributeInternal(CITYWARD);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CITY_WARD using the alias name CityWard
   */
  public void setCityWard(String value)
  {
    setAttributeInternal(CITYWARD, value);
  }

  /**
   * 
   * Gets the attribute value for ADDRESS_1 using the alias name Address1
   */
  public String getAddress1()
  {
    return (String)getAttributeInternal(ADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ADDRESS_1 using the alias name Address1
   */
  public void setAddress1(String value)
  {
    setAttributeInternal(ADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for ADDRESS_2 using the alias name Address2
   */
  public String getAddress2()
  {
    return (String)getAttributeInternal(ADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ADDRESS_2 using the alias name Address2
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
      case SITEEMAILADDRESS:
        return getSiteEmailAddress();
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
      case INQUERYCHARGEHUBNAME:
        return getInqueryChargeHubName();
      case VENDORFLAG:
        return getVendorFlag();
      case VENDORCODE:
        return getVendorCode();
      case BMTAXKBN:
        return getBmTaxKbn();
      case BMTAXKBNNM:
        return getBmTaxKbnNm();
      case INVOICETFLAG:
        return getInvoiceTFlag();
      case INVOICETNO:
        return getInvoiceTNo();
      case INVOICETAXDIVBM:
        return getInvoiceTaxDivBm();
      case XXCSOBM3BANKACCOUNTFULLVO:
        return getXxcsoBm3BankAccountFullVO();
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
      case SITEEMAILADDRESS:
        setSiteEmailAddress((String)value);
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
      case INQUERYCHARGEHUBNAME:
        setInqueryChargeHubName((String)value);
        return;
      case VENDORFLAG:
        setVendorFlag((String)value);
        return;
      case VENDORCODE:
        setVendorCode((String)value);
        return;
      case BMTAXKBN:
        setBmTaxKbn((String)value);
        return;
      case BMTAXKBNNM:
        setBmTaxKbnNm((String)value);
        return;
      case INVOICETFLAG:
        setInvoiceTFlag((String)value);
        return;
      case INVOICETNO:
        setInvoiceTNo((String)value);
        return;
      case INVOICETAXDIVBM:
        setInvoiceTaxDivBm((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the associated <code>Row</code> using master-detail link XxcsoBm3BankAccountFullVO
   */
  public oracle.jbo.Row getXxcsoBm3BankAccountFullVO()
  {
    return (oracle.jbo.Row)getAttributeInternal(XXCSOBM3BANKACCOUNTFULLVO);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InqueryChargeHubName
   */
  public String getInqueryChargeHubName()
  {
    return (String)getAttributeInternal(INQUERYCHARGEHUBNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InqueryChargeHubName
   */
  public void setInqueryChargeHubName(String value)
  {
    setAttributeInternal(INQUERYCHARGEHUBNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorCode
   */
  public String getVendorCode()
  {
    return (String)getAttributeInternal(VENDORCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorCode
   */
  public void setVendorCode(String value)
  {
    setAttributeInternal(VENDORCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorFlag
   */
  public String getVendorFlag()
  {
    return (String)getAttributeInternal(VENDORFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorFlag
   */
  public void setVendorFlag(String value)
  {
    setAttributeInternal(VENDORFLAG, value);
  }





  /**
   * 
   * Gets the attribute value for BM_TAX_KBN using the alias name BmTaxKbn
   */
  public String getBmTaxKbn()
  {
    return (String)getAttributeInternal(BMTAXKBN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM_TAX_KBN using the alias name BmTaxKbn
   */
  public void setBmTaxKbn(String value)
  {
    setAttributeInternal(BMTAXKBN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BmTaxKbnNm
   */
  public String getBmTaxKbnNm()
  {
    return (String)getAttributeInternal(BMTAXKBNNM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BmTaxKbnNm
   */
  public void setBmTaxKbnNm(String value)
  {
    setAttributeInternal(BMTAXKBNNM, value);
  }

  /**
   * 
   * Gets the attribute value for SITE_EMAIL_ADDRESS using the alias name SiteEmailAddress
   */
  public String getSiteEmailAddress()
  {
    return (String)getAttributeInternal(SITEEMAILADDRESS);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SITE_EMAIL_ADDRESS using the alias name SiteEmailAddress
   */
  public void setSiteEmailAddress(String value)
  {
    setAttributeInternal(SITEEMAILADDRESS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InvoiceTNo
   */
  public String getInvoiceTNo()
  {
    return (String)getAttributeInternal(INVOICETNO);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InvoiceTNo
   */
  public void setInvoiceTNo(String value)
  {
    setAttributeInternal(INVOICETNO, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InvoiceTaxDivBm
   */
  public String getInvoiceTaxDivBm()
  {
    return (String)getAttributeInternal(INVOICETAXDIVBM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InvoiceTaxDivBm
   */
  public void setInvoiceTaxDivBm(String value)
  {
    setAttributeInternal(INVOICETAXDIVBM, value);
  }

  /**
   * 
   * Gets the attribute value for INVOICE_T_FLAG using the alias name InvoiceTFlag
   */
  public String getInvoiceTFlag()
  {
    return (String)getAttributeInternal(INVOICETFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INVOICE_T_FLAG using the alias name InvoiceTFlag
   */
  public void setInvoiceTFlag(String value)
  {
    setAttributeInternal(INVOICETFLAG, value);
  }



}
/*============================================================================
* ファイル名 : XxcsoInitBmInfoSummaryVORowImpl
* 概要説明   : 初期表示時BM情報取得ビュー行オブジェクトクラス
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
* 2020-08-21 1.1  SCSK佐々木大和[E_本稼動_15904]税抜きでの自販機BM計算について
* 2020-12-14 1.2  SCSK佐々木大和[E_本稼動_16642]送付先コードに紐付くメールアドレスについて
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 初期表示時BM情報取得ビュー行オブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInitBmInfoSummaryVORowImpl extends OAViewRowImpl 
{






  protected static final int VENDORCODE = 0;
  protected static final int TRANSFERCOMMISSIONTYPE = 1;
  protected static final int BMPAYMENTTYPE = 2;
  protected static final int INQUIRYBASECODE = 3;
  protected static final int INQUIRYBASENAME = 4;
  protected static final int VENDORNAME = 5;
  protected static final int VENDORNAMEALT = 6;
  protected static final int POSTALCODE = 7;
  protected static final int STATE = 8;
  protected static final int CITY = 9;
  protected static final int ADDRESS1 = 10;
  protected static final int ADDRESS2 = 11;
  protected static final int ADDRESSLINESPHONETIC = 12;
  protected static final int BANKNUMBER = 13;
  protected static final int BANKNAME = 14;
  protected static final int BANKNUM = 15;
  protected static final int BANKBRANCHNAME = 16;
  protected static final int BANKACCOUNTTYPE = 17;
  protected static final int BANKACCOUNTNUM = 18;
  protected static final int ACCOUNTHOLDERNAMEALT = 19;
  protected static final int ACCOUNTHOLDERNAME = 20;
  protected static final int BMTAXKBN = 21;
  protected static final int BMTAXKBNNM = 22;
  protected static final int CUSTOMERID = 23;
  protected static final int SITEEMAILADDRESS = 24;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInitBmInfoSummaryVORowImpl()
  {
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VENDORCODE:
        return getVendorCode();
      case TRANSFERCOMMISSIONTYPE:
        return getTransferCommissionType();
      case BMPAYMENTTYPE:
        return getBmPaymentType();
      case INQUIRYBASECODE:
        return getInquiryBaseCode();
      case INQUIRYBASENAME:
        return getInquiryBaseName();
      case VENDORNAME:
        return getVendorName();
      case VENDORNAMEALT:
        return getVendorNameAlt();
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
      case BANKNUMBER:
        return getBankNumber();
      case BANKNAME:
        return getBankName();
      case BANKNUM:
        return getBankNum();
      case BANKBRANCHNAME:
        return getBankBranchName();
      case BANKACCOUNTTYPE:
        return getBankAccountType();
      case BANKACCOUNTNUM:
        return getBankAccountNum();
      case ACCOUNTHOLDERNAMEALT:
        return getAccountHolderNameAlt();
      case ACCOUNTHOLDERNAME:
        return getAccountHolderName();
      case BMTAXKBN:
        return getBmTaxKbn();
      case BMTAXKBNNM:
        return getBmTaxKbnNm();
      case CUSTOMERID:
        return getCustomerId();
      case SITEEMAILADDRESS:
        return getSiteEmailAddress();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VENDORCODE:
        setVendorCode((String)value);
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
      case INQUIRYBASENAME:
        setInquiryBaseName((String)value);
        return;
      case VENDORNAME:
        setVendorName((String)value);
        return;
      case VENDORNAMEALT:
        setVendorNameAlt((String)value);
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
      case BANKNUMBER:
        setBankNumber((String)value);
        return;
      case BANKNAME:
        setBankName((String)value);
        return;
      case BANKNUM:
        setBankNum((String)value);
        return;
      case BANKBRANCHNAME:
        setBankBranchName((String)value);
        return;
      case BANKACCOUNTTYPE:
        setBankAccountType((String)value);
        return;
      case BANKACCOUNTNUM:
        setBankAccountNum((String)value);
        return;
      case ACCOUNTHOLDERNAMEALT:
        setAccountHolderNameAlt((String)value);
        return;
      case ACCOUNTHOLDERNAME:
        setAccountHolderName((String)value);
        return;
      case BMTAXKBN:
        setBmTaxKbn((String)value);
        return;
      case BMTAXKBNNM:
        setBmTaxKbnNm((String)value);
        return;
      case CUSTOMERID:
        setCustomerId((Number)value);
        return;
      case SITEEMAILADDRESS:
        setSiteEmailAddress((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TransferCommissionType
   */
  public String getTransferCommissionType()
  {
    return (String)getAttributeInternal(TRANSFERCOMMISSIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TransferCommissionType
   */
  public void setTransferCommissionType(String value)
  {
    setAttributeInternal(TRANSFERCOMMISSIONTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BmPaymentType
   */
  public String getBmPaymentType()
  {
    return (String)getAttributeInternal(BMPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BmPaymentType
   */
  public void setBmPaymentType(String value)
  {
    setAttributeInternal(BMPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InquiryBaseCode
   */
  public String getInquiryBaseCode()
  {
    return (String)getAttributeInternal(INQUIRYBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InquiryBaseCode
   */
  public void setInquiryBaseCode(String value)
  {
    setAttributeInternal(INQUIRYBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InquiryBaseName
   */
  public String getInquiryBaseName()
  {
    return (String)getAttributeInternal(INQUIRYBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InquiryBaseName
   */
  public void setInquiryBaseName(String value)
  {
    setAttributeInternal(INQUIRYBASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorName
   */
  public String getVendorName()
  {
    return (String)getAttributeInternal(VENDORNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorName
   */
  public void setVendorName(String value)
  {
    setAttributeInternal(VENDORNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorNameAlt
   */
  public String getVendorNameAlt()
  {
    return (String)getAttributeInternal(VENDORNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorNameAlt
   */
  public void setVendorNameAlt(String value)
  {
    setAttributeInternal(VENDORNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PostalCode
   */
  public String getPostalCode()
  {
    return (String)getAttributeInternal(POSTALCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostalCode
   */
  public void setPostalCode(String value)
  {
    setAttributeInternal(POSTALCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute State
   */
  public String getState()
  {
    return (String)getAttributeInternal(STATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute State
   */
  public void setState(String value)
  {
    setAttributeInternal(STATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute City
   */
  public String getCity()
  {
    return (String)getAttributeInternal(CITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute City
   */
  public void setCity(String value)
  {
    setAttributeInternal(CITY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address1
   */
  public String getAddress1()
  {
    return (String)getAttributeInternal(ADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address1
   */
  public void setAddress1(String value)
  {
    setAttributeInternal(ADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address2
   */
  public String getAddress2()
  {
    return (String)getAttributeInternal(ADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address2
   */
  public void setAddress2(String value)
  {
    setAttributeInternal(ADDRESS2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AddressLinesPhonetic
   */
  public String getAddressLinesPhonetic()
  {
    return (String)getAttributeInternal(ADDRESSLINESPHONETIC);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AddressLinesPhonetic
   */
  public void setAddressLinesPhonetic(String value)
  {
    setAttributeInternal(ADDRESSLINESPHONETIC, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankNumber
   */
  public String getBankNumber()
  {
    return (String)getAttributeInternal(BANKNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankNumber
   */
  public void setBankNumber(String value)
  {
    setAttributeInternal(BANKNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankName
   */
  public String getBankName()
  {
    return (String)getAttributeInternal(BANKNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankName
   */
  public void setBankName(String value)
  {
    setAttributeInternal(BANKNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankNum
   */
  public String getBankNum()
  {
    return (String)getAttributeInternal(BANKNUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankNum
   */
  public void setBankNum(String value)
  {
    setAttributeInternal(BANKNUM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankBranchName
   */
  public String getBankBranchName()
  {
    return (String)getAttributeInternal(BANKBRANCHNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankBranchName
   */
  public void setBankBranchName(String value)
  {
    setAttributeInternal(BANKBRANCHNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankAccountType
   */
  public String getBankAccountType()
  {
    return (String)getAttributeInternal(BANKACCOUNTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankAccountType
   */
  public void setBankAccountType(String value)
  {
    setAttributeInternal(BANKACCOUNTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankAccountNum
   */
  public String getBankAccountNum()
  {
    return (String)getAttributeInternal(BANKACCOUNTNUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankAccountNum
   */
  public void setBankAccountNum(String value)
  {
    setAttributeInternal(BANKACCOUNTNUM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountHolderNameAlt
   */
  public String getAccountHolderNameAlt()
  {
    return (String)getAttributeInternal(ACCOUNTHOLDERNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountHolderNameAlt
   */
  public void setAccountHolderNameAlt(String value)
  {
    setAttributeInternal(ACCOUNTHOLDERNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountHolderName
   */
  public String getAccountHolderName()
  {
    return (String)getAttributeInternal(ACCOUNTHOLDERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountHolderName
   */
  public void setAccountHolderName(String value)
  {
    setAttributeInternal(ACCOUNTHOLDERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustomerId
   */
  public Number getCustomerId()
  {
    return (Number)getAttributeInternal(CUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomerId
   */
  public void setCustomerId(Number value)
  {
    setAttributeInternal(CUSTOMERID, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute BmTaxKbn
   */
  public String getBmTaxKbn()
  {
    return (String)getAttributeInternal(BMTAXKBN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BmTaxKbn
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
   * Gets the attribute value for the calculated attribute SiteEmailAddress
   */
  public String getSiteEmailAddress()
  {
    return (String)getAttributeInternal(SITEEMAILADDRESS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SiteEmailAddress
   */
  public void setSiteEmailAddress(String value)
  {
    setAttributeInternal(SITEEMAILADDRESS, value);
  }





}
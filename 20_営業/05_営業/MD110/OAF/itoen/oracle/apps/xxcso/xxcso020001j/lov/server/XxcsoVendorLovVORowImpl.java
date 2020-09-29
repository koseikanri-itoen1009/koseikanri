/*============================================================================
* ファイル名 : XxcsoVendorModelLovVOImpl
* 概要説明   : 仕入先コードLOV用ビュー行クラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者         修正内容
* ---------- ---- -------------- ----------------------------------------------
* 2008-12-18 1.0  SCS小川浩      新規作成
* 2020-08-21 1.1  SCSK佐々木大和 [E_本稼動_15904]税抜きでの自販機BM計算について
*==============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 仕入先コードのLOVのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoVendorLovVORowImpl extends OAViewRowImpl 
{


  protected static final int VENDORNUMBER = 0;
  protected static final int VENDORID = 1;
  protected static final int VENDORNAME = 2;
  protected static final int VENDORNAMEALT = 3;
  protected static final int POSTALCODEFIRST = 4;
  protected static final int POSTALCODESECOND = 5;
  protected static final int ZIP = 6;
  protected static final int STATE = 7;
  protected static final int CITY = 8;
  protected static final int ADDRESSLINE1 = 9;
  protected static final int ADDRESSLINE2 = 10;
  protected static final int PHONENUMBER = 11;
  protected static final int BANKNAME = 12;
  protected static final int BANKBRANCHNAME = 13;
  protected static final int BANKACCOUNTTYPENAME = 14;
  protected static final int BANKACCOUNTNUM = 15;
  protected static final int ACCOUNTHOLDERNAME = 16;
  protected static final int BMTRANSFERCOMMISSIONTYPE = 17;
  protected static final int BMPAYMENTTYPE = 18;
  protected static final int INQUIRYBASECODE = 19;
  protected static final int INQUIRYBASENAME = 20;
  protected static final int BMTAXKBNCODE = 21;
  protected static final int BMTAXKBN = 22;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoVendorLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorNumber
   */
  public String getVendorNumber()
  {
    return (String)getAttributeInternal(VENDORNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorNumber
   */
  public void setVendorNumber(String value)
  {
    setAttributeInternal(VENDORNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorId
   */
  public Number getVendorId()
  {
    return (Number)getAttributeInternal(VENDORID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorId
   */
  public void setVendorId(Number value)
  {
    setAttributeInternal(VENDORID, value);
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
   * Gets the attribute value for the calculated attribute Zip
   */
  public String getZip()
  {
    return (String)getAttributeInternal(ZIP);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Zip
   */
  public void setZip(String value)
  {
    setAttributeInternal(ZIP, value);
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
   * Gets the attribute value for the calculated attribute AddressLine1
   */
  public String getAddressLine1()
  {
    return (String)getAttributeInternal(ADDRESSLINE1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AddressLine1
   */
  public void setAddressLine1(String value)
  {
    setAttributeInternal(ADDRESSLINE1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AddressLine2
   */
  public String getAddressLine2()
  {
    return (String)getAttributeInternal(ADDRESSLINE2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AddressLine2
   */
  public void setAddressLine2(String value)
  {
    setAttributeInternal(ADDRESSLINE2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PhoneNumber
   */
  public String getPhoneNumber()
  {
    return (String)getAttributeInternal(PHONENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PhoneNumber
   */
  public void setPhoneNumber(String value)
  {
    setAttributeInternal(PHONENUMBER, value);
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
   * Gets the attribute value for the calculated attribute BankAccountTypeName
   */
  public String getBankAccountTypeName()
  {
    return (String)getAttributeInternal(BANKACCOUNTTYPENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankAccountTypeName
   */
  public void setBankAccountTypeName(String value)
  {
    setAttributeInternal(BANKACCOUNTTYPENAME, value);
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
   * Gets the attribute value for the calculated attribute BmTransferCommissionType
   */
  public String getBmTransferCommissionType()
  {
    return (String)getAttributeInternal(BMTRANSFERCOMMISSIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BmTransferCommissionType
   */
  public void setBmTransferCommissionType(String value)
  {
    setAttributeInternal(BMTRANSFERCOMMISSIONTYPE, value);
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VENDORNUMBER:
        return getVendorNumber();
      case VENDORID:
        return getVendorId();
      case VENDORNAME:
        return getVendorName();
      case VENDORNAMEALT:
        return getVendorNameAlt();
      case POSTALCODEFIRST:
        return getPostalCodeFirst();
      case POSTALCODESECOND:
        return getPostalCodeSecond();
      case ZIP:
        return getZip();
      case STATE:
        return getState();
      case CITY:
        return getCity();
      case ADDRESSLINE1:
        return getAddressLine1();
      case ADDRESSLINE2:
        return getAddressLine2();
      case PHONENUMBER:
        return getPhoneNumber();
      case BANKNAME:
        return getBankName();
      case BANKBRANCHNAME:
        return getBankBranchName();
      case BANKACCOUNTTYPENAME:
        return getBankAccountTypeName();
      case BANKACCOUNTNUM:
        return getBankAccountNum();
      case ACCOUNTHOLDERNAME:
        return getAccountHolderName();
      case BMTRANSFERCOMMISSIONTYPE:
        return getBmTransferCommissionType();
      case BMPAYMENTTYPE:
        return getBmPaymentType();
      case INQUIRYBASECODE:
        return getInquiryBaseCode();
      case INQUIRYBASENAME:
        return getInquiryBaseName();
      case BMTAXKBNCODE:
        return getBmTaxKbnCode();
      case BMTAXKBN:
        return getBmTaxKbn();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VENDORNUMBER:
        setVendorNumber((String)value);
        return;
      case VENDORID:
        setVendorId((Number)value);
        return;
      case VENDORNAME:
        setVendorName((String)value);
        return;
      case VENDORNAMEALT:
        setVendorNameAlt((String)value);
        return;
      case POSTALCODEFIRST:
        setPostalCodeFirst((String)value);
        return;
      case POSTALCODESECOND:
        setPostalCodeSecond((String)value);
        return;
      case ZIP:
        setZip((String)value);
        return;
      case STATE:
        setState((String)value);
        return;
      case CITY:
        setCity((String)value);
        return;
      case ADDRESSLINE1:
        setAddressLine1((String)value);
        return;
      case ADDRESSLINE2:
        setAddressLine2((String)value);
        return;
      case PHONENUMBER:
        setPhoneNumber((String)value);
        return;
      case BANKNAME:
        setBankName((String)value);
        return;
      case BANKBRANCHNAME:
        setBankBranchName((String)value);
        return;
      case BANKACCOUNTTYPENAME:
        setBankAccountTypeName((String)value);
        return;
      case BANKACCOUNTNUM:
        setBankAccountNum((String)value);
        return;
      case ACCOUNTHOLDERNAME:
        setAccountHolderName((String)value);
        return;
      case BMTRANSFERCOMMISSIONTYPE:
        setBmTransferCommissionType((String)value);
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
      case BMTAXKBNCODE:
        setBmTaxKbnCode((String)value);
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
   * Gets the attribute value for the calculated attribute BmTaxKbnCode
   */
  public String getBmTaxKbnCode()
  {
    return (String)getAttributeInternal(BMTAXKBNCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BmTaxKbnCode
   */
  public void setBmTaxKbnCode(String value)
  {
    setAttributeInternal(BMTAXKBNCODE, value);
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
}
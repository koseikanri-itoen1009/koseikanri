/*============================================================================
* �t�@�C���� : XxcsoContractVendorLovVORowImpl
* �T�v����   : �d����(���t��)���擾LOV�r���[�s�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.3
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
* 2020-08-21 1.1  SCSK���X�ؑ�a[E_�{�ғ�_15904]�Ŕ����ł̎��̋@BM�v�Z�ɂ���
* 2020-12-14 1.2  SCSK���X�ؑ�a[E_�{�ғ�_16642]���t��R�[�h�ɕR�t�����[���A�h���X�ɂ���
* 2023-06-08 1.3  SCSK�Ԓn�w    [E_�{�ғ�_19179]�C���{�C�X�Ή��iBM�֘A�j
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.lov.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �d����(���t��)���擾LOV�r���[�s�I�u�W�F�N�g�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractVendorLovVORowImpl extends OAViewRowImpl 
{


  protected static final int VENDORNUMBER = 0;
  protected static final int VENDORID = 1;
  protected static final int VENDORNAME = 2;
  protected static final int VENDORNAMEALT = 3;
  protected static final int ZIP = 4;
  protected static final int STATE = 5;
  protected static final int CITY = 6;
  protected static final int ADDRESSLINE1 = 7;
  protected static final int ADDRESSLINE2 = 8;
  protected static final int PHONENUMBER = 9;
  protected static final int BANKNUMBER = 10;
  protected static final int BANKNAME = 11;
  protected static final int BANKBRANCHNUMBER = 12;
  protected static final int BANKBRANCHNAME = 13;
  protected static final int BANKACCOUNTTYPE = 14;
  protected static final int BANKACCOUNTNUM = 15;
  protected static final int BANKACCOUNTHOLDERNAMEALT = 16;
  protected static final int BANKACCOUNTHOLDERNAME = 17;
  protected static final int BMTRANSFERCOMMISSIONTYPE = 18;
  protected static final int BMPAYMENTTYPE = 19;
  protected static final int INQUIRYBASECODE = 20;
  protected static final int INQUIRYBASENAME = 21;
  protected static final int VENDORID2 = 22;
  protected static final int BANKACCOUNTTYPENAME = 23;
  protected static final int BMTAXKBN = 24;
  protected static final int BMTAXKBNNM = 25;
  protected static final int SITEEMAILADDRESS = 26;
  protected static final int INVOICETFLAG = 27;
  protected static final int INVOICETNO = 28;
  protected static final int INVOICETAXDIVBM = 29;
  protected static final int SITEMAILADDRESS = 10;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractVendorLovVORowImpl()
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
   * Gets the attribute value for the calculated attribute BankBranchNumber
   */
  public String getBankBranchNumber()
  {
    return (String)getAttributeInternal(BANKBRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankBranchNumber
   */
  public void setBankBranchNumber(String value)
  {
    setAttributeInternal(BANKBRANCHNUMBER, value);
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
   * Gets the attribute value for the calculated attribute BankAccountHolderNameAlt
   */
  public String getBankAccountHolderNameAlt()
  {
    return (String)getAttributeInternal(BANKACCOUNTHOLDERNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankAccountHolderNameAlt
   */
  public void setBankAccountHolderNameAlt(String value)
  {
    setAttributeInternal(BANKACCOUNTHOLDERNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankAccountHolderName
   */
  public String getBankAccountHolderName()
  {
    return (String)getAttributeInternal(BANKACCOUNTHOLDERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankAccountHolderName
   */
  public void setBankAccountHolderName(String value)
  {
    setAttributeInternal(BANKACCOUNTHOLDERNAME, value);
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
      case BANKNUMBER:
        return getBankNumber();
      case BANKNAME:
        return getBankName();
      case BANKBRANCHNUMBER:
        return getBankBranchNumber();
      case BANKBRANCHNAME:
        return getBankBranchName();
      case BANKACCOUNTTYPE:
        return getBankAccountType();
      case BANKACCOUNTNUM:
        return getBankAccountNum();
      case BANKACCOUNTHOLDERNAMEALT:
        return getBankAccountHolderNameAlt();
      case BANKACCOUNTHOLDERNAME:
        return getBankAccountHolderName();
      case BMTRANSFERCOMMISSIONTYPE:
        return getBmTransferCommissionType();
      case BMPAYMENTTYPE:
        return getBmPaymentType();
      case INQUIRYBASECODE:
        return getInquiryBaseCode();
      case INQUIRYBASENAME:
        return getInquiryBaseName();
      case VENDORID2:
        return getVendorId2();
      case BANKACCOUNTTYPENAME:
        return getBankAccountTypeName();
      case BMTAXKBN:
        return getBmTaxKbn();
      case BMTAXKBNNM:
        return getBmTaxKbnNm();
      case SITEEMAILADDRESS:
        return getSiteEmailAddress();
      case INVOICETFLAG:
        return getInvoiceTFlag();
      case INVOICETNO:
        return getInvoiceTNo();
      case INVOICETAXDIVBM:
        return getInvoiceTaxDivBm();
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
      case BANKNUMBER:
        setBankNumber((String)value);
        return;
      case BANKNAME:
        setBankName((String)value);
        return;
      case BANKBRANCHNUMBER:
        setBankBranchNumber((String)value);
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
      case BANKACCOUNTHOLDERNAMEALT:
        setBankAccountHolderNameAlt((String)value);
        return;
      case BANKACCOUNTHOLDERNAME:
        setBankAccountHolderName((String)value);
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
      case VENDORID2:
        setVendorId2((Number)value);
        return;
      case BANKACCOUNTTYPENAME:
        setBankAccountTypeName((String)value);
        return;
      case BMTAXKBN:
        setBmTaxKbn((String)value);
        return;
      case BMTAXKBNNM:
        setBmTaxKbnNm((String)value);
        return;
      case SITEEMAILADDRESS:
        setSiteEmailAddress((String)value);
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
   * Gets the attribute value for the calculated attribute VendorId2
   */
  public Number getVendorId2()
  {
    return (Number)getAttributeInternal(VENDORID2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorId2
   */
  public void setVendorId2(Number value)
  {
    setAttributeInternal(VENDORID2, value);
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
   * Gets the attribute value for the calculated attribute SiteMailAddress
   */
  public String getSiteMailAddress()
  {
    return (String)getAttributeInternal(SITEMAILADDRESS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SiteMailAddress
   */
  public void setSiteMailAddress(String value)
  {
    setAttributeInternal(SITEMAILADDRESS, value);
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

  /**
   * 
   * Gets the attribute value for the calculated attribute InvoiceTFlag
   */
  public String getInvoiceTFlag()
  {
    return (String)getAttributeInternal(INVOICETFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InvoiceTFlag
   */
  public void setInvoiceTFlag(String value)
  {
    setAttributeInternal(INVOICETFLAG, value);
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
}
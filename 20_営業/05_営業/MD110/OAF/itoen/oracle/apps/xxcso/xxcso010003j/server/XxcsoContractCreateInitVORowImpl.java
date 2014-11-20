/*============================================================================
* �t�@�C���� : XxcsoContractCreateInitVOImpl
* �T�v����   : �V�K�쐬���_��Ǘ��������擾�r���[�s�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
* 2009-02-16 1.1  SCS�������l  [CT1-008]BM�w��`�F�b�N�{�b�N�X�s���Ή�
* 2009-02-17 1.1  SCS�������l  [CT1-012]�ݒu�於�擾�����C��
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �V�K�쐬���_��Ǘ��������擾�r���[�s�I�u�W�F�N�g�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractCreateInitVORowImpl extends OAViewRowImpl 
{


  protected static final int SPDECISIONHEADERID = 0;
  protected static final int SPDECISIONNUMBER = 1;
  protected static final int CONDITIONBUSINESSTYPE = 2;
  protected static final int INSTALLACCOUNTID = 3;
  protected static final int INSTALLACCOUNTNUMBER = 4;
  protected static final int INSTALLNAME = 5;
  protected static final int INSTALLPOSTALCODE = 6;
  protected static final int INSTALLSTATE = 7;
  protected static final int INSTALLCITY = 8;
  protected static final int INSTALLADDRESS1 = 9;
  protected static final int INSTALLADDRESS2 = 10;
  protected static final int CNTRCTCUSTOMERID = 11;
  protected static final int SALEBASECODE = 12;
  protected static final int BM1SPCUSTID = 13;
  protected static final int BM1PAYMENTTYPE = 14;
  protected static final int BM2SPCUSTID = 15;
  protected static final int BM2PAYMENTTYPE = 16;
  protected static final int BM3SPCUSTID = 17;
  protected static final int BM3PAYMENTTYPE = 18;
  protected static final int LINECOUNT = 19;
  protected static final int SALEBASENAME = 20;
  protected static final int LOCATIONADDRESS = 21;
  protected static final int BASELEADERNAME = 22;
  protected static final int CONTRACTYEARDATE = 23;
  protected static final int BASELEADERPOSITIONNAME = 24;
  protected static final int OTHERCONTENT = 25;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractCreateInitVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionNumber
   */
  public String getSpDecisionNumber()
  {
    return (String)getAttributeInternal(SPDECISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionNumber
   */
  public void setSpDecisionNumber(String value)
  {
    setAttributeInternal(SPDECISIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ConditionBusinessType
   */
  public String getConditionBusinessType()
  {
    return (String)getAttributeInternal(CONDITIONBUSINESSTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ConditionBusinessType
   */
  public void setConditionBusinessType(String value)
  {
    setAttributeInternal(CONDITIONBUSINESSTYPE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case SPDECISIONNUMBER:
        return getSpDecisionNumber();
      case CONDITIONBUSINESSTYPE:
        return getConditionBusinessType();
      case INSTALLACCOUNTID:
        return getInstallAccountId();
      case INSTALLACCOUNTNUMBER:
        return getInstallAccountNumber();
      case INSTALLNAME:
        return getInstallName();
      case INSTALLPOSTALCODE:
        return getInstallPostalCode();
      case INSTALLSTATE:
        return getInstallState();
      case INSTALLCITY:
        return getInstallCity();
      case INSTALLADDRESS1:
        return getInstallAddress1();
      case INSTALLADDRESS2:
        return getInstallAddress2();
      case CNTRCTCUSTOMERID:
        return getCntrctCustomerId();
      case SALEBASECODE:
        return getSaleBaseCode();
      case BM1SPCUSTID:
        return getBm1SpCustId();
      case BM1PAYMENTTYPE:
        return getBm1PaymentType();
      case BM2SPCUSTID:
        return getBm2SpCustId();
      case BM2PAYMENTTYPE:
        return getBm2PaymentType();
      case BM3SPCUSTID:
        return getBm3SpCustId();
      case BM3PAYMENTTYPE:
        return getBm3PaymentType();
      case LINECOUNT:
        return getLineCount();
      case SALEBASENAME:
        return getSaleBaseName();
      case LOCATIONADDRESS:
        return getLocationAddress();
      case BASELEADERNAME:
        return getBaseLeaderName();
      case CONTRACTYEARDATE:
        return getContractYearDate();
      case BASELEADERPOSITIONNAME:
        return getBaseLeaderPositionName();
      case OTHERCONTENT:
        return getOtherContent();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case SPDECISIONNUMBER:
        setSpDecisionNumber((String)value);
        return;
      case CONDITIONBUSINESSTYPE:
        setConditionBusinessType((String)value);
        return;
      case INSTALLACCOUNTID:
        setInstallAccountId((Number)value);
        return;
      case INSTALLACCOUNTNUMBER:
        setInstallAccountNumber((String)value);
        return;
      case INSTALLNAME:
        setInstallName((String)value);
        return;
      case INSTALLPOSTALCODE:
        setInstallPostalCode((String)value);
        return;
      case INSTALLSTATE:
        setInstallState((String)value);
        return;
      case INSTALLCITY:
        setInstallCity((String)value);
        return;
      case INSTALLADDRESS1:
        setInstallAddress1((String)value);
        return;
      case INSTALLADDRESS2:
        setInstallAddress2((String)value);
        return;
      case CNTRCTCUSTOMERID:
        setCntrctCustomerId((Number)value);
        return;
      case SALEBASECODE:
        setSaleBaseCode((String)value);
        return;
      case BM1SPCUSTID:
        setBm1SpCustId((Number)value);
        return;
      case BM1PAYMENTTYPE:
        setBm1PaymentType((String)value);
        return;
      case BM2SPCUSTID:
        setBm2SpCustId((Number)value);
        return;
      case BM2PAYMENTTYPE:
        setBm2PaymentType((String)value);
        return;
      case BM3SPCUSTID:
        setBm3SpCustId((Number)value);
        return;
      case BM3PAYMENTTYPE:
        setBm3PaymentType((String)value);
        return;
      case LINECOUNT:
        setLineCount((String)value);
        return;
      case SALEBASENAME:
        setSaleBaseName((String)value);
        return;
      case LOCATIONADDRESS:
        setLocationAddress((String)value);
        return;
      case BASELEADERNAME:
        setBaseLeaderName((String)value);
        return;
      case CONTRACTYEARDATE:
        setContractYearDate((Number)value);
        return;
      case BASELEADERPOSITIONNAME:
        setBaseLeaderPositionName((String)value);
        return;
      case OTHERCONTENT:
        setOtherContent((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAccountId
   */
  public Number getInstallAccountId()
  {
    return (Number)getAttributeInternal(INSTALLACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAccountId
   */
  public void setInstallAccountId(Number value)
  {
    setAttributeInternal(INSTALLACCOUNTID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAccountNumber
   */
  public String getInstallAccountNumber()
  {
    return (String)getAttributeInternal(INSTALLACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAccountNumber
   */
  public void setInstallAccountNumber(String value)
  {
    setAttributeInternal(INSTALLACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallName
   */
  public String getInstallName()
  {
    return (String)getAttributeInternal(INSTALLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallName
   */
  public void setInstallName(String value)
  {
    setAttributeInternal(INSTALLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPostalCode
   */
  public String getInstallPostalCode()
  {
    return (String)getAttributeInternal(INSTALLPOSTALCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPostalCode
   */
  public void setInstallPostalCode(String value)
  {
    setAttributeInternal(INSTALLPOSTALCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallState
   */
  public String getInstallState()
  {
    return (String)getAttributeInternal(INSTALLSTATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallState
   */
  public void setInstallState(String value)
  {
    setAttributeInternal(INSTALLSTATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallCity
   */
  public String getInstallCity()
  {
    return (String)getAttributeInternal(INSTALLCITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallCity
   */
  public void setInstallCity(String value)
  {
    setAttributeInternal(INSTALLCITY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAddress1
   */
  public String getInstallAddress1()
  {
    return (String)getAttributeInternal(INSTALLADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAddress1
   */
  public void setInstallAddress1(String value)
  {
    setAttributeInternal(INSTALLADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAddress2
   */
  public String getInstallAddress2()
  {
    return (String)getAttributeInternal(INSTALLADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAddress2
   */
  public void setInstallAddress2(String value)
  {
    setAttributeInternal(INSTALLADDRESS2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CntrctCustomerId
   */
  public Number getCntrctCustomerId()
  {
    return (Number)getAttributeInternal(CNTRCTCUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CntrctCustomerId
   */
  public void setCntrctCustomerId(Number value)
  {
    setAttributeInternal(CNTRCTCUSTOMERID, value);
  }













  /**
   * 
   * Gets the attribute value for the calculated attribute SaleBaseCode
   */
  public String getSaleBaseCode()
  {
    return (String)getAttributeInternal(SALEBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SaleBaseCode
   */
  public void setSaleBaseCode(String value)
  {
    setAttributeInternal(SALEBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1SpCustId
   */
  public Number getBm1SpCustId()
  {
    return (Number)getAttributeInternal(BM1SPCUSTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1SpCustId
   */
  public void setBm1SpCustId(Number value)
  {
    setAttributeInternal(BM1SPCUSTID, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute LineCount
   */
  public String getLineCount()
  {
    return (String)getAttributeInternal(LINECOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LineCount
   */
  public void setLineCount(String value)
  {
    setAttributeInternal(LINECOUNT, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute BaseLeaderName
   */
  public String getBaseLeaderName()
  {
    return (String)getAttributeInternal(BASELEADERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseLeaderName
   */
  public void setBaseLeaderName(String value)
  {
    setAttributeInternal(BASELEADERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SaleBaseName
   */
  public String getSaleBaseName()
  {
    return (String)getAttributeInternal(SALEBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SaleBaseName
   */
  public void setSaleBaseName(String value)
  {
    setAttributeInternal(SALEBASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LocationAddress
   */
  public String getLocationAddress()
  {
    return (String)getAttributeInternal(LOCATIONADDRESS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LocationAddress
   */
  public void setLocationAddress(String value)
  {
    setAttributeInternal(LOCATIONADDRESS, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute BaseLeaderPositionName
   */
  public String getBaseLeaderPositionName()
  {
    return (String)getAttributeInternal(BASELEADERPOSITIONNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseLeaderPositionName
   */
  public void setBaseLeaderPositionName(String value)
  {
    setAttributeInternal(BASELEADERPOSITIONNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OtherContent
   */
  public String getOtherContent()
  {
    return (String)getAttributeInternal(OTHERCONTENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OtherContent
   */
  public void setOtherContent(String value)
  {
    setAttributeInternal(OTHERCONTENT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1PaymentType
   */
  public String getBm1PaymentType()
  {
    return (String)getAttributeInternal(BM1PAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1PaymentType
   */
  public void setBm1PaymentType(String value)
  {
    setAttributeInternal(BM1PAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2SpCustId
   */
  public Number getBm2SpCustId()
  {
    return (Number)getAttributeInternal(BM2SPCUSTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2SpCustId
   */
  public void setBm2SpCustId(Number value)
  {
    setAttributeInternal(BM2SPCUSTID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2PaymentType
   */
  public String getBm2PaymentType()
  {
    return (String)getAttributeInternal(BM2PAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2PaymentType
   */
  public void setBm2PaymentType(String value)
  {
    setAttributeInternal(BM2PAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3SpCustId
   */
  public Number getBm3SpCustId()
  {
    return (Number)getAttributeInternal(BM3SPCUSTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3SpCustId
   */
  public void setBm3SpCustId(Number value)
  {
    setAttributeInternal(BM3SPCUSTID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3PaymentType
   */
  public String getBm3PaymentType()
  {
    return (String)getAttributeInternal(BM3PAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3PaymentType
   */
  public void setBm3PaymentType(String value)
  {
    setAttributeInternal(BM3PAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractYearDate
   */
  public Number getContractYearDate()
  {
    return (Number)getAttributeInternal(CONTRACTYEARDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractYearDate
   */
  public void setContractYearDate(Number value)
  {
    setAttributeInternal(CONTRACTYEARDATE, value);
  }
}
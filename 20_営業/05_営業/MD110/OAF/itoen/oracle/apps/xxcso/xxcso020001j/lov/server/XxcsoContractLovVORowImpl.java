/*============================================================================
* ファイル名 : XxcsoContractLovVORowImpl
* 概要説明   : 契約先コードLOV用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 契約先コードのLOVのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractLovVORowImpl extends OAViewRowImpl 
{
  protected static final int CONTRACTNUMBER = 0;


  protected static final int CONTRACTCUSTOMERID = 1;
  protected static final int CONTRACTNAME = 2;
  protected static final int CONTRACTNAMEKANA = 3;
  protected static final int POSTCODEFIRST = 4;
  protected static final int POSTCODESECOND = 5;
  protected static final int POSTCODE = 6;
  protected static final int PREFECTURES = 7;
  protected static final int CITYWARD = 8;
  protected static final int ADDRESS1 = 9;
  protected static final int ADDRESS2 = 10;
  protected static final int PHONENUMBER = 11;
  protected static final int DELEGATENAME = 12;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNumber
   */
  public Number getContractNumber()
  {
    return (Number)getAttributeInternal(CONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNumber
   */
  public void setContractNumber(Number value)
  {
    setAttributeInternal(CONTRACTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractCustomerId
   */
  public Number getContractCustomerId()
  {
    return (Number)getAttributeInternal(CONTRACTCUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractCustomerId
   */
  public void setContractCustomerId(Number value)
  {
    setAttributeInternal(CONTRACTCUSTOMERID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractName
   */
  public String getContractName()
  {
    return (String)getAttributeInternal(CONTRACTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractName
   */
  public void setContractName(String value)
  {
    setAttributeInternal(CONTRACTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNameKana
   */
  public String getContractNameKana()
  {
    return (String)getAttributeInternal(CONTRACTNAMEKANA);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNameKana
   */
  public void setContractNameKana(String value)
  {
    setAttributeInternal(CONTRACTNAMEKANA, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PostCodeFirst
   */
  public String getPostCodeFirst()
  {
    return (String)getAttributeInternal(POSTCODEFIRST);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostCodeFirst
   */
  public void setPostCodeFirst(String value)
  {
    setAttributeInternal(POSTCODEFIRST, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PostCodeSecond
   */
  public String getPostCodeSecond()
  {
    return (String)getAttributeInternal(POSTCODESECOND);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostCodeSecond
   */
  public void setPostCodeSecond(String value)
  {
    setAttributeInternal(POSTCODESECOND, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PostCode
   */
  public String getPostCode()
  {
    return (String)getAttributeInternal(POSTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostCode
   */
  public void setPostCode(String value)
  {
    setAttributeInternal(POSTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Prefectures
   */
  public String getPrefectures()
  {
    return (String)getAttributeInternal(PREFECTURES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Prefectures
   */
  public void setPrefectures(String value)
  {
    setAttributeInternal(PREFECTURES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CityWard
   */
  public String getCityWard()
  {
    return (String)getAttributeInternal(CITYWARD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CityWard
   */
  public void setCityWard(String value)
  {
    setAttributeInternal(CITYWARD, value);
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
   * Gets the attribute value for the calculated attribute DelegateName
   */
  public String getDelegateName()
  {
    return (String)getAttributeInternal(DELEGATENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelegateName
   */
  public void setDelegateName(String value)
  {
    setAttributeInternal(DELEGATENAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CONTRACTNUMBER:
        return getContractNumber();
      case CONTRACTCUSTOMERID:
        return getContractCustomerId();
      case CONTRACTNAME:
        return getContractName();
      case CONTRACTNAMEKANA:
        return getContractNameKana();
      case POSTCODEFIRST:
        return getPostCodeFirst();
      case POSTCODESECOND:
        return getPostCodeSecond();
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
      case PHONENUMBER:
        return getPhoneNumber();
      case DELEGATENAME:
        return getDelegateName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CONTRACTNUMBER:
        setContractNumber((Number)value);
        return;
      case CONTRACTCUSTOMERID:
        setContractCustomerId((Number)value);
        return;
      case CONTRACTNAME:
        setContractName((String)value);
        return;
      case CONTRACTNAMEKANA:
        setContractNameKana((String)value);
        return;
      case POSTCODEFIRST:
        setPostCodeFirst((String)value);
        return;
      case POSTCODESECOND:
        setPostCodeSecond((String)value);
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
      case PHONENUMBER:
        setPhoneNumber((String)value);
        return;
      case DELEGATENAME:
        setDelegateName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
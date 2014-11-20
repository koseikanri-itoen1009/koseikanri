/*============================================================================
* ファイル名 : XxcsoQuoteHeaderSalesSumVORowImpl
* 概要説明   : 見積ヘッダー販売参照用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * 見積ヘッダーの販売情報を参照するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteHeaderSalesSumVORowImpl extends OAViewRowImpl 
{


  protected static final int QUOTEHEADERID = 0;
  protected static final int QUOTENUMBER = 1;
  protected static final int STORENAME = 2;
  protected static final int ACCOUNTNUMBER = 3;
  protected static final int PARTYNAME = 4;
  protected static final int DELIVPLACE = 5;
  protected static final int PAYMENTCONDITION = 6;
  protected static final int QUOTESUBMITNAME = 7;
  protected static final int DELIVPRICETAXTYPE = 8;
  protected static final int UNITTYPE = 9;
  protected static final int SPECIALNOTE = 10;
  protected static final int STOREPRICETAXTYPE = 11;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteHeaderSalesSumVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteHeaderId
   */
  public Number getQuoteHeaderId()
  {
    return (Number)getAttributeInternal(QUOTEHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteHeaderId
   */
  public void setQuoteHeaderId(Number value)
  {
    setAttributeInternal(QUOTEHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteNumber
   */
  public String getQuoteNumber()
  {
    return (String)getAttributeInternal(QUOTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteNumber
   */
  public void setQuoteNumber(String value)
  {
    setAttributeInternal(QUOTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StoreName
   */
  public String getStoreName()
  {
    return (String)getAttributeInternal(STORENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StoreName
   */
  public void setStoreName(String value)
  {
    setAttributeInternal(STORENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyName
   */
  public String getPartyName()
  {
    return (String)getAttributeInternal(PARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyName
   */
  public void setPartyName(String value)
  {
    setAttributeInternal(PARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelivPlace
   */
  public String getDelivPlace()
  {
    return (String)getAttributeInternal(DELIVPLACE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelivPlace
   */
  public void setDelivPlace(String value)
  {
    setAttributeInternal(DELIVPLACE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PaymentCondition
   */
  public String getPaymentCondition()
  {
    return (String)getAttributeInternal(PAYMENTCONDITION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PaymentCondition
   */
  public void setPaymentCondition(String value)
  {
    setAttributeInternal(PAYMENTCONDITION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteSubmitName
   */
  public String getQuoteSubmitName()
  {
    return (String)getAttributeInternal(QUOTESUBMITNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteSubmitName
   */
  public void setQuoteSubmitName(String value)
  {
    setAttributeInternal(QUOTESUBMITNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelivPriceTaxType
   */
  public String getDelivPriceTaxType()
  {
    return (String)getAttributeInternal(DELIVPRICETAXTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelivPriceTaxType
   */
  public void setDelivPriceTaxType(String value)
  {
    setAttributeInternal(DELIVPRICETAXTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UnitType
   */
  public String getUnitType()
  {
    return (String)getAttributeInternal(UNITTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UnitType
   */
  public void setUnitType(String value)
  {
    setAttributeInternal(UNITTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpecialNote
   */
  public String getSpecialNote()
  {
    return (String)getAttributeInternal(SPECIALNOTE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpecialNote
   */
  public void setSpecialNote(String value)
  {
    setAttributeInternal(SPECIALNOTE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTEHEADERID:
        return getQuoteHeaderId();
      case QUOTENUMBER:
        return getQuoteNumber();
      case STORENAME:
        return getStoreName();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case PARTYNAME:
        return getPartyName();
      case DELIVPLACE:
        return getDelivPlace();
      case PAYMENTCONDITION:
        return getPaymentCondition();
      case QUOTESUBMITNAME:
        return getQuoteSubmitName();
      case DELIVPRICETAXTYPE:
        return getDelivPriceTaxType();
      case UNITTYPE:
        return getUnitType();
      case SPECIALNOTE:
        return getSpecialNote();
      case STOREPRICETAXTYPE:
        return getStorePriceTaxType();
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
      case QUOTENUMBER:
        setQuoteNumber((String)value);
        return;
      case STORENAME:
        setStoreName((String)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
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
      case DELIVPRICETAXTYPE:
        setDelivPriceTaxType((String)value);
        return;
      case UNITTYPE:
        setUnitType((String)value);
        return;
      case SPECIALNOTE:
        setSpecialNote((String)value);
        return;
      case STOREPRICETAXTYPE:
        setStorePriceTaxType((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StorePriceTaxType
   */
  public String getStorePriceTaxType()
  {
    return (String)getAttributeInternal(STOREPRICETAXTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StorePriceTaxType
   */
  public void setStorePriceTaxType(String value)
  {
    setAttributeInternal(STOREPRICETAXTYPE, value);
  }
}
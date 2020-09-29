/*============================================================================
* ファイル名 : XxcsoElectricVORowImpl
* 概要説明   : 電気代ビュー行オブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者         修正内容
* ---------- ---- -------------- --------------------------------------------
* 2020-08-21 1.0  SCSK佐々木大和 新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 電気代ビュー行オブジェクトクラス
 * @author  SCSK佐々木大和
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoElectricVORowImpl extends OAViewRowImpl 
{


  protected static final int SPDECISIONNUMBE = 0;
  protected static final int ELECTRICITYTYPE = 1;
  protected static final int ELECTRICITYMEAN = 2;
  protected static final int ELECTRICITYAMOUNT = 3;
  protected static final int ELECTRICPAYMENTTYPE = 4;
  protected static final int ELECTRICPAYMENTMEAN = 5;
  protected static final int ELECTRICPAYMENTCHANGETYPE = 6;
  protected static final int ELECTRICPAYMENTCHANGEMEAN = 7;
  protected static final int ELECTRICPAYMENTCYCLE = 8;
  protected static final int ELECTRICPAYMENTCYCLEMEAN = 9;
  protected static final int ELECTRICCLOSINGDATE = 10;
  protected static final int ELECTRICCLOSINGDATEMEAN = 11;
  protected static final int ELECTRICTRANSMONTH = 12;
  protected static final int ELECTRICTRANSMONTHMEAN = 13;
  protected static final int ELECTRICTRANSDATE = 14;
  protected static final int ELECTRICTRANSDATEMEAN = 15;
  protected static final int ELECTRICTRANSNAME = 16;
  protected static final int ELECTRICTRANSNAMEALT = 17;
  protected static final int BM1TAXKBN = 18;
  protected static final int BM2TAXKBN = 19;
  protected static final int BM3TAXKBN = 20;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoElectricVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionNumbe
   */
  public String getSpDecisionNumbe()
  {
    return (String)getAttributeInternal(SPDECISIONNUMBE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionNumbe
   */
  public void setSpDecisionNumbe(String value)
  {
    setAttributeInternal(SPDECISIONNUMBE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricityType
   */
  public String getElectricityType()
  {
    return (String)getAttributeInternal(ELECTRICITYTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricityType
   */
  public void setElectricityType(String value)
  {
    setAttributeInternal(ELECTRICITYTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricityMean
   */
  public String getElectricityMean()
  {
    return (String)getAttributeInternal(ELECTRICITYMEAN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricityMean
   */
  public void setElectricityMean(String value)
  {
    setAttributeInternal(ELECTRICITYMEAN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricityAmount
   */
  public Number getElectricityAmount()
  {
    return (Number)getAttributeInternal(ELECTRICITYAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricityAmount
   */
  public void setElectricityAmount(Number value)
  {
    setAttributeInternal(ELECTRICITYAMOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentType
   */
  public String getElectricPaymentType()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentType
   */
  public void setElectricPaymentType(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentMean
   */
  public String getElectricPaymentMean()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTMEAN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentMean
   */
  public void setElectricPaymentMean(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTMEAN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentChangeType
   */
  public String getElectricPaymentChangeType()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTCHANGETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentChangeType
   */
  public void setElectricPaymentChangeType(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTCHANGETYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentChangeMean
   */
  public String getElectricPaymentChangeMean()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTCHANGEMEAN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentChangeMean
   */
  public void setElectricPaymentChangeMean(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTCHANGEMEAN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentCycle
   */
  public String getElectricPaymentCycle()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTCYCLE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentCycle
   */
  public void setElectricPaymentCycle(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTCYCLE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentCycleMean
   */
  public String getElectricPaymentCycleMean()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTCYCLEMEAN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentCycleMean
   */
  public void setElectricPaymentCycleMean(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTCYCLEMEAN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricClosingDate
   */
  public String getElectricClosingDate()
  {
    return (String)getAttributeInternal(ELECTRICCLOSINGDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricClosingDate
   */
  public void setElectricClosingDate(String value)
  {
    setAttributeInternal(ELECTRICCLOSINGDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricClosingDateMean
   */
  public String getElectricClosingDateMean()
  {
    return (String)getAttributeInternal(ELECTRICCLOSINGDATEMEAN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricClosingDateMean
   */
  public void setElectricClosingDateMean(String value)
  {
    setAttributeInternal(ELECTRICCLOSINGDATEMEAN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransMonth
   */
  public String getElectricTransMonth()
  {
    return (String)getAttributeInternal(ELECTRICTRANSMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransMonth
   */
  public void setElectricTransMonth(String value)
  {
    setAttributeInternal(ELECTRICTRANSMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransMonthMean
   */
  public String getElectricTransMonthMean()
  {
    return (String)getAttributeInternal(ELECTRICTRANSMONTHMEAN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransMonthMean
   */
  public void setElectricTransMonthMean(String value)
  {
    setAttributeInternal(ELECTRICTRANSMONTHMEAN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransDate
   */
  public String getElectricTransDate()
  {
    return (String)getAttributeInternal(ELECTRICTRANSDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransDate
   */
  public void setElectricTransDate(String value)
  {
    setAttributeInternal(ELECTRICTRANSDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransDateMean
   */
  public String getElectricTransDateMean()
  {
    return (String)getAttributeInternal(ELECTRICTRANSDATEMEAN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransDateMean
   */
  public void setElectricTransDateMean(String value)
  {
    setAttributeInternal(ELECTRICTRANSDATEMEAN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransName
   */
  public String getElectricTransName()
  {
    return (String)getAttributeInternal(ELECTRICTRANSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransName
   */
  public void setElectricTransName(String value)
  {
    setAttributeInternal(ELECTRICTRANSNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransNameAlt
   */
  public String getElectricTransNameAlt()
  {
    return (String)getAttributeInternal(ELECTRICTRANSNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransNameAlt
   */
  public void setElectricTransNameAlt(String value)
  {
    setAttributeInternal(ELECTRICTRANSNAMEALT, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONNUMBE:
        return getSpDecisionNumbe();
      case ELECTRICITYTYPE:
        return getElectricityType();
      case ELECTRICITYMEAN:
        return getElectricityMean();
      case ELECTRICITYAMOUNT:
        return getElectricityAmount();
      case ELECTRICPAYMENTTYPE:
        return getElectricPaymentType();
      case ELECTRICPAYMENTMEAN:
        return getElectricPaymentMean();
      case ELECTRICPAYMENTCHANGETYPE:
        return getElectricPaymentChangeType();
      case ELECTRICPAYMENTCHANGEMEAN:
        return getElectricPaymentChangeMean();
      case ELECTRICPAYMENTCYCLE:
        return getElectricPaymentCycle();
      case ELECTRICPAYMENTCYCLEMEAN:
        return getElectricPaymentCycleMean();
      case ELECTRICCLOSINGDATE:
        return getElectricClosingDate();
      case ELECTRICCLOSINGDATEMEAN:
        return getElectricClosingDateMean();
      case ELECTRICTRANSMONTH:
        return getElectricTransMonth();
      case ELECTRICTRANSMONTHMEAN:
        return getElectricTransMonthMean();
      case ELECTRICTRANSDATE:
        return getElectricTransDate();
      case ELECTRICTRANSDATEMEAN:
        return getElectricTransDateMean();
      case ELECTRICTRANSNAME:
        return getElectricTransName();
      case ELECTRICTRANSNAMEALT:
        return getElectricTransNameAlt();
      case BM1TAXKBN:
        return getBm1TaxKbn();
      case BM2TAXKBN:
        return getBm2TaxKbn();
      case BM3TAXKBN:
        return getBm3TaxKbn();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONNUMBE:
        setSpDecisionNumbe((String)value);
        return;
      case ELECTRICITYTYPE:
        setElectricityType((String)value);
        return;
      case ELECTRICITYMEAN:
        setElectricityMean((String)value);
        return;
      case ELECTRICITYAMOUNT:
        setElectricityAmount((Number)value);
        return;
      case ELECTRICPAYMENTTYPE:
        setElectricPaymentType((String)value);
        return;
      case ELECTRICPAYMENTMEAN:
        setElectricPaymentMean((String)value);
        return;
      case ELECTRICPAYMENTCHANGETYPE:
        setElectricPaymentChangeType((String)value);
        return;
      case ELECTRICPAYMENTCHANGEMEAN:
        setElectricPaymentChangeMean((String)value);
        return;
      case ELECTRICPAYMENTCYCLE:
        setElectricPaymentCycle((String)value);
        return;
      case ELECTRICPAYMENTCYCLEMEAN:
        setElectricPaymentCycleMean((String)value);
        return;
      case ELECTRICCLOSINGDATE:
        setElectricClosingDate((String)value);
        return;
      case ELECTRICCLOSINGDATEMEAN:
        setElectricClosingDateMean((String)value);
        return;
      case ELECTRICTRANSMONTH:
        setElectricTransMonth((String)value);
        return;
      case ELECTRICTRANSMONTHMEAN:
        setElectricTransMonthMean((String)value);
        return;
      case ELECTRICTRANSDATE:
        setElectricTransDate((String)value);
        return;
      case ELECTRICTRANSDATEMEAN:
        setElectricTransDateMean((String)value);
        return;
      case ELECTRICTRANSNAME:
        setElectricTransName((String)value);
        return;
      case ELECTRICTRANSNAMEALT:
        setElectricTransNameAlt((String)value);
        return;
      case BM1TAXKBN:
        setBm1TaxKbn((String)value);
        return;
      case BM2TAXKBN:
        setBm2TaxKbn((String)value);
        return;
      case BM3TAXKBN:
        setBm3TaxKbn((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1TaxKbn
   */
  public String getBm1TaxKbn()
  {
    return (String)getAttributeInternal(BM1TAXKBN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1TaxKbn
   */
  public void setBm1TaxKbn(String value)
  {
    setAttributeInternal(BM1TAXKBN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2TaxKbn
   */
  public String getBm2TaxKbn()
  {
    return (String)getAttributeInternal(BM2TAXKBN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2TaxKbn
   */
  public void setBm2TaxKbn(String value)
  {
    setAttributeInternal(BM2TAXKBN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3TaxKbn
   */
  public String getBm3TaxKbn()
  {
    return (String)getAttributeInternal(BM3TAXKBN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3TaxKbn
   */
  public void setBm3TaxKbn(String value)
  {
    setAttributeInternal(BM3TAXKBN, value);
  }
}
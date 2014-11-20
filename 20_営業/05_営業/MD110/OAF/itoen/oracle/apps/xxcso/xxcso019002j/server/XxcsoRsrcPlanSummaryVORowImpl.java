/*============================================================================
* ファイル名 : XxcsoRsrcPlanSummaryVOImpl
* 概要説明   : 売上計画(複数顧客)　営業員計画情報リージョンビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;

import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 売上計画(複数顧客)　営業員計画情報リージョンビュー行クラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRsrcPlanSummaryVORowImpl extends OAViewRowImpl 
{






  protected static final int EMPLOYEENUMBER = 0;
  protected static final int BASECODE = 1;
  protected static final int TARGETYEARMONTH = 2;
  protected static final int TARGETYEARMONTHVIEW = 3;
  protected static final int NEXTYEARMONTH = 4;
  protected static final int NEXTYEARMONTHVIEW = 5;
  protected static final int TARGETRSRCPLAN = 6;
  protected static final int TARGETRSRCACCTPLANSUM = 7;
  protected static final int TRGTRSRCDIFFER = 8;
  protected static final int NEXTRSRCPLAN = 9;
  protected static final int NEXTRSRCACCTPLANSUM = 10;
  protected static final int NEXTRSRCDIFFER = 11;
  protected static final int READONLYVALUE = 12;
  protected static final int READONLYFLG = 13;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRsrcPlanSummaryVORowImpl()
  {
  }




















  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case BASECODE:
        return getBaseCode();
      case TARGETYEARMONTH:
        return getTargetYearMonth();
      case TARGETYEARMONTHVIEW:
        return getTargetYearMonthView();
      case NEXTYEARMONTH:
        return getNextYearMonth();
      case NEXTYEARMONTHVIEW:
        return getNextYearMonthView();
      case TARGETRSRCPLAN:
        return getTargetRsrcPlan();
      case TARGETRSRCACCTPLANSUM:
        return getTargetRsrcAcctPlanSum();
      case TRGTRSRCDIFFER:
        return getTrgtRsrcDiffer();
      case NEXTRSRCPLAN:
        return getNextRsrcPlan();
      case NEXTRSRCACCTPLANSUM:
        return getNextRsrcAcctPlanSum();
      case NEXTRSRCDIFFER:
        return getNextRsrcDiffer();
      case READONLYVALUE:
        return getReadonlyValue();
      case READONLYFLG:
        return getReadOnlyFlg();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case TARGETYEARMONTH:
        setTargetYearMonth((String)value);
        return;
      case TARGETYEARMONTHVIEW:
        setTargetYearMonthView((String)value);
        return;
      case NEXTYEARMONTH:
        setNextYearMonth((String)value);
        return;
      case NEXTYEARMONTHVIEW:
        setNextYearMonthView((String)value);
        return;
      case TARGETRSRCPLAN:
        setTargetRsrcPlan((String)value);
        return;
      case TARGETRSRCACCTPLANSUM:
        setTargetRsrcAcctPlanSum((String)value);
        return;
      case TRGTRSRCDIFFER:
        setTrgtRsrcDiffer((String)value);
        return;
      case NEXTRSRCPLAN:
        setNextRsrcPlan((String)value);
        return;
      case NEXTRSRCACCTPLANSUM:
        setNextRsrcAcctPlanSum((String)value);
        return;
      case NEXTRSRCDIFFER:
        setNextRsrcDiffer((String)value);
        return;
      case READONLYVALUE:
        setReadonlyValue((String)value);
        return;
      case READONLYFLG:
        setReadOnlyFlg((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetYearMonth
   */
  public String getTargetYearMonth()
  {
    return (String)getAttributeInternal(TARGETYEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetYearMonth
   */
  public void setTargetYearMonth(String value)
  {
    setAttributeInternal(TARGETYEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetYearMonthView
   */
  public String getTargetYearMonthView()
  {
    return (String)getAttributeInternal(TARGETYEARMONTHVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetYearMonthView
   */
  public void setTargetYearMonthView(String value)
  {
    setAttributeInternal(TARGETYEARMONTHVIEW, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NextYearMonth
   */
  public String getNextYearMonth()
  {
    return (String)getAttributeInternal(NEXTYEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NextYearMonth
   */
  public void setNextYearMonth(String value)
  {
    setAttributeInternal(NEXTYEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NextYearMonthView
   */
  public String getNextYearMonthView()
  {
    return (String)getAttributeInternal(NEXTYEARMONTHVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NextYearMonthView
   */
  public void setNextYearMonthView(String value)
  {
    setAttributeInternal(NEXTYEARMONTHVIEW, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetRsrcPlan
   */
  public String getTargetRsrcPlan()
  {
    return (String)getAttributeInternal(TARGETRSRCPLAN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetRsrcPlan
   */
  public void setTargetRsrcPlan(String value)
  {
    setAttributeInternal(TARGETRSRCPLAN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetRsrcAcctPlanSum
   */
  public String getTargetRsrcAcctPlanSum()
  {
    return (String)getAttributeInternal(TARGETRSRCACCTPLANSUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetRsrcAcctPlanSum
   */
  public void setTargetRsrcAcctPlanSum(String value)
  {
    setAttributeInternal(TARGETRSRCACCTPLANSUM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TrgtRsrcDiffer
   */
  public String getTrgtRsrcDiffer()
  {
    return (String)getAttributeInternal(TRGTRSRCDIFFER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TrgtRsrcDiffer
   */
  public void setTrgtRsrcDiffer(String value)
  {
    setAttributeInternal(TRGTRSRCDIFFER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NextRsrcPlan
   */
  public String getNextRsrcPlan()
  {
    return (String)getAttributeInternal(NEXTRSRCPLAN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NextRsrcPlan
   */
  public void setNextRsrcPlan(String value)
  {
    setAttributeInternal(NEXTRSRCPLAN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NextRsrcAcctPlanSum
   */
  public String getNextRsrcAcctPlanSum()
  {
    return (String)getAttributeInternal(NEXTRSRCACCTPLANSUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NextRsrcAcctPlanSum
   */
  public void setNextRsrcAcctPlanSum(String value)
  {
    setAttributeInternal(NEXTRSRCACCTPLANSUM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NextRsrcDiffer
   */
  public String getNextRsrcDiffer()
  {
    return (String)getAttributeInternal(NEXTRSRCDIFFER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NextRsrcDiffer
   */
  public void setNextRsrcDiffer(String value)
  {
    setAttributeInternal(NEXTRSRCDIFFER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ReadonlyValue
   */
  public String getReadonlyValue()
  {
    return (String)getAttributeInternal(READONLYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ReadonlyValue
   */
  public void setReadonlyValue(String value)
  {
    setAttributeInternal(READONLYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ReadOnlyFlg
   */
  public Boolean getReadOnlyFlg()
  {
    return (Boolean)getAttributeInternal(READONLYFLG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ReadOnlyFlg
   */
  public void setReadOnlyFlg(Boolean value)
  {
    setAttributeInternal(READONLYFLG, value);
  }





















}
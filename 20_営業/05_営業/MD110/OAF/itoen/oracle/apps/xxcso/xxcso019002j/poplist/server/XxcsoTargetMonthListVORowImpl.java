/*============================================================================
* ファイル名 : XxcsoTargetMonthListVOImpl
* 概要説明   : 売上計画(複数顧客)　対象年ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.poplist.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 売上計画(複数顧客)　対象年ビュー行クラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTargetMonthListVORowImpl extends OAViewRowImpl 
{


  protected static final int TARGETMONTH = 0;
  protected static final int TARGETMONTHVIEW = 1;
  protected static final int TARGETMONTHINDEX = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoTargetMonthListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetMonth
   */
  public String getTargetMonth()
  {
    return (String)getAttributeInternal(TARGETMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetMonth
   */
  public void setTargetMonth(String value)
  {
    setAttributeInternal(TARGETMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetMonthView
   */
  public String getTargetMonthView()
  {
    return (String)getAttributeInternal(TARGETMONTHVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetMonthView
   */
  public void setTargetMonthView(String value)
  {
    setAttributeInternal(TARGETMONTHVIEW, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetMonthIndex
   */
  public Number getTargetMonthIndex()
  {
    return (Number)getAttributeInternal(TARGETMONTHINDEX);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetMonthIndex
   */
  public void setTargetMonthIndex(Number value)
  {
    setAttributeInternal(TARGETMONTHINDEX, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TARGETMONTH:
        return getTargetMonth();
      case TARGETMONTHVIEW:
        return getTargetMonthView();
      case TARGETMONTHINDEX:
        return getTargetMonthIndex();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TARGETMONTH:
        setTargetMonth((String)value);
        return;
      case TARGETMONTHVIEW:
        setTargetMonthView((String)value);
        return;
      case TARGETMONTHINDEX:
        setTargetMonthIndex((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
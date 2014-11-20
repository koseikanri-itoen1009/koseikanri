/*============================================================================
* ファイル名 : XxcsoMonthListVORowImpl
* 概要説明   : リスト（月）用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS及川領  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
/*******************************************************************************
 * リスト（月）を作成するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoMonthListVORowImpl extends OAViewRowImpl 
{
  protected static final int MONTHDATE = 0;


  protected static final int MONTHNAME = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoMonthListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MonthDate
   */
  public String getMonthDate()
  {
    return (String)getAttributeInternal(MONTHDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MonthDate
   */
  public void setMonthDate(String value)
  {
    setAttributeInternal(MONTHDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MonthName
   */
  public String getMonthName()
  {
    return (String)getAttributeInternal(MONTHNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MonthName
   */
  public void setMonthName(String value)
  {
    setAttributeInternal(MONTHNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case MONTHDATE:
        return getMonthDate();
      case MONTHNAME:
        return getMonthName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case MONTHDATE:
        setMonthDate((String)value);
        return;
      case MONTHNAME:
        setMonthName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
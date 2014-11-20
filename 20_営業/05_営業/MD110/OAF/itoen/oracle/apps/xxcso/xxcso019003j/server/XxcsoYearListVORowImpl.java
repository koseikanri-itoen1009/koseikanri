/*============================================================================
* ファイル名 : XxcsoYearListVORowImpl
* 概要説明   : リスト（年）用ビュー行クラス
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
 * リスト（年）を作成するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoYearListVORowImpl extends OAViewRowImpl 
{
  protected static final int YEARDATE = 0;


  protected static final int YEARNAME = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoYearListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute YearDate
   */
  public String getYearDate()
  {
    return (String)getAttributeInternal(YEARDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute YearDate
   */
  public void setYearDate(String value)
  {
    setAttributeInternal(YEARDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute YearName
   */
  public String getYearName()
  {
    return (String)getAttributeInternal(YEARNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute YearName
   */
  public void setYearName(String value)
  {
    setAttributeInternal(YEARNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case YEARDATE:
        return getYearDate();
      case YEARNAME:
        return getYearName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case YEARDATE:
        setYearDate((String)value);
        return;
      case YEARNAME:
        setYearName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
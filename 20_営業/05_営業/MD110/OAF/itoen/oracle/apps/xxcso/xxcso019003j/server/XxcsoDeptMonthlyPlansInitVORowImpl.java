/*============================================================================
* ファイル名 : XxcsoDeptMonthlyPlansInitVORowImpl
* 概要説明   : 初期化用ビュー行クラス
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
import oracle.jbo.domain.Date;
/*******************************************************************************
 * 初期化検索するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoDeptMonthlyPlansInitVORowImpl extends OAViewRowImpl 
{
  protected static final int WORKBASECODE = 0;


  protected static final int WORKBASENAME = 1;
  protected static final int CURRENTDATE = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoDeptMonthlyPlansInitVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WorkBaseCode
   */
  public String getWorkBaseCode()
  {
    return (String)getAttributeInternal(WORKBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkBaseCode
   */
  public void setWorkBaseCode(String value)
  {
    setAttributeInternal(WORKBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WorkBaseName
   */
  public String getWorkBaseName()
  {
    return (String)getAttributeInternal(WORKBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkBaseName
   */
  public void setWorkBaseName(String value)
  {
    setAttributeInternal(WORKBASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CurrentDate
   */
  public Date getCurrentDate()
  {
    return (Date)getAttributeInternal(CURRENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CurrentDate
   */
  public void setCurrentDate(Date value)
  {
    setAttributeInternal(CURRENTDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case WORKBASECODE:
        return getWorkBaseCode();
      case WORKBASENAME:
        return getWorkBaseName();
      case CURRENTDATE:
        return getCurrentDate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case WORKBASECODE:
        setWorkBaseCode((String)value);
        return;
      case WORKBASENAME:
        setWorkBaseName((String)value);
        return;
      case CURRENTDATE:
        setCurrentDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
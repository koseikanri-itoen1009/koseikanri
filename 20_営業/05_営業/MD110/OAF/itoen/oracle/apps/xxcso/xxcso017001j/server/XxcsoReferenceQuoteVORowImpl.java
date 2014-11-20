/*============================================================================
* ファイル名 : XxcsoReferenceQuoteVORowImpl
* 概要説明   : 帳合問屋検索用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS及川領  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
/*******************************************************************************
 * 帳合問屋で対象明細を使用しているか検索するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoReferenceQuoteVORowImpl extends OAViewRowImpl 
{







  protected static final int QUOTENUMBER = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoReferenceQuoteVORowImpl()
  {
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTENUMBER:
        return getQuoteNumber();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTENUMBER:
        setQuoteNumber((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
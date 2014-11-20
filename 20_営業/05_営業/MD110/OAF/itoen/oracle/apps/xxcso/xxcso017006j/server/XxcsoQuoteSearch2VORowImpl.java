/*============================================================================
* ファイル名 : XxcsoQuoteSearch2VORowImpl
* 概要説明   : 見積検索ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS張吉    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017006j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 見積検索の版が未入力場合のビュー行クラスです。
 * @author  SCS張吉
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSearch2VORowImpl extends OAViewRowImpl 
{












  protected static final int QUOTEHEADERID = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSearch2VORowImpl()
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTEHEADERID:
        return getQuoteHeaderId();
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
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
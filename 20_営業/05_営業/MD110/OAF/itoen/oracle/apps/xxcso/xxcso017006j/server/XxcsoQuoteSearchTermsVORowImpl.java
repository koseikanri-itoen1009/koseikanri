/*============================================================================
* ファイル名 : XxcsoQuoteSearchTermsVORowImpl
* 概要説明   : 見積検索条件用ビュー行クラス
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

/*******************************************************************************
 * 見積検索条件を設定するためのビュー行クラスです。
 * @author  SCS張吉
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSearchTermsVORowImpl extends OAViewRowImpl 
{


  protected static final int QUOTETYPE = 0;
  protected static final int QUOTENUMBER = 1;
  protected static final int QUOTEREVISIONNUMBER = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSearchTermsVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteType
   */
  public String getQuoteType()
  {
    return (String)getAttributeInternal(QUOTETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteType
   */
  public void setQuoteType(String value)
  {
    setAttributeInternal(QUOTETYPE, value);
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
   * Gets the attribute value for the calculated attribute QuoteRevisionNumber
   */
  public String getQuoteRevisionNumber()
  {
    return (String)getAttributeInternal(QUOTEREVISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteRevisionNumber
   */
  public void setQuoteRevisionNumber(String value)
  {
    setAttributeInternal(QUOTEREVISIONNUMBER, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTETYPE:
        return getQuoteType();
      case QUOTENUMBER:
        return getQuoteNumber();
      case QUOTEREVISIONNUMBER:
        return getQuoteRevisionNumber();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTETYPE:
        setQuoteType((String)value);
        return;
      case QUOTENUMBER:
        setQuoteNumber((String)value);
        return;
      case QUOTEREVISIONNUMBER:
        setQuoteRevisionNumber((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
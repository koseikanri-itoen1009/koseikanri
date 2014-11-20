/*============================================================================
* ファイル名 : XxcsoRefQuoteNumberLovVORowImpl
* 概要説明   : 参照用見積番号LOV用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * 参照用見積番号のLOVのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRefQuoteNumberLovVORowImpl extends OAViewRowImpl 
{


  protected static final int QUOTEHEADERID = 0;
  protected static final int QUOTENUMBER = 1;
  protected static final int QUOTEREVISIONNUMBER = 2;
  protected static final int ACCOUNTNUMBER = 3;
  protected static final int PARTYNAME = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRefQuoteNumberLovVORowImpl()
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
   * Gets the attribute value for the calculated attribute QuoteRevisionNumber
   */
  public Number getQuoteRevisionNumber()
  {
    return (Number)getAttributeInternal(QUOTEREVISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteRevisionNumber
   */
  public void setQuoteRevisionNumber(Number value)
  {
    setAttributeInternal(QUOTEREVISIONNUMBER, value);
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTEHEADERID:
        return getQuoteHeaderId();
      case QUOTENUMBER:
        return getQuoteNumber();
      case QUOTEREVISIONNUMBER:
        return getQuoteRevisionNumber();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case PARTYNAME:
        return getPartyName();
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
      case QUOTEREVISIONNUMBER:
        setQuoteRevisionNumber((Number)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
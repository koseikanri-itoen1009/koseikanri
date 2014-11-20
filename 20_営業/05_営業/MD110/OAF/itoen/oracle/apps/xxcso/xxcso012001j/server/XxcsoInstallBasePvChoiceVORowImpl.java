/*============================================================================
* ファイル名 : XxcsoInstallBasePvChoiceVORowImpl
* 概要説明   : 物件情報汎用検索画面／ビュー指定LOOKUP検索ビュー行オブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-17 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * ビュー指定LOOKUP検索を検索するためのビュー行クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBasePvChoiceVORowImpl extends OAViewRowImpl 
{

  protected static final int VIEWID = 0;
  protected static final int VIEWNAME = 1;
  protected static final int CREATIONDATE = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBasePvChoiceVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ViewId
   */
  public Number getViewId()
  {
    return (Number)getAttributeInternal(VIEWID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ViewId
   */
  public void setViewId(Number value)
  {
    setAttributeInternal(VIEWID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ViewName
   */
  public String getViewName()
  {
    return (String)getAttributeInternal(VIEWNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ViewName
   */
  public void setViewName(String value)
  {
    setAttributeInternal(VIEWNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VIEWID:
        return getViewId();
      case VIEWNAME:
        return getViewName();
      case CREATIONDATE:
        return getCreationDate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VIEWID:
        setViewId((Number)value);
        return;
      case VIEWNAME:
        setViewName((String)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
/*============================================================================
* ファイル名 : XxcsoInstallBaseSortColumnVORowImpl
* 概要説明   : 物件情報汎用検索画面／ソート条件取得ビュー行オブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-23 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * ソート条件を取得するためのビュー行クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBaseSortColumnVORowImpl extends OAViewRowImpl 
{


  protected static final int SORTCOLUMN = 0;
  protected static final int SORTDIRECTION = 1;
  protected static final int ENABLEFLAG = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBaseSortColumnVORowImpl()
  {
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute EnableFlag
   */
  public String getEnableFlag()
  {
    return (String)getAttributeInternal(ENABLEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EnableFlag
   */
  public void setEnableFlag(String value)
  {
    setAttributeInternal(ENABLEFLAG, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SORTCOLUMN:
        return getSortColumn();
      case SORTDIRECTION:
        return getSortDirection();
      case ENABLEFLAG:
        return getEnableFlag();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ENABLEFLAG:
        setEnableFlag((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SortDirection
   */
  public String getSortDirection()
  {
    return (String)getAttributeInternal(SORTDIRECTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SortDirection
   */
  public void setSortDirection(String value)
  {
    setAttributeInternal(SORTDIRECTION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SortColumn
   */
  public String getSortColumn()
  {
    return (String)getAttributeInternal(SORTCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SortColumn
   */
  public void setSortColumn(String value)
  {
    setAttributeInternal(SORTCOLUMN, value);
  }
}
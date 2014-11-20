/*============================================================================
* ファイル名 : XxcsoInstallBaseViewSizeVORowImpl
* 概要説明   : 物件情報汎用検索画面／表示行数ビュー行オブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-25 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 表示行数を取得するためのビュー行クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBaseViewSizeVORowImpl extends OAViewRowImpl 
{

  protected static final int VIEWSIZE = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBaseViewSizeVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VIEWSIZE:
        return getViewSize();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VIEWSIZE:
        setViewSize((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ViewSize
   */
  public String getViewSize()
  {
    return (String)getAttributeInternal(VIEWSIZE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ViewSize
   */
  public void setViewSize(String value)
  {
    setAttributeInternal(VIEWSIZE, value);
  }
}
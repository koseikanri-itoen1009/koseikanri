/*============================================================================
* ファイル名 : XxcsoLoginUserAuthorityVORowImpl
* 概要説明   : ログインユーザー権限取得ビュー行オブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-28 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * ログインユーザー権限取得ビュー行オブジェクトクラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoLoginUserAuthorityVORowImpl extends OAViewRowImpl 
{











  protected static final int USERAUTHORITY = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoLoginUserAuthorityVORowImpl()
  {
  }






  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case USERAUTHORITY:
        return getUserAuthority();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UserAuthority
   */
  public String getUserAuthority()
  {
    return (String)getAttributeInternal(USERAUTHORITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UserAuthority
   */
  public void setUserAuthority(String value)
  {
    setAttributeInternal(USERAUTHORITY, value);
  }



}
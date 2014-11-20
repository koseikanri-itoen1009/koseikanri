/*============================================================================
* ファイル名 : XxcsoContractAuthorityCheckVORowImpl
* 概要説明   : 権限チェック行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-20 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
/*******************************************************************************
 * 権限チェックするためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractAuthorityCheckVORowImpl extends OAViewRowImpl 
{







  protected static final int AUTHORITY = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractAuthorityCheckVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case AUTHORITY:
        return getAuthority();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case AUTHORITY:
        setAuthority((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Authority
   */
  public String getAuthority()
  {
    return (String)getAttributeInternal(AUTHORITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Authority
   */
  public void setAuthority(String value)
  {
    setAttributeInternal(AUTHORITY, value);
  }
}
/*============================================================================
* ファイル名 : XxcsoGetAutoAssignedCodeVVORowImpl
* 概要説明   : 自動採番コード取得ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 自動採番されたコードを取得するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoGetAutoAssignedCodeVVORowImpl extends OAViewRowImpl 
{

  protected static final int AUTOASSIGNEDCODE = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoGetAutoAssignedCodeVVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AutoAssignedCode
   */
  public String getAutoAssignedCode()
  {
    return (String)getAttributeInternal(AUTOASSIGNEDCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AutoAssignedCode
   */
  public void setAutoAssignedCode(String value)
  {
    setAttributeInternal(AUTOASSIGNEDCODE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case AUTOASSIGNEDCODE:
        return getAutoAssignedCode();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case AUTOASSIGNEDCODE:
        setAutoAssignedCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
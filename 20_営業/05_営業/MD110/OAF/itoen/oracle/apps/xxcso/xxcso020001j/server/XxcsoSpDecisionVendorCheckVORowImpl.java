/*============================================================================
* ファイル名 : XxcsoSpDecisionVendorCheckVORowImpl
* 概要説明   : 同一送付先名存在確認用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 同一送付先が存在するかどうかを確認するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionVendorCheckVORowImpl extends OAViewRowImpl 
{


  protected static final int VENDORID = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionVendorCheckVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorId
   */
  public Number getVendorId()
  {
    return (Number)getAttributeInternal(VENDORID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorId
   */
  public void setVendorId(Number value)
  {
    setAttributeInternal(VENDORID, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VENDORID:
        return getVendorId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VENDORID:
        setVendorId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
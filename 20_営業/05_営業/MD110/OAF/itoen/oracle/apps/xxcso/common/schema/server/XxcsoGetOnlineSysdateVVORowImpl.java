/*============================================================================
* ファイル名 : XxcsoGetOnlineSysdateVVOImpl
* 概要説明   : オンライン処理日付取得ビュー行クラス
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
import oracle.jbo.domain.Date;

/*******************************************************************************
 * オンライン処理日付を取得するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoGetOnlineSysdateVVORowImpl extends OAViewRowImpl 
{
  protected static final int ONLINESYSDATE = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoGetOnlineSysdateVVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OnlineSysdate
   */
  public Date getOnlineSysdate()
  {
    return (Date)getAttributeInternal(ONLINESYSDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OnlineSysdate
   */
  public void setOnlineSysdate(Date value)
  {
    setAttributeInternal(ONLINESYSDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ONLINESYSDATE:
        return getOnlineSysdate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ONLINESYSDATE:
        setOnlineSysdate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
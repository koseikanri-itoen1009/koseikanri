/*============================================================================
* ファイル名 : XxcsoAsLeadVVORowImpl
* 概要説明   : 商談情報取得ビュー行クラス
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
 * 商談情報を取得するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAsLeadVVORowImpl extends OAViewRowImpl 
{






  protected static final int LEADNUMBER = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAsLeadVVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeadNumber
   */
  public String getLeadNumber()
  {
    return (String)getAttributeInternal(LEADNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeadNumber
   */
  public void setLeadNumber(String value)
  {
    setAttributeInternal(LEADNUMBER, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case LEADNUMBER:
        return getLeadNumber();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case LEADNUMBER:
        setLeadNumber((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }



}
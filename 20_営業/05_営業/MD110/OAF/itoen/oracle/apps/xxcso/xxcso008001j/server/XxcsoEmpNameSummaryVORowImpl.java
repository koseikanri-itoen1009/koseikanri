/*============================================================================
* ファイル名 : XxcsoEmpNameSummaryVORowImpl
* 概要説明   : 週次活動状況照会／検索用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * スケジュールリージョン（担当者名）を検索するためのビュー行クラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEmpNameSummaryVORowImpl extends OAViewRowImpl 
{

  protected static final int EMPNAME = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEmpNameSummaryVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPNAME:
        return getEmpName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPNAME:
        setEmpName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmpName
   */
  public String getEmpName()
  {
    return (String)getAttributeInternal(EMPNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmpName
   */
  public void setEmpName(String value)
  {
    setAttributeInternal(EMPNAME, value);
  }





}
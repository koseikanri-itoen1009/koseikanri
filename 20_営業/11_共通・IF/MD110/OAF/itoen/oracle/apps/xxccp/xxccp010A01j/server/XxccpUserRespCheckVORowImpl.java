/*============================================================================
* ファイル名 : XxccpUserRespCheckVORowImpl
* 概要説明   : ユーザー・職責チェックビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-08-10 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp010A01j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * ログインユーザーの職責をチェックするためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxccpUserRespCheckVORowImpl extends OAViewRowImpl 
{



  protected static final int SALESRESPEXISTSFLAG = 0;
  protected static final int SYSADMINUSERFLAG = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpUserRespCheckVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SALESRESPEXISTSFLAG:
        return getSalesRespExistsFlag();
      case SYSADMINUSERFLAG:
        return getSysadminUserFlag();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SALESRESPEXISTSFLAG:
        setSalesRespExistsFlag((String)value);
        return;
      case SYSADMINUSERFLAG:
        setSysadminUserFlag((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesRespExistsFlag
   */
  public String getSalesRespExistsFlag()
  {
    return (String)getAttributeInternal(SALESRESPEXISTSFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesRespExistsFlag
   */
  public void setSalesRespExistsFlag(String value)
  {
    setAttributeInternal(SALESRESPEXISTSFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SysadminUserFlag
   */
  public String getSysadminUserFlag()
  {
    return (String)getAttributeInternal(SYSADMINUSERFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SysadminUserFlag
   */
  public void setSysadminUserFlag(String value)
  {
    setAttributeInternal(SYSADMINUSERFLAG, value);
  }
}
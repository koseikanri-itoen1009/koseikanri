/*============================================================================
* ファイル名 : XxcsoInstallAccountVORowImpl
* 概要説明   : 顧客情報ＬＯＶビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-10-31 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
/*******************************************************************************
 * 顧客情報ＬＯＶを作成するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallAccountLovVORowImpl extends OAViewRowImpl 
{


  protected static final int INSTALLACCOUNTNUMBER = 0;
  protected static final int INSTALLPARTYNAME = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallAccountLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAccountNumber
   */
  public String getInstallAccountNumber()
  {
    return (String)getAttributeInternal(INSTALLACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAccountNumber
   */
  public void setInstallAccountNumber(String value)
  {
    setAttributeInternal(INSTALLACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPartyName
   */
  public String getInstallPartyName()
  {
    return (String)getAttributeInternal(INSTALLPARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPartyName
   */
  public void setInstallPartyName(String value)
  {
    setAttributeInternal(INSTALLPARTYNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case INSTALLACCOUNTNUMBER:
        return getInstallAccountNumber();
      case INSTALLPARTYNAME:
        return getInstallPartyName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case INSTALLACCOUNTNUMBER:
        setInstallAccountNumber((String)value);
        return;
      case INSTALLPARTYNAME:
        setInstallPartyName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}
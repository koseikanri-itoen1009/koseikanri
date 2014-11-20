/*============================================================================
* ファイル名 : XxcsoContractQueryTermsVORowImpl
* 概要説明   : 契約書情報検索条件用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-05 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
/*******************************************************************************
 * 契約書情報を検索するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractQueryTermsVORowImpl extends OAViewRowImpl 
{


  protected static final int CONTRACTNUMBER = 0;
  protected static final int INSTALLACCOUNTNUMBER = 1;
  protected static final int INSTALLPARTYNAME = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractQueryTermsVORowImpl()
  {
  }






  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CONTRACTNUMBER:
        return getContractNumber();
      case INSTALLACCOUNTNUMBER:
        return getInstallAccountNumber();
      case INSTALLPARTYNAME:
        return getInstallpartyName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CONTRACTNUMBER:
        setContractNumber((String)value);
        return;
      case INSTALLACCOUNTNUMBER:
        setInstallAccountNumber((String)value);
        return;
      case INSTALLPARTYNAME:
        setInstallpartyName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNumber
   */
  public String getContractNumber()
  {
    return (String)getAttributeInternal(CONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNumber
   */
  public void setContractNumber(String value)
  {
    setAttributeInternal(CONTRACTNUMBER, value);
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
   * Gets the attribute value for the calculated attribute InstallpartyName
   */
  public String getInstallpartyName()
  {
    return (String)getAttributeInternal(INSTALLPARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallpartyName
   */
  public void setInstallpartyName(String value)
  {
    setAttributeInternal(INSTALLPARTYNAME, value);
  }
}